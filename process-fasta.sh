
#!/bin/bash

# Create output directories if they don't exist
mkdir -p aligned_files
mkdir -p hmm_files

# Loop through each FASTA file in the primers directory
for file in primers/*.fasta; do
    # Get the base name of the file (without path and extension)
    base=$(basename "$file" .fasta)
    
    # Align the sequences using MAFFT
    mafft --anysymbol --auto "$file" > "aligned_files/${base}.noprimers.fasta"
    
    # Build the HMM using hmmbuild
    hmmbuild --dna "hmm_files/${base}.hmm" "aligned_files/${base}.noprimers.fasta"
done
