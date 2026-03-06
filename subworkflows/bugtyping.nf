#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { abricate_typing } from '../modules/local/abricate_typing.nf'
include { mlst } from '../modules/local/mlst'


process sistr {
    label "medium"
    publishDir "${params.out_dir}/sistr",mode:"copy"
    input:
    tuple val (SampleName),path (assembly),path(speciesid),path(serotype)

    output:
    tuple val (SampleName),path ("${SampleName}_serotype.tsv")
    script:

    """
    bacteria=$(grep "Taxon:" "$speciesid" | cut -d ':' -f2 | xargs)

    if [[ "bacteria" == "Salmonella enterica" ]]; then
        sistr -i ${assembly} ${SampleName} -f sv -o ${SampleName}_sistr.tsv --qc
        sed -i 's/genome/id/g' ${SampleName}_serotype.tsv

    elif [[ "bacteria" == "Salmonella enterica" ]]; then

        kaptive assembly kpsc_k ${assembly} -o ${SampleName}_kaptive_k.tsv
        kaptive assembly kpsc_o ${assembly} -o ${SampleName}_kaptive_o.tsv

    if  [[ "bacteria" == "Streptococcus suis" ]] ;then

        
    """
}




workflow BUGTYPING {
     take:
        assembly_speciesid
        db
        dbmap
    main:
    
      
        abricate_typing(assembly_speciesid,db,dbmap)
        
      
    emit:
        sero=abricate_typing.out.sero
        vf=abricate_typing.out.vif
        amr=abricate_typing.out.AMR
        

        
}