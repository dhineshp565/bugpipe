#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process makelimsfile {
	label "low"
	publishDir "${params.out_dir}/LIMS",mode:"copy"
	input:
	path (serotyping_results)
	path (vf_results)
	path (amr_results)
	path (mlst_results)
	path (software_version)
	output:
	path("bugpipe_LIMS_file_*.tsv")
	path("MLST_file_*.tsv")
	
	script:
	"""
	LIMS_file.sh
	
	date=\$(date '+%Y-%m-%d_%H-%M-%S')
	awk 'FNR==1 && NR!=1 { while (/^#F/) getline; } 1 {print}' ${mlst_results} > MLST_file_\${date}.tsv

	

	"""
}