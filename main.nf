#!/usr/bin/env nextflow
nextflow.enable.dsl=2



include { mlst } from './modules/local/mlst.nf'
include { abricate_typing } from './modules/local/abricate_typing.nf'
include { make_limsfile } from './modules/local/make_limsfile.nf'
include { speciesid } from './modules/local/speciesid.nf'
include { make_report } from './modules/local/make_report.nf'

include { QCREADS } from './subworkflows/qcreads.nf'
include { ASSEMBLY } from './subworkflows/assembly.nf'

workflow {

	// QC and read preparation
	QCREADS(params.input, params.qscore, params.trim_barcodes)

	// Assembly subworkflow (uses QC reads and genome size)
	ASSEMBLY(QCREADS.out.reads, params.gsize)

	versionfile = file("${baseDir}/software_version.csv")

	// Downstream typing and annotation using polished assemblies
	speciesid(ASSEMBLY.out.medaka_assembly)
	mlst(ASSEMBLY.out.medaka_assembly)
	assembly_species=ASSEMBLY.out.medaka_assembly.join(speciesid.out)
	db=("${baseDir}/db")
	dbmap= file("${baseDir}/speciesdb_map.tsv")

	abricate_typing(assembly_species,db,dbmap)

	
	//make_limsfile (abricate.out.vif.collect(), abricate.out.AMR.collect(), versionfile)

	// Report generation
	rmd_file = file("${baseDir}/bugpipe_report.Rmd")
	make_report(
		rmd_file,
		speciesid.out.collect(),
		ASSEMBLY.out.busco_results.collect(),
		QCREADS.out.csv,
		abricate_typing.out.vif.collect(),
		abricate_typing.out.AMR.collect(),
		abricate_typing.out.sero.collect(),
		ASSEMBLY.out.flye_info.collect()
	)

}

