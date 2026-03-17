#!/usr/bin/env nextflow
nextflow.enable.dsl=2



include { mlst } from './modules/local/mlst.nf'
include { abricate_typing } from './modules/local/abricate_typing.nf'
include { makelimsfile } from './modules/local/makelimsfile.nf'
include { speciesid } from './modules/local/speciesid.nf'
include { bakta } from './modules/local/bakta.nf'
include { multiqc } from './modules/local/multiqc.nf'
include { make_report } from './modules/local/make_report.nf'
include { QCREADS } from './subworkflows/qcreads.nf'
include { ASSEMBLY } from './subworkflows/assembly.nf'
include { BUGTYPING } from './subworkflows/bugtyping.nf'

workflow {

	// QC and read preparation
	QCREADS(params.input, params.qscore, params.trim_barcodes)

	// Assembly subworkflow (uses QC reads and genome size)
	ASSEMBLY(QCREADS.out.reads, params.gsize)

	

	// Downstream typing and annotation using polished assemblies
	speciesid(ASSEMBLY.out.medaka_assembly)
	mlst(ASSEMBLY.out.medaka_assembly)
	assembly_species=ASSEMBLY.out.medaka_assembly.join(speciesid.out)
	db=("${baseDir}/db")
	dbmap= file("${baseDir}/speciesdb_map.tsv")

	BUGTYPING(assembly_species,db,dbmap)

	if (params.annotate) {
		bakta(ASSEMBLY.out.medaka_assembly,params.bakta_db)
	}

	
	//make_limsfile (abricate.out.vif.collect(), abricate.out.AMR.collect(), versionfile)

	// Report generation
	rmd_file = file("${baseDir}/bugpipe_report.Rmd")
	make_report(
		rmd_file,
		speciesid.out.map { sample, speciesid -> speciesid }.collect(),
		ASSEMBLY.out.busco_results.collect(),
		QCREADS.out.csv,
		BUGTYPING.out.vf.collect(),
		BUGTYPING.out.amr.collect(),
		BUGTYPING.out.sero.map {sample, sero -> sero }.collect(),
		ASSEMBLY.out.flye_info.collect(),
		mlst.out.collect()
	)
	multiqc (QCREADS.out.read_stats)
	versionfile = file("${baseDir}/software_version.tsv")
	makelimsfile(BUGTYPING.out.sero.map {sample, sero -> sero }.collect(),BUGTYPING.out.vf.collect(),BUGTYPING.out.amr.collect(),mlst.out.collect(),versionfile)
}

