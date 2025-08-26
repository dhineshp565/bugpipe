#!/bin/bash



set -euo pipefail

# Input arguments
SampleName="$1"
Consensus="$2"         

# Define default values
DefaultLine="${SampleName}\t${SampleName}_contig_1\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone"
HeaderOnly=1  # Expected line count if only the header is present

# Output filenames

VFOut="${SampleName}_vf.csv"
AMROut="${SampleName}_AMR.csv"


# Run virulence factor search
abricate --db vfdb "$Consensus" > "$VFOut"
sed -i 's,_assembly.fasta,,g' "$VFOut"
if [ "$(wc -l < "$VFOut")" -eq $HeaderOnly ]; then
    echo -e "$DefaultLine" >> "$VFOut"
fi

# Run AMR search using CARD
abricate --db card "$Consensus" > "$AMROut"
sed -i 's,_assembly.fasta,,g' "$AMROut"
if [ "$(wc -l < "$AMROut")" -eq $HeaderOnly ]; then
    echo -e "$DefaultLine" >> "$AMROut"
fi

