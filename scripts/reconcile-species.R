#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(rvest)
  library(stringr)
  library(progress)
  library(tidyr)
})

normalize_binomen <- function(x) {
  if (is.null(x)) return(x)
  x <- str_squish(x)
  x <- str_replace_all(x, "[[:space:]]+", " ")
  x <- str_remove(x, "[[:punct:]]+$")
  x
}

# Extract all binomina from “Valid as …” patterns
extract_all_valid_as <- function(text_or_lines) {
  txt <- if (length(text_or_lines) > 1) paste(text_or_lines, collapse = " ") else text_or_lines
  m <- str_match_all(txt, "Valid as\\s+([A-Z][a-z]+)\\s+([a-z\\-]+)")
  if (length(m) == 0 || length(m[[1]]) == 0) return(character(0))
  unique(paste(m[[1]][,2], m[[1]][,3]))
}

# Parse a CoF species page into records (without deciding validity)
parse_cof_results <- function(text) {
  lines <- str_split(text, "\n")[[1]]
  lines <- str_squish(lines)
  lines <- lines[nzchar(lines)]
  
  # Record starts: "species, Genus"
  starts <- grep("^[a-z\\-]+,\\s*[A-Z][a-z]+", lines)
  if (length(starts) == 0) return(tibble())
  
  blocks <- mapply(function(i, j) lines[i:j],
                   starts,
                   c(starts[-1]-1, length(lines)),
                   SIMPLIFY = FALSE)
  
  results <- lapply(blocks, function(block) {
    entry_line <- block[1]
    entry_match <- str_match(entry_line, "^([a-z\\-]+),\\s*([A-Z][a-z]+)")
    entry_name <- if (!any(is.na(entry_match))) paste(entry_match[3], entry_match[2]) else NA_character_
    
    # Collect all "Valid as ..." names present in the block
    block_valids <- extract_all_valid_as(block)
    
    tibble(
      entry = entry_name,
      blockValids = paste(block_valids, collapse = "; "),
      recordSynCount = length(block_valids)
    )
  })
  
  bind_rows(results)
}

# Choose best record given a queried name (for richer synonyms)
choose_best_record <- function(records, queried) {
  if (nrow(records) == 0) return(records)
  
  entry_col <- ifelse(is.na(records$entry), "", records$entry)
  valids_col <- ifelse(is.na(records$blockValids), "", records$blockValids)
  
  # 1) Prefer entry == queried
  idx1 <- which(entry_col == queried)
  if (length(idx1)) {
    chosen <- records[idx1[1], ]
    chosen$chosenReason <- "matched_entry_equal"
    return(chosen)
  }
  
  # 2) Prefer where queried appears among blockValids
  idx2 <- which(str_detect(valids_col, fixed(queried)))
  if (length(idx2)) {
    syn_counts <- records$recordSynCount[idx2]
    chosen_idx <- idx2[order(syn_counts, decreasing = TRUE)][1]
    chosen <- records[chosen_idx, ]
    chosen$chosenReason <- "matched_blockValid"
    return(chosen)
  }
  
  # 3) Fallback to the record with the most valids
  chosen_idx <- order(records$recordSynCount, decreasing = TRUE)[1]
  chosen <- records[chosen_idx, ]
  chosen$chosenReason <- "fallback_max_valids"
  chosen
}

# Query CoF at species level, set cofValid = queried, build synonyms per rules
lookup_cof <- function(name) {
  nm <- normalize_binomen(name)
  parts <- str_split(nm, "\\s+", simplify = TRUE)
  if (ncol(parts) < 2) {
    return(tibble(entry = NA, cofValid = nm, synonyms = NA, queried = nm, chosenReason = "invalid_query"))
  }
  genus <- parts[1]; species <- parts[2]
  
  url <- paste0(
    "https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?tbl=species&genus=",
    URLencode(genus), "&species=", URLencode(species)
  )
  
  page <- tryCatch(read_html(url), error = function(e) NULL)
  if (is.null(page)) {
    return(tibble(entry = NA, cofValid = nm, synonyms = NA, queried = nm, chosenReason = "fetch_failed"))
  }
  
  txt <- page %>% html_text2()
  all_records <- parse_cof_results(txt)
  
  if (nrow(all_records) == 0) {
    return(tibble(entry = NA, cofValid = nm, synonyms = NA, queried = nm, chosenReason = "no_records"))
  }
  
  chosen <- choose_best_record(all_records, nm)
  
  # Build synonyms:
  # - Take all blockValids
  # - Add entry if not equal to queried
  # - Remove queried (cofValid)
  block_valids <- if (is.na(chosen$blockValids) || chosen$blockValids == "") character(0) else
    str_split(chosen$blockValids, ";\\s*")[[1]]
  
  syns <- unique(c(
    block_valids,
    if (!is.na(chosen$entry) && chosen$entry != "" && chosen$entry != nm) chosen$entry else character(0)
  ))
  syns <- setdiff(syns, nm) # drop self-mapping
  
  tibble(
    entry = chosen$entry,
    cofValid = nm,
    synonyms = paste(syns, collapse = "; "),
    queried = nm,
    chosenReason = chosen$chosenReason
  )
}

