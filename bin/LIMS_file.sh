#!/usr/bin/env bash
# This script takes the outputs form abricate and merges them into one tabsepearted file for imprting into LIMS casebook

# Extract data from *_sero.tsv files
awk 'FNR==1 && NR!=1 { while (/^#F/) getline; } 1 {print}' *_serotype.tsv > sero_file.tsv

# Add "CATEGORY" header to sero_file.tsv
awk 'BEGIN{print "CATEGORY"} {if(NR>1) print ($0=="" ? "" : "serotype")}' sero_file.tsv > sero_column.txt

# Combine sero_file.tsv and sero_column.txt into serotype_res.tsv
paste sero_file.tsv sero_column.txt > serotype_res.tsv

# Extract data from *_vf.tsv files
awk 'FNR==1 && NR!=1 { while (/^#F/) getline; } 1 {print}' *_vf.tsv > vf_file.tsv

# Add "CATEGORY" header to vf_file.tsv
awk 'BEGIN{print "CATEGORY"} {if(NR>1) print ($0=="" ? "" : "VF")}' vf_file.tsv > vf_column.txt

# Combine vf_file.tsv and vf_column.txt into vf_res.tsv
paste vf_file.tsv vf_column.txt > vf_res.tsv

# Extract data from *_AMR.tsv files
awk 'FNR==1 && NR!=1 { while (/^#F/) getline; } 1 {print}' *_AMR.tsv > amr_file.tsv

# Add "CATEGORY" header to amr_file.tsv
awk 'BEGIN{print "CATEGORY"} {if(NR>1) print ($0=="" ? "" : "AMR")}' amr_file.tsv > amr_column.txt

# Combine vf_file.tsv and vf_column.txt into amr_res.tsv
paste amr_file.tsv amr_column.txt > amr_res.tsv

# Generate current date and time
datetime=$(date +"%d%b%Y_%H-%M-%S")



# Extract data from *_res.tsv files and save as ${datetime}_LIMS_file.tsv
awk 'FNR==1 && NR!=1 { while (/^#F/) getline; } 1 {print}' *_res.tsv > bugpipe_LIMS_file.tsv

cat software_version.tsv bugpipe_LIMS_file.tsv >> bugpipe_LIMS_file_${datetime}.tsv

# Replace "#FILE" with "ID" in ${datetime}_LIMS_file.tsv
sed -i 's,#FILE,ID,g' bugpipe_LIMS_file_${datetime}.tsv

