### Create truth VCF ###
cd tb/benchmark

# Set up conda environment 'benchmark' on Utah kingspeak1
module load mamba
module load htslib
mamba create -n benchmark -c bioconda mummer python=3
mamba install -n benchmark -c bioconda art
mamba install -n benchmark -c bioconda entrez-direct
mamba install -n benchmark biopython
mamba install -n benchmark tabix
source activate benchmark

# Install hap.py (requires Python2)
git clone
mamba create -n happy -c bioconda pysam python=2  # hap.py requires python2
mamba install -n happy pandas python=2
# Follow instructions from Github to make (use python2)

## Organize directories
ref_dir=resources/refs/
mkdir $ref_dir
results_dir=results/
mkdir $results_dir
data_dir=data/
mkdir $data_dir
query_name='AE000516.fasta'
ncbi_id_query=AE000516.2
ref_name="H37Rv.fasta"
ncbi_id_ref="NC_000962.3"
prefix=H37Rv_AE000516


## 1. Download CDC genome ##
ncbi_id_query=AE000516.2
esearch -db nucleotide -query ${ncbi_id_query} | efetch -format fasta > ${ref_dir}${query_name}
ncbi_id_ref="NC_000962.3"
esearch -db nucleotide -query ${ncbi_id_ref} | efetch -format fasta > ${ref_dir}${ref_name}

## 2a. Pairwise align genomes with Mummer ##
# use default cluster length
nucmer --maxmatch ${ref_dir}${ref_name} ${ref_dir}${query_name} -p ${results_dir}${prefix}

# 3. identify SNPs between genomes with respect to H37Rv, generate truth VCF
delta-filter -r -q ${results_dir}${prefix}.delta > ${results_dir}${prefix}.filter
show-snps -TIr ${results_dir}${prefix}.filter > ${results_dir}${prefix}.snps # same length as without the delta-filter. 

# Remove the -C flag in show-snps because it removes necessary columns [R] and [Q]. Instead filter where those columns are not equal ot 0. 
awk '{if($7!=1 && $8!=1) print $0}' ${results_dir}${prefix}.snps > ${results_dir}${prefix}_unique.snps 

## 4. Convert SNPs file to truth VCF file for AE000516 ##
git clone https://github.com/MatteoSchiavinato/all2vcf.git
all2vcf/all2vcf mummer --snps ${results_dir}${prefix}_unique.snps --input-header --output-header --reference ${ref_dir}${ref_name} >  ${results_dir}${prefix}.vcf
# Add GT line (for compatibility with hap.py) 
cat results/H37Rv_AE000516.vcf | sed 's/INFO$/INFO\tFORMAT\tAE000516/' | sed  '/^#/! s/\S*$/GT\t1/' > ${results_dir}${prefix}_fmt.vcf

# Add to header: 
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
bgzip -c ${results_dir}${prefix}_fmt.vcf > ${results_dir}${prefix}_fmt.vcf.gz
tabix ${results_dir}${prefix}_fmt.vcf.gz

## 2b. Pairwise align genomes with Mummer ##
# extend cluster length to 1500
nucmer --maxmatch --mincluster 1500 ${ref_dir}${ref_name} ${ref_dir}${query_name} -p ${results_dir}${prefix}_c1500

# 3b. identify SNPs between genomes with respect to H37Rv, generate truth VCF
delta-filter -r -q ${results_dir}${prefix}_c1500.delta > ${results_dir}${prefix}_c1500.filter
show-snps -TIr ${results_dir}${prefix}_c1500.filter > ${results_dir}${prefix}_c1500.snps # same length as without the delta-filter. 

# Remove the -C flag in show-snps because it removes necessary columns [R] and [Q]. Instead filter where those columns are not equal ot 0. 
awk '{if($7!=1 && $8!=1) print $0}' ${results_dir}${prefix}_c1500.snps > ${results_dir}${prefix}_c1500_unique.snps 

