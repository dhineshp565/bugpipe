# BugPipe: Bacterial Whole Genome Assembly and Typing Pipeline

A comprehensive Nextflow pipeline for whole genome assembly and analysis of bacterial isolates using Oxford Nanopore sequencing data. This pipeline can also be used for fungal isolates for genome assembly, completeness estimation, and optional genome annotation.

## Overview

BugPipe performs complete bacterial genome analysis including:
- Genome assembly and polishing
- Species identification
- Multi-locus sequence typing (MLST)
- Antimicrobial resistance (AMR) gene detection
- Virulence factor identification
- Assembly quality assessment
- Automated HTML report generation

## Quick Start

### Basic Usage
```bash
nextflow run main.nf --input samples/fastq --out_dir Results --profile docker
```

### With Barcode Trimming
```bash
nextflow run main.nf --input samples/fastq --out_dir Results --profile docker --trim_adapters true
```

## Parameters

### Required Parameters
| Parameter | Description |
|-----------|-------------|
| `--input` | Input directory containing subdirectories with FASTQ files |
| `--out_dir` | Output directory for results |

### Optional Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `--qscore` | 10 | Minimum read quality score threshold for filtering |
| `--trim_adapters` | false | Set to `true` to enable barcode and adapter trimming |
| `--medaka_model` | bacteria | Basecalling model for genome polishing |
| `--gsize` | auto | Estimated genome size (e.g., 3.5M, 3.5G, 3.5k) |
| `--lineage` | bacteria_odb10 | BUSCO lineage for completeness assessment |
| `--annotate` | false | Enable genome annotation using Bakta |
| `--bakta_db` | /data/referenceDB/bakta_db/bakta_db-light | Path to Bakta database directory |

## Input Structure

Your input directory should be organized as follows:
```
input_directory/
├── sample1/
│   ├── file1.fastq.gz
│   └── file2.fastq.gz
├── sample2/
│   ├── file1.fastq.gz
│   └── file2.fastq.gz
└── ...
```

## Output Structure

The pipeline generates the following outputs:
```
Results/
├── assemblies/         # Final polished assemblies
├── mlst/               # MLST typing results
├── abricate/           # AMR and virulence factor results
├── serotype/           # Serotype refinement outputs (SISTR/Kaptive/S. suis refinement)
├── speciesID/          # Species identification
├── busco/              # Assembly quality metrics
├── multiqc/            # MultiQC report and data
├── bakta/              # Optional Bakta annotation outputs
├── LIMS/               # LIMS-formatted files
└── WGS_results_*.html  # Summary report
```

## Requirements

