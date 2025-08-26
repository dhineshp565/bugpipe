#!/usr/bin/env nextflow
nextflow.enable.dsl=2



// make csv file with headers from the given input

process make_csv {
	publishDir "${params.out_dir}"
	input:
	path(fastq_input)
	output:
	path("samplelist.csv")
	
	script:
	"""
	makecsv.sh ${fastq_input}

	"""

}

//merge fastq files for each SampleName and create a merged file for each SampleNames
process merge_fastq {
	publishDir "${params.out_dir}/merged"
	label "low"
	input:
	tuple val(SampleName),path(SamplePath)
	output:
	tuple val(SampleName),path("${SampleName}.{fastq,fastq.gz}"),emit:reads

	shell:
	"""
	count=\$(ls -1 ${SamplePath}/*.gz 2>/dev/null | wc -l)
	
	
		if [[ "\${count}" != "0" ]]
		then
			cat ${SamplePath}/*.fastq.gz > ${SampleName}.fastq.gz
					
		else
			count=\$(ls -1 ${SamplePath}/*.fastq 2>/dev/null | wc -l)
			if [[ "\${count}" != "0" ]]
			then
				cat ${SamplePath}/*.fastq > ${SampleName}.fastq
				
			fi
		fi
	"""
}

//trim barcodes and adapter using porechop

process porechop {
	label "high"
	publishDir "${params.out_dir}/trimmed"
	input:
	tuple val(SampleName),path(SamplePath)
	output:
	tuple val(SampleName),path ("${SampleName}_trimmed.fastq")
	script:
	"""
	porechop -i ${SamplePath} -o ${SampleName}_trimmed.fastq
	"""
}

process dragonflye {
    label "high"
    publishDir "${params.out_dir}/Assembly",mode:"copy"
    input:
    tuple val(SampleName),path(SamplePath)
	val(medaka_model)
    output:
	tuple val(SampleName),path("${SampleName}_flye.fasta")
	path("${SampleName}_flye-info.txt"),emit:flyeinfo
    script:
    """
    dragonflye --reads ${SamplePath} --outdir ${SampleName}_assembly --nanohq 

    # rename fasta file with samplename
    mv "${SampleName}_assembly"/flye.fasta "${SampleName}"_flye.fasta
    # rename fasta header with samplename
    sed -i 's/contig/${SampleName}_contig/g' "${SampleName}_flye.fasta"

     # rename flyeinfo file and contnents
    mv "${SampleName}_assembly"/flye-info.txt "${SampleName}"_flye-info.txt
    sed -i 's/contig/${SampleName}_contig/g' "${SampleName}_flye-info.txt"
    """
}


process medaka {
	publishDir "${params.out_dir}/medaka",mode:"copy"
	label "high"
	input:
	tuple val(SampleName),path(SamplePath)
	tuple val(SampleName),path(draft_assembly)
	path("${SampleName}_flye-info.txt")
	val (medaka_model)
	output:
	val(SampleName), emit:sample
	tuple val(SampleName),path("${SampleName}_assembly.fasta"),emit:assembly
	path("${SampleName}_flye-info.txt"),emit:flyeinfo
	
	script:
	"""
	
	medaka_consensus -i ${SamplePath} -d ${draft_assembly} -o ${SampleName}_medaka_assembly --bacteria
		
	mv ${SampleName}_medaka_assembly/consensus.fasta ${SampleName}_assembly.fasta
	
	"""

}


process busco {
    label "low"
    publishDir "${params.out_dir}/busco",mode:"copy"
    input:
    tuple val(SampleName),path(cons)
    output:
    path ("${SampleName}_busco.txt")
    script:

    """
    busco -i ${cons} -m genome -l bacteria_odb10 -o ${SampleName}_busco_results
	mv ${SampleName}_busco_results/*.txt ${SampleName}_busco.txt

    """
}

process mlst {
	publishDir "${params.out_dir}/mlst/",mode:"copy"
	label "low"
	input:
	tuple val(SampleName),path(assembly)
	output:
	path("${SampleName}_MLST.csv")
	script:
	"""
	mlst ${assembly} > ${SampleName}_MLST.csv
	sed -i 's,_assembly.fasta,,g' ${SampleName}_MLST.csv
	"""
}

process abricate{
	publishDir "${params.out_dir}/abricate/",mode:"copy"
	label "low"
	input:
	tuple val(SampleName),path(consensus)
	output:
	path("${SampleName}_vf.csv"),emit:vif
	path("${SampleName}_AMR.csv"),emit:AMR
	
	script:
	"""
	run_abricate.sh ${SampleName} ${consensus}
	
	"""
	
}

process make_limsfile {
	label "low"
	publishDir "${params.out_dir}/LIMS",mode:"copy"
	input:
	
	path (vf_results)
	path (amr_results)
	path (software_version)
	output:
	path("*_LIMS_file.csv")
	path("*MLST.csv"),emit:mlst
	
	script:
	"""
	LIMS_file.sh

	"""
}

process speciesid {
	label "low"
	publishDir "${params.out_dir}/speciesID",mode:"copy"
	input:
	tuple val(SampleName),path(assembly)
	output:
	path("${SampleName}_speciesid.txt")
	script:
	"""
	rMLST_speciesID.py --file ${assembly} > ${SampleName}_speciesid.txt
	sed -i '1iSample: ${SampleName}' ${SampleName}_speciesid.txt
	"""
}
	

process make_report {
	label "low"
	publishDir "${params.out_dir}/",mode:"copy"
	input:
	path(rmdfile)
	path(speciesID)
	path(busco)
	path (samplelist)
	path (vffiles)
	path (amrfiles)
	output:
	path("*.html")

	script:

	"""
	
	cp ${rmdfile} rmdfile_copy.Rmd
	cp ${samplelist} samples.csv
	
	
	Rscript -e "rmarkdown::render(input='rmdfile_copy.Rmd', params=list(csv='samples.csv'), output_file=paste0('Baceria_WGS_results_', format(Sys.time(), '%Y-%m-%d_%H-%M-%S'), '.html'))"
	
	"""

}







workflow {
    data=Channel
	.fromPath(params.input)
	merge_fastq(make_csv(data).splitCsv(header:true).map { row-> tuple(row.SampleName,row.SamplePath)})
	
	// Merge fastq files for each sample

	// based on the optional argument trim barcodes using porechop, assemble using dragonflye and polish using medaka
    if (params.trim_barcodes){
		porechop(merge_fastq.out)
		dragonflye(porechop.out,params.medaka_model) 
		medaka(porechop.out,dragonflye.out,params.medaka_model)
	} else {
        dragonflye(merge_fastq.out,params.medaka_model) 
		medaka(merge_fastq.out,dragonflye.out,params.medaka_model)          
    }
	versionfile=file("${baseDir}/software_version.csv")
	//checking completeness of assembly
    busco(medaka.out.assembly)

	speciesid(medaka.out.assembly)
	//mlst
    mlst (medaka.out.assembly)
	//abricate AMR,serotyping and virulence factors
	
    abricate (medaka.out.assembly)

	
	
	 
	versionfile=file("${baseDir}/software_version.csv")
	//make lims file
    //make_limsfile (abricate.out.vif.collect(),abricate.out.AMR.collect(),versionfile)
	
	//report generation

	rmd_file=file("${baseDir}/bacpipe_report.Rmd")
	make_report (rmd_file,speciesid.out.collect(),busco.out.collect(),make_csv.out,abricate.out.vif.collect(),abricate.out.AMR.collect())


}

