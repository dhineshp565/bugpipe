#!/usr/bin/env nextflow

process bakta {
    label "high"
    publishDir "${params.out_dir}/bakta",mode:"copy"
    input:
    tuple val(SampleName), path(assembly)
    path (bakta_db)

    output:
    path("${SampleName}_bakta")

    script:
    """
    bakta \
        --db ${bakta_db} \
        --output ${SampleName}_bakta \
        --prefix ${SampleName} \
        --locus ${SampleName} \
        --keep-contig-headers \
        --thread 8 \
        ${assembly}
    """
}