#!/usr/bin/env nextflow

process speciesid {
	label "low"
	publishDir "${params.out_dir}/speciesID",mode:"copy"
	input:
	tuple val(SampleName),path(assembly)
	output:
	path("${SampleName}_speciesid.txt")
	script:
	"""
	rMLST_speciesID.py --file ${assembly} > ${SampleName}_speciesid.txt
	sed -i '1iSample: ${SampleName}' ${SampleName}_speciesid.txt
	"""
}
