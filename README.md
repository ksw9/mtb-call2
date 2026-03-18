# *M. tuberculosis* variant identification pipeline

Pipeline for *M. tuberculosis* variant identification from short-read data for epidemiology and phylogenetics. Briefly, this pipeline takes raw short-read Illumina data, pre-processes reads (read adapter trimming and taxonomic filtering), maps reads to a provided reference genome, calls variants, and outputs consensus FASTA sequences for downstream applications. The pipeline is written in Nextflow, so modules are adaptable. User options allow for tailoring of the pipeline such as setting custom filters and choosing a reference genome.

## Pipeline profiles

* **download_refs** : the pipeline will download all resources required for analyses.

  * Downloads references.

  * Indexes references.
  
  * Builds mapping indices.
  
  * Builds the variant calling dictionary.
  
  * Downloads and sets-up snpEff.
  
  * Downloads or generates a Kraken2 database.

* **variant_calling** : runs the analysis on user-defined samples.

  * Trims reads using TrimGalore!

  * Filters reads using Kraken2.

  * Maps reads to the H37Rv genome.

  * Predicts antibiotic resistance using Mykrobe.

  * Predicts lineage and drug resistance using TBProfiler.

  * Variant Calling with GATK and, optionally, LoFreq.
  
    * Calls variants with GATK HaplotypeCaller and GenotypeGVCFs.
    
    * Filters variants using user-customizable filters.

    * Annotates VCFs using snpEff
  
    * Converts VCF to FASTA via bcftools, retaining only SNPs
    
      * Generates FASTA without PE/PPE masking
    
      * Generates FASTA with PE/PPE masking

## Installation & set-up

1. Clone the Github repo.

```
git clone https://github.com/ksw9/mtb-call2.git
```

2. Load your HPC's container tool (i.e. Docker, Podman or Singularity) and Nextflow.\
N.B. Some clusters may have these pre-loaded.

```
module load singularity # or docker
module load nextflow 
```

3. Update the "**nextflow.config**" file:

  - Update the "**resources_dir**" parameter, e.g.\
    *resources_dir = "/full/path/mtb-call2/resources"*\
    N.B. Use the full path\
    N.B. This directory will be created (and populated) when you run the pipeline in "**download_refs**" mode (see point 4)

  - Update the "**clusterOptions**" parameter, e.g.\
    *clusterOptions = "--account my_account --partition my_partition --qos my_qos -N 1 --time=24:00:00 --mem=150G --cpus-per-task=3"*

4. Run the pipeline using the "**download_refs**" profile to populate your resources directory with required references, indices, and databases, including SnpEFF, and Kraken2.\
N.B. you can use the **--kraken2_database_download** option to customize how to handle the Kraken2 database generation:

    - **none** : don't generate a Kraken2 database (useful if you previously downloaded/generated a database)
    - **standard** : download a pre-generated Kraken2 standard database
    - **expanded** : generates a new database with standard and EUPathDB46 assemblies (this option is time-consuming)

```
nextflow run main.nf -profile {standard,docker,podman,singularity},download_refs --kraken2_database_download {none,standard,expanded}
```

5. Update the "**kraken_database_path**" parameter in **nextflow.config**" file, e.g.
*kraken_database_path = /path/to/kraken2/database/relative/to/resources_dir*\
N.B. Path is relative to "**resources_dir**", so move your database to the resources directory if needed.

6. Now the pipeline is ready for running analyses.

## Running analyses

1. Create a tab-delimited **reads manifest** file of input gzipped fastq samples as below.\
N.B. The **scripts/write_input_reads_list.sh** script is a useful utility to automate this for paired-end samples.\
N.B. The order of the columns doesn't matter as long as the header is present.
N.B. If a sample is single-end, set **fastq_2** to "*mock.fastq*".

| sample | batch | fastq_1 | fastq_2 |
| :---: | :---: | :---: | :---: |
| unique_sample_identifier | sample_batch | /full/path/fastq/read_1.fastq.gz | /full/path/fastq/read_2.fastq.gz |

2. Place the **reads manifest** in a subdirectory of "**resources_dir**" named "**input**", e.g.\
*/full/path/mtb-call2/resources/input/sample_manifest.tsv*

3. Load your HPC's container tool (i.e. Docker, Podman or Singularity) and Nextflow.\
N.B. Some clusters may have these pre-loaded.

```
module load singularity # or docker
module load nextflow 
```

