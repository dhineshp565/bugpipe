#!/usr/bin/env nextflow

process medaka {
	publishDir "${params.out_dir}/medaka",mode:"copy"
	label "high"
	input:
	tuple val(SampleName),path(SamplePath),path(draft_assembly)
	val (medaka_model)
	output:
	tuple val(SampleName),path("${SampleName}_assembly.fasta"),emit:assembly
	script:
	"""
	if [ "$medaka_model" = "bacteria" ]; then 
		
		medaka_consensus -i ${SamplePath} -d ${draft_assembly} -o ${SampleName}_medaka_assembly --bacteria
		mv ${SampleName}_medaka_assembly/consensus.fasta ${SampleName}_assembly.fasta
	else
		medaka_consensus -i ${SamplePath} -d ${draft_assembly} -o ${SampleName}_medaka_assembly
		mv ${SampleName}_medaka_assembly/consensus.fasta ${SampleName}_assembly.fasta
	fi
		
	"""

}