#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { abricate_typing } from '../modules/local/abricate_typing.nf'
include { mlst } from '../modules/local/mlst'



process serotype_ssuis {
    label "high"
    publishDir "${params.out_dir}/serotype",mode:"copy"
    input:
    tuple val (SampleName),path (assembly),path(serofile)
    path (cpsK_ref)

    output:
    tuple val (SampleName),path ("${SampleName}_serotype.tsv")
    script:

    """
       if cut -f15 ${serofile} | grep -Eq "serotype-2|serotype-14"; then

            minimap2 -ax map-ont ${cpsK_ref} ${assembly} > ${SampleName}.sam
            samtools view -bS ${SampleName}.sam > ${SampleName}.bam
            samtools sort ${SampleName}.bam > ${SampleName}_sorted.bam

            samtools faidx ${cpsK_ref}
            samtools index ${SampleName}_sorted.bam

            bcftools mpileup -Ob -f ${cpsK_ref} ${SampleName}_sorted.bam > ${SampleName}.bcf
            bcftools call -mv -Ob ${SampleName}.bcf > ${SampleName}.vcf
            bcftools view ${SampleName}.vcf > ${SampleName}_vcf.csv

            if grep -E -wq "cps-2|cps-1" ${serofile} && cut -f2 ${SampleName}_vcf.csv | grep -wq "483"; then

                sed -i 's,serotype-2,serotype-1/2,g' ${serofile}
                sed -i 's,serotype-14,serotype-1,g' ${serofile}

            fi
        fi

        
    """
}

process serotype_salmonella {
    label "high"
    publishDir "${params.out_dir}/serotype", mode: "copy"

    input:
    tuple val(SampleName), path(assembly),path(serofile)

    output:
    tuple val(SampleName), path("${SampleName}_serotype.tsv")

    script:
    """
    sistr -i ${assembly}  ${SampleName} -f csv -o ${SampleName}_sistr.csv --qc

    sistrtoabricate.py ${SampleName}_sistr.csv ${serofile}

   
    
    """
}
process serotype_kpneumoniae {
    label "high"
    publishDir "${params.out_dir}/serotype", mode: "copy"

    input:
    tuple val(SampleName), path(assembly),path(serofile)

    output:
    tuple val(SampleName), path("${SampleName}_serotype.tsv")
    path("${SampleName}_k.tsv")
    path("${SampleName}_o.tsv")


    script:
    """
    
    kaptive assembly kpsc_k ${assembly} -o ${SampleName}_k.tsv
    kaptivetoabricate.py ${SampleName}_k.tsv  ${serofile} 
    cp  ${serofile} ${SampleName}_k_abricate.tsv 

    kaptive assembly kpsc_o ${assembly} -o ${SampleName}_o.tsv
    kaptivetoabricate.py ${SampleName}_o.tsv  ${serofile}
    cp  ${serofile} ${SampleName}_o_abricate.tsv 


    awk 'FNR==1 && NR!=1 { while (/^#F/) getline; } 1 {print}' *_abricate.tsv > ${SampleName}_serotype.tsv
   
   
    """
}


workflow BUGTYPING {
     take:
        assembly_speciesid
        db
        dbmap
    main:
    
      
        abricate_typing(assembly_speciesid,db,dbmap)
        
        
        
        // Join assembly_speciesid with abricate_typing.out.sero on SampleName (first element)
        ch_serotyping_in = assembly_speciesid
                            .map { sample,assembly,speciesid ->
                def bacteria_id=speciesid.text
                            .readLines()
                            .findAll { it.startsWith('Taxon:') }
                            .collect { it.split(':',2)[1]?.trim() }
                            .join(' ')
        tuple(sample, assembly, bacteria_id)}
                            .join (abricate_typing.out.sero)
     
        ch_ssuis = ch_serotyping_in 
                .filter {sample, assembly, bacteria_id,sero-> bacteria_id.contains ('Streptococcus suis')}
                .map { sample, assembly, bacteria_id,sero-> tuple (sample,assembly,sero)}
                
        cpsk = file("${baseDir}/db/Ssuis_cps2K.fasta")
        serotype_ssuis (ch_ssuis,cpsk)

        ch_salmonella = ch_serotyping_in 
                .filter {sample, assembly, bacteria_id,sero -> bacteria_id.contains ('Salmonella')}
                .map { sample, assembly, bacteria_id,sero -> tuple (sample,assembly,sero)}
        serotype_salmonella (ch_salmonella)

        ch_kpneumoniae = ch_serotyping_in 
                .filter {sample, assembly, bacteria_id,sero -> bacteria_id.contains ('Klebsiella')}
                .map { sample, assembly, bacteria_id,sero -> tuple (sample,assembly,sero)}
        serotype_kpneumoniae (ch_kpneumoniae)

     ch_serotype = serotype_ssuis.out
        .mix(serotype_salmonella.out, serotype_kpneumoniae.out[0])
        .mix(
            // Fallback for unknown species: just pass through abricate sero
            ch_serotyping_in
                .filter { sample, assembly, bacteria_id,sero -> !bacteria_id.contains('Streptococcus suis') && 
                                                 !bacteria_id.contains('Salmonella') && 
                                                 !bacteria_id.contains('Klebsiella') }
                .map { sample, assembly, bacteria_id,sero -> tuple(sample, sero) }
                )

    emit:
        sero=ch_serotype
        vf=abricate_typing.out.vif
        amr=abricate_typing.out.AMR
        

        
}