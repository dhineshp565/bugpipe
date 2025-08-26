# Bacteria whole genome assembly and typing pipeline


Pipeline for whole genome assembly and analysis of bacterial isolates. Works for Oxford Nanopore reads


### Usage
Requires input directory containg sub-directories with the fastq files and output directory. Outputs several intermediate files with a html report with speciesID, AMR, MLST, and virulence factors found in the sample.
```
nextflow run main.nf --input samples/fastq--outdir Results_mannheimia_2 -profile docker --trim_barcodes
```
```
Parameters:

--input		Input directory containg sub-sirectories with fastq files
--out_dir	Output directory
optional
--trim_barcodes barcode and adapter trimming using porechop
```
### Dependencies
* nextflow
* docker
* wsl2
### Software and references used
* dragonflye (https://github.com/rpetit3/dragonflye)
* abricate (https://github.com/tseemann/abricate)
* mlst (https://github.com/tseemann/mlst,This publication made use of the PubMLST website (https://pubmlst.org/) developed by Keith Jolley (Jolley & Maiden 2010, BMC        Bioinformatics, 11:595) and sited at the University of Oxford. The development of that website was funded by the Wellcome Trust)
* rmarkdown 
* rMLST API (https://pubmlst.org/species-id)
