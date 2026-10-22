#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { dragonflye } from '../modules/local/dragonflye.nf'
include { autocycler } from '../modules/local/autocycler.nf'
include { medaka } from '../modules/local/medaka.nf'
include { busco } from  '../modules/local/busco.nf'



workflow ASSEMBLY {
    take:
    reads
    gsize

    main:
    if (params.assembler == 'autocycler') {
        autocycler(reads, gsize)
        ch_draft_assembly  = autocycler.out.assembly
        ch_assembly_info = autocycler.out.plassembler_summary
    } else {
        dragonflye(reads, gsize)
        ch_draft_assembly     = dragonflye.out.assembly
        ch_assembly_info = dragonflye.out.flyeinfo
    }
    
    medaka_input = reads.join(ch_draft_assembly)
            .map { samplename, fastq, assembly -> tuple(samplename, fastq, assembly) }
    medaka(medaka_input,params.medaka_model)
    busco(medaka.out.assembly, params.lineage)

    emit:
    assembly_info   = ch_assembly_info
    medaka_assembly = medaka.out.assembly
    busco_results   = busco.out
}
