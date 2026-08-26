#!/bin/env bash

# This script makes a csv file with sample name and sample path with headers (SampleName,SamplePath).
# $1 = input path of fasta files directory

# add headers to the csv file
echo "SampleName,SamplePath" > samplelist.csv
input_dir="$1"

# iterate over fasta files in the input directory
for file in "$input_dir"/*.{fasta,fa,fna,fasta.gz,fa.gz,fna.gz}; do
    # check if file exists (handles case where no matches found)
    if [ -f "$file" ]; then
        samplename=$(basename "$file" | sed -E 's/\.(fasta|fa|fna)(\.gz)?$//')
        filepath=$(realpath "$file")
        echo "${samplename},${filepath}" >> samplelist.csv
    fi
done