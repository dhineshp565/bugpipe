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

	# Read first line
	first_line=\$(head -n 1 ${SampleName}_MLST.tsv)

	# Count number of columns
	ncols=\$(echo "\$first_line" | awk '{print NF}')

	# If only 3 columns → no MLST scheme available
	if [[ "\$ncols" -le 3 ]]; then

		# Insert minimal header
		sed -i '1i\\SAMPLE\tSCHEME\tST' ${SampleName}_MLST.tsv
		sed -i 's/-\t-/No_MLST_scheme_availble\tNA/g' ${SampleName}_MLST.tsv

	else

		# Build dynamic header
		header="SAMPLE\tSCHEME\tST"

		for field in \$(echo "\$first_line" | cut -f4-); do
			gene=\${field%%(*}
			header="\${header}\t\${gene}"
		done

		sed -i "1i\${header}" ${SampleName}_MLST.tsv

	fi

	"""
}