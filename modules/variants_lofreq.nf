process VariantsLoFreq {

  // Variant calling with LoFreq
  
  label 'variantcalling'

  publishDir "${projectDir}/results/${batch}/${sample_id}/vars", mode: "copy", pattern: "*{_lofreq_unfilt,_lofreq_filt}.vcf.gz"

  input:
  each path(reference)
  each path(reference_index)
  tuple val(sample_id), path(bam), val(batch)

  output:
  tuple val(sample_id), path("${sample_id}_lofreq_unfilt.vcf.gz"), val(batch), emit: lofreq_unfilt_vcf
  tuple val(sample_id), path("${sample_id}_lofreq_filt.vcf.gz"), val(batch), emit: lofreq_filt_vcf

  """
  # Indexing bam
  samtools index ${bam}

  # Call variants with LoFreq, no filter
  lofreq call-parallel --call-indels --pp-threads \$SLURM_CPUS_ON_NODE --no-default-filter -f ${reference} -o ${sample_id}_lofreq_unfilt_tmp.vcf ${bam}

  # Add FORMAT and SAMPLE fields for full VCF formatting (required for later annotation)
  sed -e '6i##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">' -e "s|FILTER\tINFO|FILTER\tINFO\tFORMAT\t${sample_id}|g" ${sample_id}_lofreq_unfilt_tmp.vcf | \
  awk -F"\t" -v genotype=1 -v OFS="\t" '/^[^#]/{ \$9 = "GT"; \$10 = genotype }1' | bgzip > ${sample_id}_lofreq_unfilt.vcf.gz

  # Call variants with LoFreq, default filter
  lofreq call-parallel --call-indels --pp-threads \$SLURM_CPUS_ON_NODE -f ${reference} -o ${sample_id}_lofreq_filt_tmp.vcf ${bam}

  # Add FORMAT and SAMPLE fields for full VCF formatting (required for later annotation)
  sed -e '6i##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">' -e "s|FILTER\tINFO|FILTER\tINFO\tFORMAT\t${sample_id}|g" ${sample_id}_lofreq_filt_tmp.vcf | \
  awk -F"\t" -v genotype=1 -v OFS="\t" '/^[^#]/{ \$9 = "GT"; \$10 = genotype }1' | bgzip > ${sample_id}_lofreq_filt.vcf.gz
  """

}
