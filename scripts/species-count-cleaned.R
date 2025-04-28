#!/usr/bin/env Rscript

# Define the folder path containing the CSV files
folder_path <- "assets/fasta"

# List all CSV files in the folder (using full paths for easier access)
csv_files <- list.files(path = folder_path, pattern = "\\.csv$", full.names = TRUE)

# Create an empty vector to collect the sciNameValid entries from all files
all_names <- c()

# Loop over each CSV file
for (file in csv_files) {
  # Read the CSV file. Adjust parameters if your files need a different separator or encoding.
  data <- read.csv(file, stringsAsFactors = FALSE)
  
  # Check if the expected "sciNameValid" column exists
  if ("sciNameValid" %in% colnames(data)) {
    # Append the values from the "sciNameValid" column to the all_names vector
    all_names <- c(all_names, data$sciNameValid)
  } else {
    warning(paste("The file", file, "does not contain a column named 'sciNameValid'."))
  }
}

# Identify the unique names from the combined vector of names
unique_names <- unique(all_names)

# Count the total number of unique names
total_unique_names <- length(unique_names)

# Print the result
cat("Total unique names across all files:", total_unique_names, "\n")
