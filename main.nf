#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { mlst } from './modules/local/mlst.nf'
include { abricate_typing } from './modules/local/abricate_typing.nf'
include { makelimsfile } from './modules/local/makelimsfile.nf'
include { speciesid } from './modules/local/speciesid.nf'
include { bakta } from './modules/local/bakta.nf'
include { multiqc } from './modules/local/multiqc.nf'
include { make_report } from './modules/local/make_report.nf'
include { busco } from  './modules/local/busco.nf'
include { QCREADS } from './subworkflows/qcreads.nf'
include { ASSEMBLY } from './subworkflows/assembly.nf'
include { BUGTYPING } from './subworkflows/bugtyping.nf'
include { make_report_fastamode } from './modules/local/make_report_fastamode.nf'


// Process to create CSV file for FASTA mode report
process makecsv_fasta {
    input:
    path(fasta_dir)

    output:
    path ("samplelist.csv")

    script:
    """
    makecsv_fasta.sh "${fasta_dir}"
    """
}



workflow {

    // Check if FASTA input is provided
    if (params.fasta) {
        // FASTA mode: skip QC and assembly
        log.info "Running in FASTA mode - skipping QC and assembly steps"
		
        // Create channel from FASTA input (can be single file or directory)
        
		data = channel.fromPath(params.fasta)
        
        makecsv_fasta(data)
        
        ch_fasta = makecsv_fasta.out
            .splitCsv(header:true)
            .map { row -> tuple(row.SampleName, row.SamplePath) }



      
        assembly_ch = ch_fasta

        // Run BUSCO on FASTA assemblies
        busco(assembly_ch, params.lineage)

        // Downstream typing and annotation using FASTA assemblies
        speciesid(assembly_ch)
        mlst(assembly_ch)
        assembly_species = assembly_ch.join(speciesid.out)

        db = ("${baseDir}/db")
        dbmap = file("${baseDir}/speciesdb_map.tsv")

        BUGTYPING(assembly_species, db, dbmap)

        if (params.annotate) {
            bakta(assembly_ch, params.bakta_db)
        }

        // Report generation for FASTA mode (without QC stats)
        rmd_file = file("${baseDir}/bugpipe_report_fastamode.Rmd")
        
        // Create CSV file with sample names and FASTA paths for report
        ch_fasta_csv = makecsv_fasta.out
        
        

        make_report_fastamode(
            rmd_file,
            speciesid.out.map { _sample, species_id -> species_id }.collect(),
            busco.out.collect(),
            ch_fasta_csv,
            BUGTYPING.out.vf.collect(),
            BUGTYPING.out.amr.collect(),
            BUGTYPING.out.sero.map {_sample, sero -> sero }.collect(),
            mlst.out.collect()
        )

        versionfile = file("${baseDir}/software_version.tsv")
        makelimsfile(BUGTYPING.out.sero.map {_sample, sero -> sero }.collect(), BUGTYPING.out.vf.collect(), BUGTYPING.out.amr.collect(), mlst.out.collect(), versionfile)

    } else {
        // FASTQ mode: standard workflow with QC and assembly
        log.info "Running in FASTQ mode - performing QC and assembly"

        // QC and read preparation
        QCREADS(params.input, params.qscore, params.trim_adapters)

        // Assembly subworkflow (uses QC reads and genome size)
        ASSEMBLY(QCREADS.out.reads, params.gsize)

        // Downstream typing and annotation using polished assemblies
        speciesid(ASSEMBLY.out.medaka_assembly)
        mlst(ASSEMBLY.out.medaka_assembly)
        assembly_species = ASSEMBLY.out.medaka_assembly.join(speciesid.out)
        db = ("${baseDir}/db")
        dbmap = file("${baseDir}/speciesdb_map.tsv")

        BUGTYPING(assembly_species, db, dbmap)

        if (params.annotate) {
            bakta(ASSEMBLY.out.medaka_assembly, params.bakta_db)
        }

        // Report generation
        rmd_file = file("${baseDir}/bugpipe_report.Rmd")
        make_report(
            rmd_file,
            speciesid.out.map { _sample, species_id -> species_id }.collect(),
            ASSEMBLY.out.busco_results.collect(),
            QCREADS.out.csv,
            BUGTYPING.out.vf.collect(),
            BUGTYPING.out.amr.collect(),
            BUGTYPING.out.sero.map {_sample, sero -> sero }.collect(),
            ASSEMBLY.out.flye_info.collect(),
            mlst.out.collect()
        )
        multiqc(QCREADS.out.read_stats.collect())

        versionfile = file("${baseDir}/software_version.tsv")
        makelimsfile(BUGTYPING.out.sero.map {_sample, sero -> sero }.collect(), BUGTYPING.out.vf.collect(), BUGTYPING.out.amr.collect(), mlst.out.collect(), versionfile)
    }
}