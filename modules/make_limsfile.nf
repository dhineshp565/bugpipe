#!/usr/bin/env nextflow

process make_limsfile {
	label "low"
	publishDir "${params.out_dir}/LIMS",mode:"copy"
	input:
	
	path (vf_results)
	path (amr_results)
	path (software_version)
	output:
	path("*_LIMS_file.csv")
	path("*MLST.csv"),emit:mlst
	
	script:
	"""
	LIMS_file.sh

	"""
}
