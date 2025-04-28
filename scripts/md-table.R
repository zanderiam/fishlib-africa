# Load necessary libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(grid)  # Load the grid package
library(gridExtra)  # Load the gridExtra package

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
  
  # Reshape data for plotting
  locus_data_long <- locus_data %>%
    pivot_longer(cols = c(Cov_all, Cov_native, Cov_introduced), 
                 names_to = "Coverage_Type", 
                 values_to = "Coverage_Value")
  
  plot <- ggplot(locus_data_long, aes(x = reorder(Fragment_Name, -Coverage_Value), y = Coverage_Value, fill = Coverage_Type)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.8)) +
    geom_text(aes(label = Coverage_Value), vjust = -0.3, size = 1.5, position = position_dodge(width = 0.8)) +
    scale_fill_manual(values = c("Cov_all" = "#2E86C1", "Cov_native" = "#28B463", "Cov_introduced" = "#E74C3C"), 
                      name = "Coverage Type") +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid.major = element_line(color = "#E0E0E0"),
      panel.grid.minor = element_line(color = "#F5F5F5")
    )
  
  # Create title and subtitle grobs
  title_grob <- textGrob(paste("Coverage Analysis -", locus), gp = gpar(fontsize = 14, fontface = "bold"))
  subtitle_grob <- textGrob("Coverage per Fragment", gp = gpar(fontsize = 12))
  
  # Combine plot and text grobs
  combined_plot <- arrangeGrob(plot, title_grob, subtitle_grob, ncol = 1, heights = unit(c(10, 1, 1), "null"))
  
  # Save the combined plot
  ggsave(
    filename = file.path("plots", paste0(locus, "_coverage_analysis_final.png")),
    plot = combined_plot,
    width = 10,
    height = 8,
    dpi = 300
  )
  
  cat(sprintf("Plot saved: %s_coverage_analysis_final.png\n", locus))
}

# Print summary statistics
cat("\nSummary Statistics:\n")
summary_stats <- data %>%
  group_by(Locus) %>%
  summarise(
    Mean_Coverage = mean(Cov_all),
    Min_Coverage = min(Cov_all),
    Max_Coverage = max(Cov_all),
    n_Fragments = n()
  )
print(summary_stats)
