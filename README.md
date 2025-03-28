# *M. tuberculosis* variant identification pipeline

Pipeline for *M. tuberculosis* variant identification from short-read data for epidemiology and phylogenetics. Briefly, this pipeline takes raw short-read Illumina data, pre-processes reads (read adapter trimming and taxonomic filtering), maps reads to a provided reference genome, calls variants, and outputs consensus FASTA sequences for downstream applications. The pipeline is written in Nextflow, so modules are adaptable. User options allow for tailoring of the pipeline such as setting custom filters and choosing a reference genome. Users can [benchmark](benchmark.md) this pipeline with their chosen filters on simulated data and truth VCFs. 

## Installation & set-up

1. Clone Github repo.

```
git clone https://github.com/ksw9/mtb-call2.git
```

2. Load your HPC's container tool (i.e. Docker, Podman or Singularity) and nextflow. (Some clusters may have these pre-loaded.)

```
module load singularity # or docker (not necessary on Stanford SCG)
module load nextflow 
```

3. Run the pipeline using the "download_refs" profile to populate your resources directory with required references, indices, and databases, including SnpEFF, and Kraken2.

```
nextflow run main.nf -profile {standard,docker,podman,singularity},download_refs
```

4. Modify the config file (nextflow.config):

  - Update resources_dir (full path to directory resources).
  - Update clusterOptions parameter to make arguments specific to cluster.
    - Stanford SCG: clusterOptions = "-A jandr --partition batch -N 1 --time=4:00:00 --mem 96g"
    - Stanford SCG: container = "ksw9/mtb-call:1.0" (Stanford cluster Java installation is not compatible with other Docker images)
  - If you are using a previously installed Kraken2 database, update kraken_db with the path.

## Usage

1. Run the pipeline with the "variant_calling" profile on the test data (truncated FASTQ files) included in the test_data directory. Include any user options here. The Docker images will be pulled automatically by running the pipeline the first time.

```
nextflow run main.nf -profile {standard,docker,podman,singularity},variant_calling
```

2. Run the pipeline on user data with the "variant_calling" profile.

  - Create a tab-delimited file with sample name, full path to FASTQ read 1, full path to FASTQ read 2, batch name. 
  - Update the nextflow.config so that the reads_list parameter is now defined by the new list. 
  - Update the scripts/submit_mtb_pipeline.sh job submission script with job name, email, email preferences. 
  - Run the pipeline.

```
nextflow run main.nf -profile {standard,docker,podman,singularity},variant_calling
sbatch scripts/submit_mtb_pipeline.sh # submit via a SLURM job scheduler script. Use scripts/submit_mtb_pipeline_scg.sh at Stanford.
```

## Outputs

All outputs are stored in the results directory, within the project directory. Directory structure mirrors the input reads file, with directories organized by sequencing run, then sample.

<pre>
<b>results</b>
│
└── <b>batch_0</b>
    │
    ├── <b>sample</b>
    |   │
    |   ├── <b>bams</b>
    |   │
    |   ├── <b>fasta</b>
    |   │
    |   ├── <b>kraken</b>
    |   │
    |   ├── <b>stats</b>
    |   │
    |   ├── <b>trim</b>
    |   │
    |   └── <b>vars</b>
    |
    └── <b>batch_n</b>
</pre>

## Example data

The test_data directory includes two datasets:

1. test_data/test: Truncated paired-end fastq files for use to confirm pipeline runs.
  - An input sample .tsv file list is located at config/test_data.tsv.
2. test_data/benchmark: Simulated Illumina reads for pipeline [benchmarking](benchmark.md).

## Options

There are several user options which can be modified on the command line or in the nextflow.config file (command line options take precedence).
- **mapper**: defines mapping algorithm to be used (**bwa** or **bowtie2**). (Default = "bwa")
- **run_lofreq**: set to **true** to run LoFreq as well as GATK, or **false** to run GATK only. (Default = true)
- **seq_platform**: mock platform name for picard AddOrReplaceReadGroups. (Default = "illumina")
- **library**: mock library name for picard AddOrReplaceReadGroups (Default = "library1")
- **vcf_filter**: string of filters to be used for filtering the vcf file. See scripts/filter_vcf.py for more details. (Default = 'QUAL > 20 && QUAL != "." && DP > 5 && TYPE == "SNP"')
- **additional_vcf_filtering**: additional paremeters for the vcf filtering step. Use **"--remove_extreme_depth"** to remove variants with depth two standard deviations away from the mean variant depth, **"--remove_extreme_qual"** to remove variants with depth two standard deviations away from the mean variant quality, **"--remove_extreme_depth --remove_extreme_qual"** for both options, or **""** for none. (Default = '')
- **ploidy**: defines ploidy for GATK variant calling (currently, only tested for ploidy = 1). (Default = 1)
- **nextseq**: set to **true** if NextSeq was the sequencing platform. Nextseq has been found to [overcall](https://github.com/FelixKrueger/TrimGalore/blob/master/Docs/Trim_Galore_User_Guide.md) G bases at the 3' end. If set to **true**, TrimGalore will ignore quality scores of G bases in the trimming step. (Default = false)
- **nextseq_qual_threshold**: If the above parameter is **true**, defines the quality threshold for trimming. (Default = 20)
- **vcf_variants_only**: If **true**, GATK will output a VCF including only variant sites with respect to the reference genome, while all positions will be included if **false**. (Default = true)
- **fasta_vcf_sites_only**: If **true**, sites missing from the vcf will be marked as N in the consensus fasta. Note that if this parameter is **false** and **vcf_variants_only** is **true**, the resulting FASTA file will include the consensus allele at all non-variant sites, which may be an incorrect assumption at low or no coverage positions (i.e. the REF allele will be filled in rather than N). (Default = true)
- **use_filtered_vcf_for_fasta**: If **true** ,the filtered vcf file will be used for bcftools consensus, while if **false** the unfiltered vcf will be used. (Default = true)

## Troubleshooting

- Singularity uses the `$HOME` directory as the default cache. This may cause errors if there are space limitations in `$HOME`. Specify a cache dir to store the image via:

``` 
export WORKDIR=$(pwd)
export NXF_SINGULARITY_CACHEDIR=$WORKDIR/images
export SINGULARITY_CACHEDIR=$WORKDIR/images
```
- If Nextflow cannot pull the Docker images on the fly, pull them manually, then run the pipeline. If using singularity, then modify the "container" fields in the nextflow.config file specifying the local path (e.g. container = '/full/path/to/image.sif')

```
# e.g. for efetch image using Docker
docker pull ksw9/mtb-call:efetch

# e.g. for efetch image using Singularity
singularity pull ksw9-mtb-call_efetch.img docker://ksw9/mtb-call:efetch
```

- If the pipeline truncates after a few steps, confirm that all expected files have been downloaded and are in the resources directory. This may be caused by an incomplete download (i.e. of refs/).
