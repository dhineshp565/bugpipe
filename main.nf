#!/usr/bin/env nextflow
nextflow.enable.dsl=2



include { mlst } from './modules/local/mlst.nf'
include { abricate } from './modules/local/abricate.nf'
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
	abricate(ASSEMBLY.out.medaka_assembly)

	versionfile = file("${baseDir}/software_version.csv")
	//make_limsfile (abricate.out.vif.collect(), abricate.out.AMR.collect(), versionfile)

	// Report generation
	rmd_file = file("${baseDir}/bugpipe_report.Rmd")
	make_report(
		rmd_file,
		speciesid.out.collect(),
		ASSEMBLY.out.busco_results.collect(),
		QCREADS.out.csv,
		abricate.out.vif.collect(),
		abricate.out.AMR.collect(),
		ASSEMBLY.out.flye_info.collect()
	)

}

