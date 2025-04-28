# Load necessary library
library(dplyr)

# Read the CSV file into a data frame
species_data <- read.csv("species-table.csv")

# Remove duplicates based on the speciesName column
cleaned_species_data <- species_data %>% distinct(speciesName, .keep_all = TRUE)

# Write the cleaned data to a new CSV file
write.csv(cleaned_species_data, "cleaned-species-table.csv", row.names = FALSE)

# Print a message to confirm the operation
cat("Duplicates removed and cleaned data saved to 'cleaned-species-table.csv'.\n")
