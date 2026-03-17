#!/usr/bin/env nextflow

process abricate_typing {
	publishDir "${params.out_dir}/abricate/",mode:"copy"
	label "low"
	input:
	tuple val(SampleName),path(consensus),path(speciesid)
	path(db)
	path(dbmap)
	output:
	path("${SampleName}_vf.tsv"),emit:vif
	path("${SampleName}_AMR.tsv"),emit:AMR
	tuple val(SampleName),path ("${SampleName}_serotype.tsv"),emit:sero
	
	script:
	"""
	abricate_typing.sh ${SampleName} ${consensus} ${speciesid} ${db} ${dbmap}
	
	"""
	
}
