# Load necessary libraries
library(dplyr)
library(tidyr)

# Define the path to the folder containing the CSV files
folder_path <- "assets/fasta"

# Get a list of all CSV files in the folder
csv_files <- list.files(path = folder_path, pattern = "*.csv", full.names = TRUE)

# Initialize an empty dataframe to store the combined data
combined_data <- data.frame()

# Read and combine all CSV files
for (file in csv_files) {
  data <- read.csv(file)
  combined_data <- bind_rows(combined_data, data)
}

# Count the occurrences of each species for each metabarcode
species_count <- combined_data %>%
  group_by(sciNameValid, metabarcode) %>%
  summarise(count = n(), .groups = 'drop') %>%
  pivot_wider(names_from = sciNameValid, values_from = count, values_fill = list(count = 0))

# Transpose the species count dataframe
species_count_transposed <- species_count %>%
  pivot_longer(cols = -metabarcode, names_to = "species", values_to = "count") %>%
  pivot_wider(names_from = metabarcode, values_from = count, values_fill = list(count = 0))

# Calculate the coverage for each metabarcode and the total amount of hits for each metabarcode
coverage <- combined_data %>%
  group_by(metabarcode) %>%
  summarise(coverage = n_distinct(sciNameValid) / 3569, total_hits = n(), .groups = 'drop')

# Export the transposed species count dataframe to a CSV file
write.csv(species_count_transposed, file = "reports/species_count_cleaned.csv", row.names = FALSE)

# Export the coverage dataframe to a CSV file
write.csv(coverage, file = "reports/metabarcode_coverage_cleaned.csv", row.names = FALSE)

# Print a message indicating the files have been saved
cat("The species count dataframe has been saved to reports/species_count.csv\n")
cat("The metabarcode coverage dataframe has been saved to reports/metabarcode_coverage.csv\n")
