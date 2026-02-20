#!/usr/bin/env nextflow

process make_report {
	label "medium"
	publishDir "${params.out_dir}/",mode:"copy"
	input:
	path(rmdfile)
	path(speciesID)
	path(busco)
	path (samplelist)
	path (vffiles)
	path (amrfiles)
    path(flyeinfo)
	output:
	path("*.html")

	script:

	"""
	
	cp ${rmdfile} rmdfile_copy.Rmd
	cp ${samplelist} samples.csv
	
	
	Rscript -e "rmarkdown::render(input='rmdfile_copy.Rmd', params=list(csv='samples.csv'), output_file=paste0('WGS_results_', format(Sys.time(), '%Y-%m-%d_%H-%M-%S'), '.html'))"
	
	"""

}
