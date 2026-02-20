#!/usr/bin/env nextflow

process dragonflye {
    label "high"
    publishDir "${params.out_dir}/Assembly",mode:"copy"
    input:
    tuple val(SampleName),path(SamplePath)
	val(gsize)
    output:
	tuple val(SampleName),path("${SampleName}_flye.fasta"),emit:assembly
    path("${SampleName}_flye-info.txt"),emit:flyeinfo
    script:
    """
	if [ "${gsize}" = "auto" ];then
    	dragonflye --reads ${SamplePath} --outdir ${SampleName}_assembly --nanohq 
	else
		dragonflye --reads ${SamplePath} --outdir ${SampleName}_assembly --nanohq --gsize ${gsize}
	fi

    # rename fasta file with samplename
    mv "${SampleName}_assembly"/flye.fasta "${SampleName}"_flye.fasta
    # rename fasta header with samplename
    sed -i 's/contig/${SampleName}_contig/g' "${SampleName}_flye.fasta"

    # rename flyeinfo file and contnents
    mv "${SampleName}_assembly"/flye-info.txt "${SampleName}"_flye-info.txt
    sed -i 's/contig/${SampleName}_contig/g' "${SampleName}_flye-info.txt"

    """
}