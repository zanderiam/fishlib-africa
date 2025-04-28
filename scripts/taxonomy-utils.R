#!/usr/bin/env Rscript

process_taxonomy <- function(ncbi_results, species_table, bold_data, stats) {
  # Clean GenBank data
  gb_data <- clean_genbank_data(ncbi_results$ncbi_data, stats)
  
  # Process BOLD data
  bold_processed <- process_bold_data(bold_data, ncbi_results)
  
  # Merge and process taxonomy
  merged_data <- merge_and_process_taxonomy(gb_data, bold_processed, species_table)
  
  return(merged_data)
}

clean_genbank_data <- function(frag_df, stats) {
  frag_df %>%
    filter(gi_no != "NCBI_GENOMES") %>%
    mutate(
      genbankVersion = pull(filter(stats, stat=="genbankVersion"), n),
      searchDate = pull(filter(stats, stat=="date"), n)
    ) %>%
    distinct(gi_no, .keep_all = TRUE) %>%
    mutate(source = "GENBANK") %>%
    clean_coordinates() %>%
    select(-taxonomy, -organelle, -keyword, -lat_lon)
}

clean_coordinates <- function(data) {
  data %>%
    mutate(
      lat = paste(str_split_fixed(lat_lon, " ", 4)[,1], str_split_fixed(lat_lon, " ", 4)[,2]),
      lon = paste(str_split_fixed(lat_lon, " ", 4)[,3], str_split_fixed(lat_lon, " ", 4)[,4])
    ) %>%
    mutate(
      lat = if_else(grepl(" N", lat), 
                    str_replace_all(lat, " N", ""), 
                    if_else(grepl(" S", lat), 
                           paste0("-", str_replace_all(lat, " S", "")), 
                           lat)),
      lon = if_else(grepl(" E", lon),
                    str_replace_all(lon, " E", ""),
                    if_else(grepl(" W", lon),
                           paste0("-", str_replace_all(lon, " W", "")),
                           lon))
    ) %>%
    mutate(
      lat = str_replace_all(lat, "^ ", NA_character_),
      lon = str_replace_all(lon, "^ ", NA_character_)
    ) %>%
    mutate(
      lat = suppressWarnings(as.numeric(lat)),
      lon = suppressWarnings(as.numeric(lon))
    )
}

process_bold_data <- function(bold_data, ncbi_results) {
  bold_data %>%
    filter(!is.na(species_name)) %>%
    filter(processidUniq %in% ncbi_results$bold_ids) %>%
    filter(!genbank_accession %in% str_replace_all(ncbi_results$ncbi_data$gbAccession, "\\..+", "")) %>%
    mutate(
      source = "BOLD",
      nucleotides = str_to_lower(nucleotides),
      length = as.character(str_length(nucleotides))
    ) %>%
    select(source, processidUniq, genbank_accession, species_name, lat, lon,
           country, institution_storing, catalognum, nucleotides, length) %>%
    rename(
      dbid = processidUniq,
      gbAccession = genbank_accession,
      sciNameOrig = species_name,
      decimalLatitude = lat,
      decimalLongitude = lon,
      institutionCode = institution_storing,
      catalogNumber = catalognum
    )
}

merge_and_process_taxonomy <- function(gb_data, bold_data, species_table) {
  merged <- bind_rows(gb_data, bold_data) %>%
    mutate(matchCol = if_else(grepl("\\.COI-5P", dbid), dbid, gbAccession))
  
  # Process taxonomy
  merged %>%
    add_taxonomy(species_table) %>%
    arrange(class, order, family, genus, sciNameValid) %>%
    filter(!is.na(nucleotides))
}

add_taxonomy <- function(data, species_table) {
  data %>%
    mutate(phylum = "Chordata") %>%
    left_join(
      distinct(species_table, class, order, family, genus),
      by = "genus"
    )
}