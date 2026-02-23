process FilterVCF {

  // Variant calling with GATK
  
  label 'variantcalling'

  publishDir "${projectDir}/results/${batch}/${sample_id}/vars", mode: "copy", pattern: "*{_filtering_stats.txt,_filtered.vcf.gz}"

  input:
  each path(scripts_dir)
  tuple val(sample_id), val(batch), path(vcf)

  output:
  tuple val(sample_id), val(batch), path("${sample_id}*_filtered.vcf.gz"), emit: filtered_vcf
  tuple val(sample_id), val(batch), path("${sample_id}_filtering_stats.txt"), emit: vcf_filtering_stats

  """
  bgzip -d ${vcf}
  unzipped_file=\$(basename ${vcf} | sed "s/.gz//g")

  python ${scripts_dir}/filter_vcf.py \
  --vcf_filter "${params.vcf_filter}" \
  --vcf_file \${unzipped_file} \
  ${params.additional_vcf_filtering} >> ${sample_id}_filtering_stats.txt

  filtered_file=\$(basename ${vcf} | sed "s/.vcf.gz/_filtered.vcf/g")
  bgzip \${filtered_file}
  """

}
