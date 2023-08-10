# *M. tuberculosis* variant identification benchmarking

Genomic epidemiology relies on accurate identification of *M. tuberculosis* variants. We and others have reported on significant differences between variant identification pipelines that may alter transmission inferences. Filtering is critical but identifying an optimal pipeline and set of filters--and the tradeoffs between sensitivity and specificity--may be determined by specific application. 

We previously conducted a variant identification [experiment](https://doi.org/10.1099/mgen.0.000418) and found that a combination of bwa and GATK outperformed other tool combinations. We described our simulation-based benchmarking approach there. 

To measure performance of this pipeline, including the filters set by the use, we include two read sets: simulated Illumina reads from the (a) CDC1551 and (b) H37Rv reference genomes. Reads were simulated with [ART](https://www.niehs.nih.gov/research/resources/software/biostatistics/art/index.cfm). To generate a truth set of variants, we pairwise aligned the CDC1551 and H37Rv reference genomes with MUMMER and identified SNPs between the two genomes.

1. Download [hap.py](https://github.com/Illumina/hap.py), a variant calling benchmarking tool. (Compiling from source may be the easiest option.)
- hap.py requires Python2.

2. Run pipeline on benchmarking data. To do this, update the nextflow.config: reads_list = 'input/benchmarking_reads_list.tsv'
```
nextflow run main.nf -profile singularity # or docker
```

3. Evaluate performance of identifying SNPs in the CDC1551 genome inside and outside of the PE/PPE gene set. Will report both performance in full VCF and excluding any site with a FILTER tag (i.e. those failing the quality or depth filters specified in the nextflow.config).
```
truth_vcf=test_reads/benchmark/H37Rv_AE000516_c1500_fmt.vcf.gz
query=results/benchmark/AE000516/vars/AE000516_gatk_filt.vcf.gz
bed=resources/bed/H37Rv_ppe.bed.gz
ref_dir=resources/refs/
ref=H37Rv.fasta

# Include entire genome
hap.py ${truth_vcf} ${query_vcf} -o perf -r ${ref_dir}${ref_name} --set-gt hom

# Exclude regions defined in the bed file.
hap.py ${truth_vcf} ${query_vcf} -o perf -r ${ref_dir}${ref_name} --set-gt hom -T ^${bed}
```
- We report a recall of 91.4% (845/925) and precision of 99.5% (845/849) when excluding the PE/PPE genes with the pipeline default filters.
- We report a recall of 77.4% (1162/1502) and precision of 93.6% (1162/1225) when including the full gneome with the pipeline default filters. 

4. Evaluate specificity of variant identification in the H37Rv data. There should be 0 SNPs identified in the H37Rv data (i.e. 100% specificity).
```
bcftools view --types 'snps' results/benchmark/H37Rv/vars/H37Rv_gatk_filt.vcf.gz 
```
5. We constructed the truth VCF through pairwise alignment. However, differet alignment strategies result in different sets of SNPs and therefore alter performance measurements. We constructed the pairwise alignment as described [previously](https://doi.org/10.1099/mgen.0.000418), setting the mincluster length to 1500 (to increase specificity). We also include an alternative truth VCF: `test_reads/benchmark/H37Rv_AE000516_fmt.vcf.gz` with mincluster length as the default (which may increase sensitivity). 
