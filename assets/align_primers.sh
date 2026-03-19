#!/bin/bash

# Define input and output directories
INPUT_DIR="primers_for_alignment"
OUTPUT_DIR="aligned_primers"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through all .fasta files in the input directory
for file in "$INPUT_DIR"/*.fasta; do
    # Extract base filename (no path, no extension)
    base=$(basename "$file" .fasta)

    # Extract simplified name: keep only the 2nd and 3rd dot-separated parts
    simplified=$(echo "$base" | awk -F. '{print $2 "." $3}')

    # Define output filename
    output="$OUTPUT_DIR/aligned.${simplified}.fasta"

    # Run MAFFT L-INS-i
    mafft --localpair --maxiterate 1000 "$file" > "$output"

    echo "Aligned: $file → $output"
done