### System Dependencies
- [Nextflow](https://www.nextflow.io/) (≥21.0)
- [Docker](https://www.docker.com/)
- Linux/Unix environment (WSL2 for Windows)

### Hardware Recommendations
- Minimum 8 GB RAM
- Multiple CPU cores recommended for parallel processing


## Pipeline Workflow

1. **Input Processing:** Merges FASTQ files per sample
2. **Quality Control:** Optional barcode/adapter trimming with Porechop
3. **Assembly:** Genome assembly using Dragonflye (Flye)
4. **Polishing:** Consensus polishing with Medaka
5. **Quality Assessment:** Completeness evaluation with BUSCO
6. **Typing & Annotation:**
   - Species identification (rMLST)
   - MLST typing ([MLST](https://github.com/tseemann/mlst) and [PubMLST](https://pubmlst.org/))
   - AMR gene detection (Abricate + [CARD](https://card.mcmaster.ca/home))
   - Virulence factor detection (Abricate + [VFDB](https://www.mgc.ac.cn/VFs/main.htm) or Species-specific custom database)
   - Serotype detection (Abricate + Species-specific databases, plus [SISTR](https://github.com/phac-nml/sistr_cmd) for Salmonella and [Kaptive](https://github.com/klebgenomics/Kaptive) for Klebsiella)
7. **Annotation:** Optional genome annotation using Bakta
8. **Reporting:** Automated HTML report generation

## Supported Bacteria for Serotyping

The following bacterial species are supported for serotype detection:

| Species | Serotype Database | Database Source |
|---------|-------------------|-----------------|
| *Glaesserella parasuis* | gparasuis_serodb | [Howell et al 2015](https://doi.org/10.1128/jcm.01991-15) |
| *Streptococcus suis* | ssuis_serodb | [Athey et al 2016](https://doi.org/10.1186/s12866-016-0782-8) |
| *Mannheimia haemolytica* | mhaemolytica_serodb | [Iguchi et al 2025](https://doi.org/10.1038/s41598-025-97176-z) |
| *Escherichia coli* | EcOH | [ABRicate built-in DB](https://github.com/tseemann/abricate) |
| *Klebsiella aerogenes* | kaerogenes_serodb | [K-antigen](https://doi.org/10.1016/j.celrep.2024.114602); [O-antigen](https://doi.org/10.1038/s41598-020-73360-1) |
| *Klebsiella pneumoniae* | Kaptive (kpsc_k, kpsc_o) | [Kaptive](https://kaptive-web.erc.monash.edu/) |
| *Salmonella* | SISTR | [Yoshida et al 2016](https://doi.org/10.1371/journal.pone.0147101) |
| *Staphylococcus aureus* | saureus_serodb | cap-5 and cap-8 only |
| *Histophilus somni* | None | None |
| *Actinobacillus pleuropneumoniae* | apleuropneumoniae_serodb | [Angen et al 2025](https://doi.org/10.1099/mgen.0.001434) |

## Tools and References

| Tool | Purpose | Link | Reference |
|------|---------|------|-----------|
| [Dragonflye](https://github.com/rpetit3/dragonflye) | Genome assembly | https://github.com/rpetit3/dragonflye | Petit III, R.A. |
| [Flye](https://github.com/mikolmogorov/Flye) | Long-read assembler used by Dragonflye | https://github.com/mikolmogorov/Flye | Kolmogorov, M. et al. |
| [Medaka](https://github.com/nanoporetech/medaka) | Consensus polishing | https://github.com/nanoporetech/medaka | Oxford Nanopore Technologies |
| [Porechop](https://github.com/rrwick/Porechop) | Adapter trimming | https://github.com/rrwick/Porechop | Wick, R.R. |
| [NanoPlot](https://github.com/wdecoster/NanoPlot) | Read-level QC metrics | https://github.com/wdecoster/NanoPlot | De Coster, W. et al. |
| [MultiQC](https://github.com/MultiQC/MultiQC) | Aggregate QC report generation | https://github.com/MultiQC/MultiQC | Ewels, P. et al. |
| [MLST](https://github.com/tseemann/mlst) | Multi-locus sequence typing | https://github.com/tseemann/mlst | Seemann, T. |
| [Abricate](https://github.com/tseemann/abricate) | AMR/VF/Serotype detection | https://github.com/tseemann/abricate | Seemann, T. |
| [CARD](https://card.mcmaster.ca/) | AMR gene reference database used in ABRicate (`--db card`) | https://card.mcmaster.ca/ | Alcock, B.P. et al. |
| [VFDB](http://www.mgc.ac.cn/VFs/) | Virulence factor reference database used in ABRicate (`--db vfdb`) | http://www.mgc.ac.cn/VFs/ | Liu, B. et al. |
| [Kaptive](https://github.com/klebgenomics/Kaptive) | Capsule/LPS serotype prediction | https://github.com/klebgenomics/Kaptive | Wyres, K.L. et al. |
| [SISTR](https://github.com/phac-nml/sistr_cmd) | Salmonella serotyping | https://github.com/phac-nml/sistr_cmd | Yoshida, C.E. et al. |
| [Minimap2](https://github.com/lh3/minimap2) | Read mapping for S. suis serotype refinement | https://github.com/lh3/minimap2 | Li, H. |
| [SAMtools](https://github.com/samtools/samtools) | BAM/FASTA indexing and alignment processing | https://github.com/samtools/samtools | Danecek, P. et al. |
| [BCFtools](https://github.com/samtools/bcftools) | Variant calling for serotype refinement | https://github.com/samtools/bcftools | Danecek, P. et al. |
| [BUSCO](https://busco.ezlab.org/) | Assembly completeness assessment | https://busco.ezlab.org/ | Manni, M. et al. |
| [Bakta](https://github.com/oschwartz10612/bakta) | Genome annotation | https://github.com/oschwartz10612/bakta | Schwartz et al. |
| [rMLST API](https://pubmlst.org/species-id) | Species identification | https://pubmlst.org/species-id | Jolley & Maiden, 2010 |
| [PubMLST](https://pubmlst.org/) | MLST database repository | https://pubmlst.org/ | Maiden, M.C. et al. |



