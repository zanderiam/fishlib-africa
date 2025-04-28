#!/usr/bin/env Rscript
# Rupert A. Collins

# R script to make reference databases for UK fishes for multiple markers
# downloads all mtDNA sequence data from GenBank/BOLD, for a provided list of species 

# load functions and libs
source(here::here("scripts/load-libs.R"))
# load up your personal NCBI API key to get 10 requests per sec. This needs to be generated from your account at https://www.ncbi.nlm.nih.gov/
# DO NOT PUT THIS KEY ON GITHUB
# if you don't have one, ncbi will rate-limit your access to 3 requests per sec, and errors may occur.
source(here("assets/ncbi-key.R"))

# get args
option_list <- list( 
    make_option(c("-q","--qlength"), type="numeric"),
    make_option(c("-t","--threads"), type="numeric"),
    make_option(c("-e","--exhaustive"), type="character"),
    make_option(c("-b","--bold"), type="character")
    )

bold.red <- read.csv("temp/bold-dump.csv")
bold.fas <- tab2fas(df=bold.red,seqcol="nucleotides", namecol = "processidUniq")
write.FASTA(bold.fas, file=here("temp/mtdna-dump.fas"), append=TRUE)