## 4b. Convert SNPs file to truth VCF file for AE000516 ##
all2vcf/all2vcf mummer --snps ${results_dir}${prefix}_c1500_unique.snps --input-header --output-header --reference ${ref_dir}${ref_name} >  ${results_dir}${prefix}_c1500.vcf
# Add GT line (for compatibility with hap.py) 
cat ${results_dir}${prefix}_c1500.vcf | sed 's/INFO$/INFO\tFORMAT\tAE000516/' | sed  '/^#/! s/\S*$/GT\t1/' > ${results_dir}${prefix}_c1500_fmt.vcf

# Add to header: 
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
bgzip -c ${results_dir}${prefix}_c1500_fmt.vcf > ${results_dir}${prefix}_c1500_fmt.vcf.gz
tabix ${results_dir}${prefix}_c1500_fmt.vcf.gz

## 2c. Create a truth file for H37Rv (no snps)
zcat ${results_dir}${prefix}_fmt.vcf.gz | head -n9 | sed 's/AE000516/H37Rv/' | sed 's/1$/0/g' | bgzip -c > ${results_dir}H37Rv_H37Rv_fmt.vcf.gz
tabix ${results_dir}H37Rv_H37Rv_fmt.vcf.gz

## 5. Simulate reads ##
# from CDC genome ##
art_illumina -ss HS25 -sam -i ${ref_dir}${query_name} --paired -l 150 -f 100 -m 650 -s 150 -o ${data_dir}AE000516_sims

# from H37Rv genome ##
art_illumina -ss HS25 -sam -i ${ref_dir}${ref_name} --paired -l 150 -f 100 -m 650 -s 150 -o ${data_dir}H37Rv_sims

# zip
ls data/*fq | parallel bgzip

## 6. Create input reads TSV ##
echo -e "sample\tfastq_1\tfastq_2\tbatch" > data/benchmarking_reads_list.tsv
for p1 in ${data_dir}*_sims1.fq.gz; do 
  sample=$(basename ${p1/_sims*})
  p2=${p1/sims1/sims2}
  echo -e "${sample}\t$(pwd)/${p1}\t$(pwd)/${p2}\tbenchmark" >> data/benchmarking_reads_list.tsv
done 

# Soft link to resources directory
ln -s /uufs/chpc.utah.edu/common/home/walter-group1/tb/benchmark/data/benchmarking_reads_list.tsv  /uufs/chpc.utah.edu/common/home/walter-group1/tb/mtb-call2/resources/input/benchmarking_reads_list.tsv

## 7. Call variants with pipeline ##
cd /uufs/chpc.utah.edu/common/home/walter-group1/tb/mtb-call2

## 8. Run hap.py ##
source activate happy
python2 bin/hap.py --version
happy=/uufs/chpc.utah.edu/common/home/walter-group1/repos/hap.py-build/bin/hap.py
truth_vcf=test_reads/benchmark/${prefix}_fmt.vcf.gz
query_vcf=results/benchmark/AE000516/vars/AE000516_gatk_filt.vcf.gz 
bed=resources/bed/H37Rv_ppe.bed.gz

# a. Performance genome-wide using most sensitive truth VCF set
${happy} ${truth_vcf} ${query_vcf} -o perf -r ${ref_dir}${ref_name} --set-gt hom
# b. Performance outside of PE/PPE genes
${happy} ${truth_vcf} ${query_vcf} -o perf -r ${ref_dir}${ref_name} --set-gt hom -T ^$bed

# Redefine truth set to be more stringent
truth_vcf=test_reads/benchmark/${prefix}_c1500_fmt.vcf.gz

# c. Performance genome-wide using most sensitive truth VCF set
${happy} ${truth_vcf} ${query_vcf} -o perf -r ${ref_dir}${ref_name} --set-gt hom
# d. Performance outside of PE/PPE genes
${happy} ${truth_vcf} ${query_vcf} -o perf -r ${ref_dir}${ref_name} --set-gt hom -T ^$bed

# e. Do this for H37Rv too. 
truth_vcf=${results_dir}H37Rv_H37Rv_fmt.vcf.gz
query_vcf=../WalterPipeline/results/benchmark/H37Rv/vars/H37Rv_gatk_filt.vcf.gz 

# No snps identified: hap.py won't run, perfect specificity.
bcftools view --types 'snps' $query_vcf