# -----------------------------
# 1. Load inputs
# -----------------------------
unmatched <- read_csv("assets/unmatched-species.csv", show_col_types = FALSE)
char_cols <- names(unmatched)[sapply(unmatched, is.character)]
name_col <- if ("sciNameAccession" %in% char_cols) "sciNameAccession" else char_cols[1]

unmatched_species <- unmatched %>%
  transmute(queryName = normalize_binomen(.data[[name_col]])) %>%
  filter(!is.na(queryName), queryName != "") %>%
  distinct() %>%
  pull(queryName)

cat("\nLoaded ", length(unmatched_species), " unmatched species from '", name_col, "'.\n", sep = "")

species_table <- read_csv("assets/species-table.csv", show_col_types = FALSE) %>%
  mutate(validName = normalize_binomen(validName))

# -----------------------------
# 2. Query CoF
# -----------------------------
pb <- progress_bar$new(
  format = "  Querying CoF [:bar] :percent eta: :eta",
  total = length(unmatched_species), clear = FALSE, width = 60
)

cof_extractions <- vector("list", length(unmatched_species))
for (i in seq_along(unmatched_species)) {
  cof_extractions[[i]] <- lookup_cof(unmatched_species[i])
  pb$tick()
}

extraction_log <- bind_rows(cof_extractions)
write_csv(extraction_log, "assets/cof-extraction-log.csv")
cat("\nRaw CoF extraction written to assets/cof-extraction-log.csv\n")

# -----------------------------
# 3. Build synonym → valid map (drop self-mappings)
# -----------------------------
cof_map <- extraction_log %>%
  filter(!is.na(cofValid), cofValid != "", !is.na(synonyms), synonyms != "") %>%
  separate_rows(synonyms, sep = ";\\s*") %>%
  mutate(synonym = normalize_binomen(synonyms)) %>%
  filter(synonym != "", synonym != cofValid) %>%
  distinct(synonym, cofValid)

write_csv(cof_map, "assets/cof-synonym-map.csv")
cat("Synonym→valid map written to assets/cof-synonym-map.csv (", nrow(cof_map), " rows)\n", sep = "")

# -----------------------------
# 4. Apply replacements
# -----------------------------
repl_vec <- setNames(cof_map$cofValid, cof_map$synonym)

species_table_cof <- species_table %>%
  mutate(
    fishbaseValid = validName,
    validName = if_else(
      status == "accepted name" & validName %in% names(repl_vec),
      repl_vec[validName],
      validName
    ),
    speciesName = if_else(
      status == "accepted name" & speciesName %in% names(repl_vec),
      repl_vec[speciesName],
      speciesName
    )
  )

replacements_log <- species_table %>%
  filter(status == "accepted name" & (validName %in% names(repl_vec) | speciesName %in% names(repl_vec))) %>%
  transmute(
    fbAcceptedOriginal_validName = validName,
    fbAcceptedOriginal_speciesName = speciesName,
    cofValid_validName = if_else(validName %in% names(repl_vec), repl_vec[validName], validName),
    cofValid_speciesName = if_else(speciesName %in% names(repl_vec), repl_vec[speciesName], speciesName)
  ) %>%
  distinct()

write_csv(species_table_cof, "assets/species-table-cof.csv")
write_csv(replacements_log, "assets/replacements-log.csv")

cat("\nUpdated species table written to assets/species-table-cof.csv\n")
cat("Replacement log written to assets/replacements-log.csv\n")
