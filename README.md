# Pipeliner   
<i>Flexible and robust framework for the specification of high-throughput sequencing data processing workflows</i>    
    
![Python](https://img.shields.io/badge/Pipeline-Python%202.7-blue.svg)
![Python](https://img.shields.io/badge/Web%20App-Python%203.6-blue.svg)
![Compatibility](https://img.shields.io/badge/Compatibility-Linux%20%2F%20OSX-orange.svg)
![Dependencies](https://img.shields.io/badge/dependencies-up%20to%20date-brightgreen.svg)
[![GitHub Issues](https://img.shields.io/github/issues/montilab/pipeliner.svg)](https://github.com/montilab/pipeliner/issues)  
    
#### Features   
* Modular directory structure: It is designed to generate automated result directory based on the names of the samples and tools used to process them   
* Platform independent: It is bundled with an anaconda repository which contains pre-compiled tools as well as pre-built environments that can use used directly.   
* Modular architecture: It allows the expert users to customize, modify processes, or add additional tools based on their needs.    
* Automated job parallelization, job recovery, and reproducibility

# Table of Contents
- [Prerequisites](#prerequisites)
  * [Test Nextflow](#test-nextflow)
  * [Setup Conda](#setup-conda)
  * [Create Conda Environment](#create-conda-environment)
- [Setting Up Pipeliner](#setting-up-pipeliner)
  * [Clone Repository and Download Nextflow Executable](#clone-repository-and-download-nextflow-executable)
  * [Pipeliner Structure Example](#pipeliner-structure-example)
    + [Files to Upload](#files-to-upload)
    + [Files to Modify](#files-to-modify)
    + [Other Files and Folders](#other-files-and-folders)
  * [Editing the Config File](#editing-the-config-file)
    + [Local Config](#local-config)
    + [Cluster Config](#cluster-config)
    + [Advanced Cluster Options](#advanced-cluster-options)        
- [Running Pipeliner](#running-pipeliner)
  * [Run Locally](#run-locally)
  * [Expected Output](#expected-output)
  * [Resume](#resume)
  * [Run on Cluster](#run-on-cluster)
  * [Output](#output)

---

# Prerequisites
> Pipeliner requires Java, Nextflow, and Anaconda. All other tools will be installed through conda. 

### Test Nextflow

Make sure you have Java 7/8 installed and then install Nextflow to any working directory. Test the Nextflow executable before continuuing. This is just to make sure your environment is compatible with a Nextflow executable. You will download another one later when you clone the repository.
```bash
java -version
cd path/to/wd
curl -s https://get.nextflow.io | bash
./nextflow run hello
```

### Setup Conda

*Local Machine*  
Conda is available through [Anaconda](https://www.continuum.io/downloads). Download the distribution pre-packaged with Python 2.7. If this is your first time working with conda, you may need to edit your configuration paths to ensure anaconda is invoked when calling `conda`.

*Shared Computing Cluster (SCC)*  
Enable conda by loading a pre-installed version of Anaconda with `module load anaconda2`. This will load the latest pre-installed version pre-packaged with Python 2.7. When referring to SCC commands in the documentation, keep in mind they are specific to [Boston University](https://www.bu.edu/tech/support/research/computing-resources/scc/).

### Create Conda Environment

*Linux*
```bash
conda env create -f envs/linux_env.yml 
source activate pipeliner
```

*Mac*
```bash
conda env create -f envs/osx_env.yml 
source activate pipeliner
```

---

# Setting Up Pipeliner

### Clone Repository and Download Nextflow Executable

```bash
git clone https://github.com/montilab/pipeliner
cd pipeliner/RNA-seq
curl -s https://get.nextflow.io | bash
```
> You'll be running Nextflow in the directory you clone to, so choose a good spot!

### Pipeliner Structure Example
```text
/pipeliner/RNA-seq
├── /data
│   │
│   ├── /alignments
│   │   └── sample_1.bam       [^]
│   ├── /reads
│   │   ├── sample_1_R1.fq.gz  [^]
│   │   └── sample_1_R2.fq.gz  [^]
│   │
│   ├── genome_annotation.gtf  [^]
│   ├── genome_reference.fa    [^]
│   ├── genome_refseq.bed      [^]
│   ├── reads.csv              [*]
│   └── alignments.csv         [*]
│
├── nextflow
├── main.nf                    
├── local.config               [*]
├── cluster.config             [*]
│
├── /templates
└── /scripts
```
[^] - Files that must be **uploaded** by the user  
[*] - Files that must be **modified** by the user

#### Files to Upload
```text
/data/reads                    | path/to/reads
/data/alignments               | path/to/alignments
/data/genome_annotation.gtf    | genome annotations (.gtf or .gff)
/data/genome_reference.fa      | genome reference (.fa or .fasta)
/data/genome_refseq.bed        | genome refseq
```
> Uploading the genome refseq file is only necessary for rseqc. If not using genome refseq, skip the rseqc process in your config file!

#### Files to Modify
```text
/data/reads.csv                | file detailing the global path/to/reads
/data/alignments.csv           | file detailing the global path/to/alignments
local.config                   | example parameters for local execution
cluster.config                 | example parameters for cluster execution
```
> You can start with read files or start from alignement files by specifying in one of the config files.  
> Look at [reads.csv](https://github.com/montilab/pipeliner/blob/master/RNA-seq/ggal_data/ggal_reads.csv) or [alignments.csv](https://github.com/montilab/pipeliner/blob/master/RNA-seq/ggal_data/ggal_alignments.csv) examples to see how yours should be formatted.

#### Other Files and Folders
```text
nextflow                       | nextflow executable
main.nf                        | nextflow pipeliner
/templates                     | shell scripts used by processes within pipeliner
/scripts                       | other scritps used by processes within pipeliner
```

> You can edit shell scripts directly if the customization options are not sufficient. See [advanced usage](#modifying-pipeliner).

### Editing the Config File
> You only need one config file, but it will change signficantly if you're running locally or on a cluster. There are a lot of options but here are the key lines you need to edit.

#### Local Config
```text
PROJECT  = <scc-project>
executor = 'local'

indir      = "/Users/anthonyfederico/Village/pipeliner/RNA-seq/ggal_data"
outdir     = "/Users/anthonyfederico/Village/pipeliner/RNA-seq/ggal_results"
fasta      = "${params.indir}/genome_reference.fa"
gtf        = "${params.indir}/genome_annotation.gtf"
bed        = "${params.indir}/genome_refseq.bed"
reads      = "${params.indir}/ggal_reads.csv"
alignments = "${params.indir}/ggal_alignments.csv"

aligner  = "star"       | choose aligning process ["star" or "hisat"]
counter  = "stringtie"  | choose counting process ["stringtie" or "htseq" or "featurecounts"]
paired   = true         | are reads paired or single end?
from_bam = false        | start directly from alignment files?

hisat_indexing.cpus = 1
hisat_mapping.cpus  = 1
star_indexing.cpus  = 1
star_mapping.cpus   = 1
```

#### Cluster Config
```text
PROJECT  = <scc-project>
executor = 'sge

indir      = "/restricted/projectnb/montilab-p/projects/pipeliner/RNA-seq/ggal_data"
outdir     = "/restricted/projectnb/montilab-p/projects/pipeliner/RNA-seq/ggal_results"
fasta      = "${params.indir}/genome_reference.fa"
gtf        = "${params.indir}/genome_annotation.gtf"
bed        = "${params.indir}/genome_refseq.bed"
reads      = "${params.indir}/ggal_reads.csv"
alignments = "${params.indir}/ggal_alignments.csv"

aligner  = "star"       | choose aligning process ["star" or "hisat"]
counter  = "stringtie"  | choose counting process ["stringtie" or "htseq" or "featurecounts"]
paired   = true         | are reads paired or single end?
from_bam = false        | start directly from alignment files?

hisat_indexing.cpus = 16
hisat_mapping.cpus  = 16
star_indexing.cpus  = 16
star_mapping.cpus   = 16
```

#### Advanced Cluster Options
```text
-l h_rt         | Hard run time limit in hh:mm:ss format
-l mem_total    | Request a node that has at least this amount of memory
-pe omp         | Request number of cpus
```

> Resources for New Users  
> [Quick Start](http://www.bu.edu/tech/support/research/system-usage/scc-quickstart/)  
> [Detailed Introduction](http://www.bu.edu/tech/files/2016/09/2016_fall-Tutorial-Intro-to-SCC.pdf)  
> [More Cluster Options](http://www.bu.edu/tech/support/research/system-usage/running-jobs/submitting-jobs/)

---

# Running Pipeliner

### Run Locally
```bash
./nextflow main.nf -c local.config
```

### Expected Output
```text
Launching `main.nf` [distraught_hugle] - revision: 0e9a7a8940
 P I P E L I N E R  ~  v2.3
====================================
Reads          : /Users/anthonyfederico/Village/pipeliner/RNA-seq/ggal_data/ggal_reads.csv
Reference      : /Users/anthonyfederico/Village/pipeliner/RNA-seq/ggal_data/genome_reference.fa
Annotation     : /Users/anthonyfederico/Village/pipeliner/RNA-seq/ggal_data/genome_annotation.gtf
Refseq         : /Users/anthonyfederico/Village/pipeliner/RNA-seq/ggal_data/genome_refseq.bed
Input Dir      : /Users/anthonyfederico/Village/pipeliner/RNA-seq/ggal_data
Output Dir     : /Users/anthonyfederico/Village/pipeliner/RNA-seq/ggal_results
====================================
Read Type      : paired-end
Aligner        : hisat
Quantifier     : htseq
Save Reference : true
Save Temporary : true
====================================
Current user  : anthonyfederico
Current home  : /Users/anthonyfederico
Current path  : /Users/anthonyfederico/Village/pipeliner/RNA-seq
====================================
[warm up] executor > local
[32/b1db1d] Submitted process > hisat_indexing (genome_reference.fa)
[3b/d93c6d] Submitted process > trim_galore (ggal_alpha)
[9c/3fa50b] Submitted process > trim_galore (ggal_theta)
[62/25fce0] Submitted process > trim_galore (ggal_gamma)
[96/2ffc07] Submitted process > fastqc (ggal_alpha)
[31/89cddb] Submitted process > fastqc (ggal_theta)
[57/b2fdf0] Submitted process > fastqc (ggal_gamma)
[66/ccc9db] Submitted process > hisat_mapping (ggal_alpha)
[28/69fff5] Submitted process > hisat_mapping (ggal_theta)
[5c/5ed2b6] Submitted process > hisat_mapping (ggal_gamma)
[bc/6f490c] Submitted process > rseqc (ggal_alpha)
[71/80aa9e] Submitted process > rseqc (ggal_theta)
[17/ca0d9f] Submitted process > rseqc (ggal_gamma)
[d7/7d391b] Submitted process > htseq (ggal_alpha)
[df/936854] Submitted process > htseq (ggal_theta)
[11/143c2c] Submitted process > htseq (ggal_gamma)
[1f/3af548] Submitted process > multiqc
Success: Pipeline Completed!
```

### Resume
If there is an error with your workflow, you can fix it and return to where you left off in the last run.
```
./nextflow main.nf -resume
```

### Run on Cluster
> When running Nextflow on a cluster, individual qsub jobs will be taken care, however main.nf will be running interactively. Try not to do this because interactive jobs will usually be killed after a short period of time. Instead, qsub `./nextflow main.nf -c cluster.config` as well. Therefore, do the following.

```bash
File: run.qsub

#!/bin/sh
./nextflow main.nf -c cluster.config
```
*Run with* `qsub -P <project> -l h_rt=96:00:00 -e std.err -o std.out run.qsub`  

```bash
File: resume.qsub

#!/bin/sh
./nextflow main.nf -resume
```
*Resume with* `qsub -P <project> -l h_rt=96:00:00 -e std.err -o std.out resume.qsub`  

### Output
> Trimmed reads can be run again, alignment files can be used again, multiqc report will show quality control stats across all processes, star index can be used again, and aggregated count matrices can be exported for differential expression analysis outside of Pipeliner.

```
/pipeliner/RNA-seq
└── /results
    │
    ├── /sample_1
    │   ├── /trimgalore      | Trimmed Reads (.fq.gz) for sample_1
    │   ├── /fastqc          
    │   ├── /star            | Alignment File (.bam) for sample_1
    │   ├── /rseqc          
    │   └── /stringtie
    │
    ├── /counts              | Aggregated count matrices across all samples
    ├── /star_files          | Star index used for alignment
    ├── /multiqc_files       | Aggregated report across all samples
    ├── /stringtie
    ├── reads.csv
    └── alignments.csv
```

### Modifying Pipeliner
> For more advanced users comfortable with shell scripting, commands for all processes can be found in templates. Most templates use parameters specified in the config file however you can explicity change any script to suit your needs.

```text
/pipeliner/RNA-seq
│
└── /templates
    ├── trim_galore.sh
    ├── fastqc.sh
    ├── star_indexing.sh
    ├── star_mapping.sh
    ├── hisat_indexing.sh
    ├── hisat_mapping.sh
    ├── rseqc.sh
    ├── stringtie.sh
    ├── htseq.sh
    ├── featurecounts.sh   
    └── multiqc.sh
```
