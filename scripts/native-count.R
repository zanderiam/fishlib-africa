#!/usr/bin/env Rscript

# Load necessary library
library(readr)

# List of species to check for
species_list <- c("Alburnus alburnus", "Amatitlania nigrofasciata", "Astronotus ocellatus", "Astyanax orthodus",
                  "Aulopareia unicolor", "Barbus barbus", "Carassius auratus", "Carassius carassius",
                  "Channa maculata", "Channa striata", "Cirrhinus cirrhosus", "Ctenopharyngodon idella",
                  "Cyprinus carpio", "Esox lucius", "Gambusia affinis", "Gambusia holbrooki",
                  "Gobio gobio", "Haplochromis aeneocolor", "Hucho hucho", "Hypophthalmichthys molitrix",
                  "Hypophthalmichthys nobilis", "Ictalurus punctatus", "Labeo catla", "Labeo rohita",
                  "Lepomis cyanellus", "Lepomis gibbosus", "Lepomis macrochirus", "Lepomis microlophus",
                  "Macropodus opercularis", "Micropterus dolomieu", "Micropterus punctulatus",
                  "Micropterus salmoides", "Morone saxatilis", "Mylopharyngodon piceus",
                  "Oncorhynchus mykiss", "Oreochromis leucostictus", "Oreochromis mortimeri",
                  "Oreochromis mossambicus", "Oreochromis niloticus", "Oreochromis spilurus",
                  "Osphronemus goramy", "Perca fluviatilis", "Phalloceros caudimaculatus",
                  "Poecilia latipinna", "Poecilia reticulata", "Pseudorasbora parva",
                  "Rutilus rutilus", "Salmo trutta", "Salvelinus fontinalis", "Sander lucioperca",
                  "Sarmarutilus rubilio", "Scardinius erythrophthalmus", "Serranochromis robustus",
                  "Silurus glanis", "Tanichthys albonubes", "Tilapia guinasana", "Tinca tinca",
                  "Trichopodus trichopterus", "Xiphophorus hellerii", "Xiphophorus maculatus")

# Folder path containing the CSV files
folder_path <- "assets/fasta"

# Initialize a list to store the results
results <- list()

# Iterate over each file in the folder
files <- list.files(path = folder_path, pattern = "*.csv", full.names = TRUE)
for (file in files) {
  # Read the CSV file
  df <- read_csv(file)
  
  # Count the number of unique species not present from the list
  unique_species_not_present <- length(unique(df$sciNameValid[!df$sciNameValid %in% species_list]))
  
  # Store the result in the list
  results[[basename(file)]] <- unique_species_not_present
}

# Convert the results list to a data frame
results_df <- data.frame(Filename = names(results), Unique_Species_Not_Present_Count = unlist(results))

# Save the results to a CSV file
write.csv(results_df, "native_count_results.csv", row.names = FALSE)

print("The count of unique species not present for each CSV file has been saved to 'native_count_results.csv'.")