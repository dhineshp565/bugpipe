#!/usr/bin/env python
# Converts SISTR CSV output to Abricate TSV format for LIMS import
# Usage: python sistrtoabricate.py sistr_input.csv abricate_output.tsv

import pandas as pd
import sys

# Get input/output filenames from command line arguments
sistr_file = sys.argv[1]      # SISTR CSV input file (1st argument)
abricate_file = sys.argv[2]   # Abricate TSV output file (2nd argument)

# Read SISTR results (CSV format with comma separator)
df_sistr = pd.read_csv(sistr_file, sep=',')

# Read existing Abricate template (TSV format)
df_abricate = pd.read_csv(abricate_file, sep='\t') 

# Map SISTR data to Abricate columns (row-by-row alignment)
df_abricate['START'] = df_sistr['cgmlst_ST']                    # cgMLST sequence type
df_abricate['END'] = df_sistr['cgmlst_distance']                # cgMLST genetic distance  
df_abricate['STRAND'] = df_sistr['serogroup']                   # Serogroup (C2-C3)
df_abricate['GENE'] = ('I' + df_sistr['o_antigen'] + ':' + df_sistr['h1'] + ':' + df_sistr['h2'])   # I 8,20:i:z6 (Kentucky) # Standard antigenic formula
df_abricate['COVERAGE'] = df_sistr['cgmlst_found_loci']         # Total cgMLST loci found
df_abricate['COVERAGE_MAP'] = df_sistr['cgmlst_matching_alleles']  # Matching alleles
df_abricate['GAPS'] = 'NA'                                      # No gaps data available
df_abricate['%COVERAGE'] = 'NA'                                 # No % coverage data
df_abricate['%IDENTITY'] = 'NA'                                 # No % identity data
df_abricate['DATABASE'] = 'SISTR'                               # Source database name

df_abricate['ACCESSION'] = df_sistr['qc_messages']              # QC info as accession
df_abricate['PRODUCT'] = df_sistr['qc_status']                  # PASS/WARNING/FAIL
df_abricate['RESISTANCE'] = df_sistr['serovar']                 # Serovar name (Kentucky)

# Overwrite output file with updated Abricate format (TSV)
df_abricate.to_csv(abricate_file, sep='\t', index=False)     
