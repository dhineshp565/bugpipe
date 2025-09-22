# BugPipe: Bacterial Whole Genome Assembly and Typing Pipeline

A comprehensive Nextflow pipeline for whole genome assembly and analysis of bacterial isolates using Oxford Nanopore sequencing data.This pipline can also be used for fungal isolates but only for assemblinge the genome and estimating the genome completeness.

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
nextflow run main.nf --input samples/fastq --out_dir Results --profile docker --trim_barcodes
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
| `--trim_barcodes` | false | Enable barcode and adapter trimming |
| `--medaka_model` | bacteria | Basecalling model for genome polishing |
| `--gsize` | auto | Estimated genome size (e.g., 3.5M, 3.5G, 3.5k) |
| `--lineage` | bacteria_odb10 | BUSCO lineage for completeness assessment |

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
├── assemblies/          # Final polished assemblies
├── mlst/               # MLST typing results
├── abricate/           # AMR and virulence factor results
├── speciesID/          # Species identification
├── busco/              # Assembly quality metrics
├── LIMS/               # LIMS-formatted files
└── Bacteria_WGS_results_[timestamp].html  # Summary report
```

## Requirements

### System Dependencies
- [Nextflow](https://www.nextflow.io/) (≥21.0)
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)
- Linux/Unix environment (WSL2 for Windows)

### Hardware Recommendations
- Minimum 8 GB RAM
- Multiple CPU cores recommended for parallel processing

## Installation

1. **Install Nextflow:**
   ```bash
   curl -s https://get.nextflow.io | bash
   sudo mv nextflow /usr/local/bin/
   ```

2. **Install Docker:**
   Follow the [official Docker installation guide](https://docs.docker.com/get-docker/)

3. **Clone the pipeline:**
   ```bash
   git clone https://github.com/dhineshp565/bugpipe.git
   cd bugpipe
   ```

## Pipeline Workflow

1. **Input Processing:** Merges FASTQ files per sample
2. **Quality Control:** Optional barcode/adapter trimming with Porechop
3. **Assembly:** Genome assembly using Dragonflye (Flye + Raven)
4. **Polishing:** Consensus polishing with Medaka
5. **Quality Assessment:** Completeness evaluation with BUSCO
6. **Typing & Annotation:**
   - Species identification (rMLST)
   - MLST typing
   - AMR gene detection (Abricate)
   - Virulence factor detection (Abricate)
7. **Reporting:** Automated HTML report generation

## Tools and References

| Tool | Purpose | Reference |
|------|---------|-----------|
| [Dragonflye](https://github.com/rpetit3/dragonflye) | Genome assembly | Petit III, R.A. |
| [Medaka](https://github.com/nanoporetech/medaka) | Consensus polishing | Oxford Nanopore Technologies |
| [Porechop](https://github.com/rrwick/Porechop) | Adapter trimming | Wick, R.R. |
| [MLST](https://github.com/tseemann/mlst) | Multi-locus sequence typing | Seemann, T. |
| [Abricate](https://github.com/tseemann/abricate) | AMR/VF gene detection | Seemann, T. |
| [BUSCO](https://busco.ezlab.org/) | Assembly completeness | Manni, M. et al. |
| [rMLST API](https://pubmlst.org/species-id) | Species identification | Jolley & Maiden, 2010 |

## Citation

If you use BugPipe in your research, please cite:
- This pipeline: [Add your citation here]
- PubMLST: Jolley & Maiden (2010). BMC Bioinformatics, 11:595

## Support

For issues and questions:
- Open an issue on [GitHub](https://github.com/dhineshp565/bugpipe/issues)
- Check the [documentation](link-to-docs)

