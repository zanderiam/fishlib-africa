#!/usr/bin/env Rscript
# Modified version - BOLD database only

# load functions and libs
source(here::here("scripts/load-libs.R"))

# get args
option_list <- list( 
  make_option(c("-t","--threads"), type="numeric")
)

# set args
opt <- parse_args(OptionParser(option_list=option_list,add_help_option=FALSE))

# opts if running line-by-line
#opt <- NULL
#opt$threads <- 4

# load up the species table
species.table <- read_csv(file=here("assets/species-table.csv"),show_col_types=FALSE)
writeLines(paste0("\nSpecies table contains ",length(pull(species.table,speciesName))," species names"))

# get list of species
spp.list <- unique(c(pull(species.table,speciesName),pull(species.table,validName)))

writeLines("\nNow searching BOLD ...\n")

# randomise the query
set.seed(42)
spp.list.sam <- sample(spp.list)

# set max length of query
chunk.size.bold <- floor(1000/mean(unlist(lapply(spp.list.sam,nchar)))) # 4000 chars is 200 species per chunk
bold.split <- split(spp.list.sam, ceiling(seq_along(spp.list.sam)/chunk.size.bold))

# query BOLD and retrieve a table
start_time <- Sys.time()
bold.all <- mcmapply(FUN=function(x) bold_seqspec_timer(species=x), bold.split, SIMPLIFY=FALSE, USE.NAMES=FALSE, mc.cores=opt$threads)
end_time <- Sys.time()
end_time-start_time

# check for errors (should be "data.frame" or "logical", not "character")
if(length(which(sapply(bold.all,class) == "data.frame" | sapply(bold.all,class) == "logical")) == length(sapply(bold.all,class))) {
  writeLines("\nBOLD results successfully retrieved.")
} else {
  stop(writeLines("\nBOLD search failed, try again."))
}

# remove the NA non-dataframes
bold.all <- bold.all[which(sapply(bold.all, class)=="data.frame")]

# tidy it up and join it together, remove duplicate records
bold.red <- lapply(lapply(bold.all, as_tibble), function(x) mutate_all(x,as.character))
bold.red <- bind_rows(bold.red)
bold.red %<>% 
  mutate(nucleotides=str_replace_all(nucleotides,"-",""), nucleotides=str_replace_all(nucleotides,"N",""), num_bases=nchar(nucleotides)) %>% 
  filter(num_bases > 0) %>%
  filter(institution_storing!="Mined from GenBank, NCBI") %>% 
  mutate(processidUniq=paste(processid,markercode,sep=".")) %>% 
  distinct(processidUniq, .keep_all=TRUE)

# write output files
write_csv(bold.red,file=here("temp/bold-dump.csv"))

# create a fasta file of BOLD sequences
bold.fas <- tab2fas(df=bold.red,seqcol="nucleotides",namecol="processidUniq")
write.FASTA(bold.fas, file=here("temp/mtdna-dump.fas"))

### report a summary table
stats <- tibble(
  stat=c("speciesTotal","speciesValid","speciesSynonyms","date","totalRecordsBold"),
  n=c(species.table %>% distinct(speciesName) %>% nrow(),
      species.table %>% filter(status == "accepted name") %>% distinct(speciesName) %>% nrow(),
      species.table %>% filter(status != "accepted name") %>% distinct(speciesName) %>% nrow(),
      format(Sys.time(), '%d %b %Y'),
      length(pull(bold.red,processidUniq))
  )
)

# print and save
writeLines("\nPrinting stats ...\n")
print(stats,n=Inf)
write_csv(stats,file=here("reports/stats.csv"))
writeLines("\nAll operations completed!\nPlease read previous messages in case of error.")