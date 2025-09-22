#!/usr/bin/env nextflow

process mlst {
	publishDir "${params.out_dir}/mlst/",mode:"copy"
	label "low"
	input:
	tuple val(SampleName),path(assembly)
	output:
	path("${SampleName}_MLST.csv")
	script:
	"""
	mlst ${assembly} > ${SampleName}_MLST.csv
	sed -i 's,_assembly.fasta,,g' ${SampleName}_MLST.csv
	"""
}