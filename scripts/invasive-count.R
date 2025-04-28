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
  
  # Check if each species from the list is present in the file
  species_present <- sapply(species_list, function(species) any(df$sciNameValid == species))
  
  # Count the number of unique species present
  species_count <- sum(species_present)
  
  # Store the result in the list
  results[[basename(file)]] <- species_count
}

# Convert the results list to a data frame
results_df <- data.frame(Filename = names(results), Species_Count = unlist(results))


# Save the results to an Excel file
write.csv(results_df, "invasive_species_count_results.csv", row.names = FALSE)

print("The species count for each CSV file has been saved to 'invasive_species_count_results.csv'.")