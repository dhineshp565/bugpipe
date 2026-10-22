#!/usr/bin/env nextflow

process autocycler {
    label "high"
    publishDir "${params.out_dir}/Assembly",mode:"copy"
    input:
    tuple val(SampleName),path(SamplePath)
    val(gsize)

    output:
    tuple val(SampleName),path("${SampleName}_autocycler.fasta"),emit:assembly
    path("${SampleName}_summary.tsv"),emit:plassembler_summary

    path("${SampleName}_autocycler_out"),emit:outdir


    script:
    """
    if [ "${gsize}" = "auto" ]; then
        fast_autocycler ${SamplePath} ${SampleName}_autocycler_out
    else
        fast_autocycler ${SamplePath} ${SampleName}_autocycler_out --genome_size ${gsize}
    fi

    # rename fasta file with samplename
    mv ${SampleName}_autocycler_out/assembly.fasta ${SampleName}_autocycler.fasta

     # rename fasta headers with samplename prefix
    sed -i 's/^>/>${SampleName}_/' "${SampleName}_autocycler.fasta"
   
    mv ${SampleName}_autocycler_out/plassembler_summary.tsv ${SampleName}_summary.tsv
    

   
    """
}
