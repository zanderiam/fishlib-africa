#!/usr/bin/env Rscript

# Load necessary libraries
library(ggplot2)
library(dplyr)

# Read and process the markdown table
data <- read.table("reports/reports-table-only.md", 
                   header = TRUE, 
                   sep = "|", 
                   strip.white = TRUE,
                   check.names = FALSE) %>%
  # Remove first and last empty columns from pipe table
  select(-1, -ncol(.))

# Clean column names
colnames(data) <- c("Locus", "Fragment_Name", "Total", "Cov_all", "Cov_native", "Cov_introduced", "Singletons", "Haps_mean", "Haps_median")

# Convert numeric columns
data$Total <- as.numeric(gsub("[^0-9.]", "", data$Total))
data$Cov_all <- as.numeric(gsub("[^0-9.]", "", data$Cov_all))
data$Cov_native <- as.numeric(gsub("[^0-9.]", "", data$Cov_native))
data$Cov_introduced <- as.numeric(gsub("[^0-9.]", "", data$Cov_introduced))
data$Singletons <- as.numeric(gsub("[^0-9.]", "", data$Singletons))
data$Haps_mean <- as.numeric(gsub("[^0-9.]", "", data$Haps_mean))
data$Haps_median <- as.numeric(gsub("[^0-9.]", "", data$Haps_median))

# Create a directory for plots if it doesn't exist
dir.create("plots", showWarnings = FALSE)

# Create separate plots for each locus
unique_loci <- unique(data$Locus)

for (locus in unique_loci) {
  locus_data <- data %>% filter(Locus == locus)
  
  # Sort the data by Cov_all in descending order
  locus_data <- locus_data %>% arrange(desc(Cov_all))
  
  plot <- ggplot(locus_data, aes(x = reorder(Fragment_Name, -Total), y = Total)) +
    geom_bar(stat = "identity", fill = "#2E86C1") +
    geom_text(aes(label = Total), vjust = -0.3, size = 3.5) +
    labs(
      title = paste("Coverage Analysis -", locus),
      subtitle = "Total Barcode Count per Fragment",
      x = "Fragment",
      y = "Total Barcode Count"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5, vjust = -10),
      plot.subtitle = element_text(size = 12, hjust = 0.5, vjust = -10),
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid.major = element_line(color = "#E0E0E0"),
      panel.grid.minor = element_line(color = "#F5F5F5")
    )
  
  
  # Save the plot with better resolution
  ggsave(
    filename = file.path("plots", paste0(locus, "_coverage_analysis_barcode_count_final.png")),
    plot = plot,
    width = 10,
    height = 6,
    dpi = 300
  )
  
  cat(sprintf("Plot saved: %s_coverage_analysis_barcode_count_final.png
", locus))
}

# Print summary statistics
cat("\nSummary Statistics:\n")
summary_stats <- data %>%
  group_by(Locus) %>%
  summarise(
    Mean_Coverage = mean(Total),
    Min_Coverage = min(Total),
    Max_Coverage = max(Total),
    n_Fragments = n()
  )
print(summary_stats)
