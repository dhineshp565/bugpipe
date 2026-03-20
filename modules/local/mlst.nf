#!/usr/bin/env nextflow

process mlst {
	publishDir "${params.out_dir}/mlst/",mode:"copy"
	label "low"
	input:
	tuple val(SampleName),path(assembly)
	output:
	path("${SampleName}_MLST.tsv")
	script:
	"""
	# Run MLST
	mlst ${assembly} > ${SampleName}_MLST.tsv

	# Remove assembly suffix from sample name
	sed -i 's,_assembly.fasta,,g' ${SampleName}_MLST.tsv

	# Read first line and count fields (sample, scheme, ST + loci)
	first_line=\$(head -n 1 ${SampleName}_MLST.tsv)
	ncols=\$(echo "\$first_line" | awk '{print NF}')

	# Build a generic header that works across species with different locus counts
	header="SAMPLE\tSCHEME\tST"
	
	if [[ "\$ncols" -gt 3 ]]; then
		for ((i=1; i<=ncols-3; i++)); do
			header+="\tLOCUS\${i}"
		done
		sed -i "1i\${header}" ${SampleName}_MLST.tsv
	fi

	# If MLST has no scheme hit, keep a consistent, import-friendly structure
	if [[ "\$ncols" -le 3 ]]; then
		header+="\tLOCUS1\tLOCUS2\tLOCUS3\tLOCUS4\tLOCUS5\tLOCUS6\tLOCUS7"
		sed -i 's/-\t-/No_MLST_scheme_available\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA/' ${SampleName}_MLST.tsv

		# Prepend header row for downstream LIMS import
		sed -i "1i\${header}" ${SampleName}_MLST.tsv
	
		
	fi

	"""
}