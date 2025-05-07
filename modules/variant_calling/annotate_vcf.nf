process AnnotateVCF {

  // Annotate VCF for variant examination
  
  label 'variantcalling'

  publishDir "${projectDir}/results/${batch}/${sample_id}/vars", mode: "copy", pattern: "*_${variant_caller}_ann.vcf.gz"

  input:
  each variant_caller
  each path(snpeff_dir)
  each path(bed_file)
  each path(bed_file_index)
  each path(vcf_header)
  tuple val(sample_id), path(vcf), val(batch)

  output:
  path "${sample_id}_${variant_caller}_ann.vcf.gz"

  """
  # Rename Chromosome to be consistent with snpEff/Ensembl genomes.
  zcat ${vcf} | sed 's/NC_000962.3/Chromosome/g' | bgzip > ${sample_id}_renamed.vcf.gz
  tabix ${sample_id}_renamed.vcf.gz

  # Run snpEff and then rename Chromosome.
  java -jar -Xmx8g ${snpeff_dir}/snpEff.jar eff ${params.snpeff_db} ${sample_id}_renamed.vcf.gz -c ${params.snpeff_config} -noStats -no-downstream -no-upstream -canon | sed 's/Chromosome/NC_000962.3/g'| bgzip > ${sample_id}_tmp.vcf.gz
  tabix ${sample_id}_tmp.vcf.gz

  # Also use bed file to annotate vcf, zip.
  bcftools annotate -a ${bed_file} -h ${vcf_header} -c CHROM,FROM,TO,FORMAT/PPE ${sample_id}_tmp.vcf.gz | bgzip > ${sample_id}_${variant_caller}_ann.vcf.gz
  """

}
