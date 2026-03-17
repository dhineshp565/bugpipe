#!/usr/bin/env python
# Converts kaptive CSV output to Abricate TSV format for LIMS import
# Usage: python kaptivetoabricate.py kaptive_input.csv abricate_output.tsv

import pandas as pd
import sys

# Get input/output filenames from command line arguments
kaptive_file = sys.argv[1]      # kaptive CSV input file (1st argument)
abricate_file = sys.argv[2]  

# Read kaptive results (CSV format with comma separator)
df_kaptive = pd.read_csv(kaptive_file, sep='\t')

# Read existing Abricate template (TSV format)
df_abricate = pd.read_csv(abricate_file, sep='\t') 

# Map kaptive data to Abricate columns (row-by-row alignment)
df_abricate['START'] = df_kaptive['Expected genes in locus']                  
df_abricate['END'] = df_kaptive['Other genes in locus']             
df_abricate['STRAND'] = df_kaptive['Expected genes outside locus']    
df_abricate['GENE'] = 'K and O antigen'
df_abricate['COVERAGE'] = 'NA'    
df_abricate['COVERAGE_MAP'] = 'NA'
df_abricate['GAPS'] = df_kaptive['Length discrepancy']                                      
df_abricate['%COVERAGE'] = df_kaptive['Coverage']                           
df_abricate['%IDENTITY'] = df_kaptive['Identity']                               
df_abricate['DATABASE'] = 'kaptive'                               
df_abricate['ACCESSION'] = df_kaptive['Expected genes in locus']              
df_abricate['PRODUCT'] = df_kaptive['Match confidence']                  
df_abricate['RESISTANCE'] = df_kaptive['Best match locus']                 

# Overwrite output file with updated Abricate format (TSV)
df_abricate.to_csv(abricate_file, sep='\t', index=False)     
