#!/usr/bin/env nextflow
nextflow.enable.dsl=2


include { make_csv }  from './modules/make_csv.nf'
include { merge_fastq } from './modules/merge_fastq.nf'
include { porechop } from './modules/porechop.nf'
include { dragonflye } from './modules/dragonflye.nf'
include { medaka } from './modules/medaka.nf'
include { busco } from  './modules/busco.nf'
include { mlst } from './modules/mlst.nf'
include { abricate } from './modules/abricate.nf'
include { make_limsfile } from './modules/make_limsfile.nf'
include { speciesid } from './modules/speciesid.nf'
include { make_report } from './modules/make_report.nf'



workflow {
    data=Channel
	.fromPath(params.input)
	merge_fastq(make_csv(data).splitCsv(header:true).map { row-> tuple(row.SampleName,row.SamplePath)})
	
	// Merge fastq files for each sample

	// based on the optional argument trim barcodes using porechop, assemble using dragonflye and polish using medaka
    if (params.trim_barcodes){
		porechop(merge_fastq.out)
		dragonflye(porechop.out,params.gsize) 
		fastq_assembly_ch = porechop.out.join(dragonflye.out.assembly).map { samplename, fastq, assembly -> tuple(samplename, fastq, assembly) }
		medaka(fastq_assembly_ch,params.medaka_model)
	} else {
        dragonflye(merge_fastq.out,params.gsize) 
		fastq_assembly_ch = merge_fastq.out.join(dragonflye.out.assembly).map { samplename, fastq, assembly -> tuple(samplename, fastq, assembly) }
		medaka(fastq_assembly_ch,params.medaka_model)          
    }
	versionfile=file("${baseDir}/software_version.csv")
	//checking completeness of assembly
    busco(medaka.out.assembly,params.lineage)

	speciesid(medaka.out.assembly)
	//mlst
    mlst (medaka.out.assembly)
	//abricate AMR,serotyping and virulence factors
	
    abricate (medaka.out.assembly)

	
	
	 
	versionfile=file("${baseDir}/software_version.csv")
	//make lims file
    //make_limsfile (abricate.out.vif.collect(),abricate.out.AMR.collect(),versionfile)
	
	//report generation

	rmd_file=file("${baseDir}/bugpipe_report.Rmd")
	make_report (rmd_file,speciesid.out.collect(),busco.out.collect(),make_csv.out,abricate.out.vif.collect(),abricate.out.AMR.collect(),dragonflye.out.flyeinfo.collect())


}

