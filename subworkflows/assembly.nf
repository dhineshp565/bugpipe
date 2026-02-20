#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { dragonflye } from '../modules/local/dragonflye.nf'
include { medaka } from '../modules/local/medaka.nf'
include { busco } from  '../modules/local/busco.nf'



workflow ASSEMBLY {
    take:
    reads
    gsize

    main:
    dragonflye (reads,gsize)
    fastq_assembly_ch = reads.join(dragonflye.out.assembly).map { samplename, fastq, assembly -> tuple(samplename, fastq, assembly) }
    medaka(fastq_assembly_ch,params.medaka_model)

    busco(medaka.out.assembly,params.lineage)

    emit:
    flye_assembly    = dragonflye.out.assembly
    flye_info        = dragonflye.out.flyeinfo
    medaka_assembly  = medaka.out.assembly
    busco_results    = busco.out
}