4. Run the pipeline with the "**variant_calling**" profile.\
N.B. It's recommended to run the pipeline using a slurm script.\
N.B. Use the "--reads_list" parameter to declare the path to the **reads manifest** relative to the "**resources_dir**" (see point 2).

```
nextflow run main.nf -profile {standard,docker,podman,singularity},variant_calling --reads_list input/sample_manifest.tsv
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
    |   │   Alignment step outputs
    |   │
    |   ├── <b>fasta</b>
    |   │   Consensus fasta files
    |   │
    |   ├── <b>kraken</b>
    |   │   Taxonomical classification results
    |   │
    |   ├── <b>stats</b>
    |   │   Useful metrics to assess sample quality
    |   │
    |   ├── <b>trim</b>
    |   │   Trimming step outputs
    |   │
    |   └── <b>vars</b>
    |       Variant calling step outputs
    |
    └── <b>batch_n</b>
</pre>

## Options

There are several user options which can be modified on the command line or in the nextflow.config file (command line options take precedence).

- **mapper**: defines mapping algorithm to be used (**bwa** or **bowtie2**).\
  (Default = "bwa")

- **run_lofreq**: set to **true** to run LoFreq as well as GATK, or **false** to run GATK only.\
  (Default = true)

- **seq_platform**: mock platform name for picard AddOrReplaceReadGroups.\
  (Default = "illumina")

- **library**: mock library name for picard AddOrReplaceReadGroups.\
  (Default = "library1")

- **vcf_filter**: string of filters to be used for filtering the vcf file.\
  See scripts/filter_vcf.py for more details.\
  (Default = 'QUAL > 20 && QUAL != "." && DP > 5 && TYPE == "SNP"')

- **additional_vcf_filtering**: additional paremeters for the vcf filtering step.\
  Use **"--remove_extreme_depth"** to remove variants with depth two standard deviations away from the mean variant depth, **"--remove_extreme_qual"** to remove variants with depth two standard deviations away from the mean variant quality, **"--remove_extreme_depth --remove_extreme_qual"** for both options, or **""** for none.\
  (Default = '')

- **ploidy**: defines ploidy for GATK variant calling (currently, only tested for ploidy = 1).\
  (Default = 1)

- **nextseq**: set to **true** if NextSeq was the sequencing platform. Nextseq has been found to [overcall](https://github.com/FelixKrueger/TrimGalore/blob/master/Docs/Trim_Galore_User_Guide.md) G bases at the 3' end.\
  If set to **true**, TrimGalore will ignore quality scores of G bases in the trimming step.\
  (Default = false)

- **nextseq_qual_threshold**: If the above parameter is **true**, defines the quality threshold for trimming.\
  (Default = 20)

- **vcf_variants_only**: If **true**, GATK will output a VCF including only variant sites with respect to the reference genome, while all positions will be included if **false**.\
  (Default = true)

- **fasta_vcf_sites_only**: If **true**, sites missing from the vcf will be marked as N in the consensus fasta.\
  Note that if this parameter is **false** and **vcf_variants_only** is **true**, the resulting FASTA file will include the consensus allele at all non-variant sites, which may be an incorrect assumption at low or no coverage positions (i.e. the REF allele will be filled in rather than N).\
  (Default = true)

- **use_filtered_vcf_for_fasta**: If **true** ,the filtered vcf file will be used for bcftools consensus, while if **false** the unfiltered vcf will be used.\
  (Default = true)

## Example data

The **test_reads** directory includes a paired-end sample useful for quick testing.

## Troubleshooting

- Singularity uses the `$HOME` directory as the default cache. This may cause errors if there are space limitations in `$HOME`. Specify a cache dir to store the image via:

``` 
export WORKDIR=$(pwd)
export NXF_SINGULARITY_CACHEDIR=$WORKDIR/images
export SINGULARITY_CACHEDIR=$WORKDIR/images
```
- If Nextflow cannot pull the Docker images on the fly, pull them manually, then run the pipeline. If using singularity, then modify the "container" fields in the nextflow.config file specifying the local path (e.g. container = '/full/path/to/image.sif').

```
# e.g. for efetch image using Docker
docker pull ksw9/mtb-call:efetch

# e.g. for efetch image using Singularity
singularity pull ksw9-mtb-call_efetch.img docker://ksw9/mtb-call:efetch
```

- When using singularity, images may require lots of memory for download, so it's advisable to download images using the full resources of a node.

- If the pipeline truncates after a few steps, confirm that all expected files have been downloaded and are in the resources directory. This may be caused by an incomplete download.
