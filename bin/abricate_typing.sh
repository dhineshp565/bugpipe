#!/bin/bash

# run_abricate.sh
# ----------------
# Wrapper around ABRicate to run serotyping, virulence-factor (VF) and
# AMR (CARD) searches for a sample consensus assembly. The script:
# - reads species from a `speciesid` file (a line like `Taxon: <species>`)
# - looks up the desired serotype/VF DB names and types in a mapping table
# - runs ABRicate with either a builtin DB name (e.g. `vfdb`, `card`, `ecoh`)
#   or a custom DB located under a provided `db` base directory
#
# Usage:
#   ./bin/run_abricate.sh <SampleName> <Consensus_fasta> <speciesid_file> <db_base_dir> <species_map.tsv>
#
# Example mapping file (tab-delimited):
#   Species	SerotypeDB	SerotypeType	VFDB	VFType
#   "Glaesserella parasuis"	 gparasuis_serodb	custom	gparasuis_vfdb	custom
#   "Escherichia coli"	 ecoh	builtin	ecoli_vf	builtin
#
# Mapping columns used by this script:
#   $1 = species name (must match the extracted Taxon)
#   $2 = serotype DB name (or 'None')
#   $3 = serotype type: 'builtin' (use `--db <name>`) or 'custom' (use --datadir)
#   $4 = VF DB name (or 'None')
#   $5 = VF type: 'builtin' or 'custom'

# Exit on error, treat unset variables as errors, fail on pipe errors
set -euo pipefail

# -------------------------
# Input arguments
# -------------------------
SampleName="$1"        # Sample name, used for output filenames
Consensus="$2"         # Consensus FASTA file
speciesid="$3"         # File containing species ID (line like "Taxon: <species>")
db="$4"                # Path to database folder
mapfile="$5"           # Species-to-database mapping table

# -------------------------
# Output filenames
# -------------------------
SEROout="${SampleName}_serotype.tsv"  # Serotyping results
VFOut="${SampleName}_vf.tsv"          # Virulence factor results
AMROut="${SampleName}_AMR.tsv"       # AMR (antimicrobial resistance) results

# -------------------------
# Default output line
# -------------------------
DefaultLine="${SampleName}\t${SampleName}_contig\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone\tNone"
HeaderOnly=1  # number of lines if only header exists

# -------------------------
# Database directories
# -------------------------
db=$(realpath "$db") # convert to absolute path
SERODB_DIR="$db/bugpipe_serodb"  # serotype DB directory
VFDB_DIR="$db/bugpipe_vfdb"      # virulence factor DB directory

# -------------------------
# Extract species from speciesid file
# -------------------------
bacteria=$(grep "Taxon:" "$speciesid" | cut -d ':' -f2 | xargs)
# e.g., "Glaesserella parasuis"

# -------------------------
# Lookup species in mapping table
# -------------------------
serodb=$(awk -F'\t' -v sp="$bacteria" '$1==sp {print $2}' "$mapfile")
serotype_type=$(awk -F'\t' -v sp="$bacteria" '$1==sp {print $3}' "$mapfile")
vfdb=$(awk -F'\t' -v sp="$bacteria" '$1==sp {print $4}' "$mapfile")
vf_type=$(awk -F'\t' -v sp="$bacteria" '$1==sp {print $5}' "$mapfile")

# -------------------------
# Serotyping
# -------------------------
if [[ -n "${serodb:-}" && "${serodb}" != "None" ]]; then
    if [[ "$serotype_type" == "builtin" ]]; then
        abricate --db "$serodb" -minid 80 -mincov 80 --quiet "$Consensus" > "$SEROout"
    else
        # custom database
        abricate --datadir "$SERODB_DIR" --db "$serodb" -minid 80 -mincov 80 --quiet "$Consensus" > "$SEROout"
    fi
else
    # Species not in table or no serotype DB available
    echo -e "#FILE\tSEQUENCE\tSTART\tEND\tSTRAND\tGENE\tCOVERAGE\tCOVERAGE_MAP\tGAPS\t%COVERAGE\t%IDENTITY\tDATABASE\tACCESSION\tPRODUCT\tRESISTANCE" > "$SEROout"
    echo -e "$DefaultLine" >> "$SEROout"
fi

# Append default line if only header
if [[ $(wc -l < "$SEROout") -eq $HeaderOnly ]]; then
    echo -e "$DefaultLine" >> "$SEROout"
fi

# -------------------------
# Virulence factor search
# -------------------------
if [[ -n "${vfdb:-}" && "${vfdb}" != "None" ]]; then
    if [[ "$vf_type" == "builtin" ]]; then
        abricate --db "$vfdb" -minid 80 -mincov 80 --quiet "$Consensus" > "$VFOut"
    else
        # custom database
        abricate --datadir "$VFDB_DIR" --db "$vfdb" -minid 80 -mincov 80 --quiet "$Consensus" > "$VFOut"
    fi
else
    # Species not in table → run default VFDB search
    abricate --db vfdb "$Consensus" > "$VFOut"
fi

# Append default line if only header
if [[ $(wc -l < "$VFOut") -eq $HeaderOnly ]]; then
    echo -e "$DefaultLine" >> "$VFOut"
fi

# -------------------------
# AMR detection (always run)
# -------------------------
abricate --db card "$Consensus" > "$AMROut"

# Append default line if only header
if [[ $(wc -l < "$AMROut") -eq $HeaderOnly ]]; then
    echo -e "$DefaultLine" >> "$AMROut"
fi