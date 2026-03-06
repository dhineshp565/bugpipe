#!/usr/bin/env nextflow

process abricate_typing {
	publishDir "${params.out_dir}/abricate/",mode:"copy"
	label "low"
	input:
	tuple val(SampleName),path(consensus),path(speciesid)
	path(db)
	path(dbmap)
	output:
	path("${SampleName}_vf.csv"),emit:vif
	path("${SampleName}_AMR.csv"),emit:AMR
	path ("${SampleName}_serotype.csv"),emit:sero
	
	script:
	"""
	abricate_typing.sh ${SampleName} ${consensus} ${speciesid} ${db} ${dbmap}
	
	"""
	
}
