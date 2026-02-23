process AnnotateVCFsnpEff {

  // Annotate VCF for variant examination
  
  label 'download_refs'

  //publishDir "${projectDir}/results/${batch}/${sample_id}/vars", mode: "copy", pattern: "*_${variant_caller}_ann_snpeff.vcf.gz"

  input:
  each variant_caller
  each path(snpeff_dir)
  tuple val(sample_id), val(batch), path(vcf), path(index)

  output:
  tuple val(sample_id), val(batch), path("${sample_id}_${variant_caller}_ann_snpeff.vcf.gz"), emit: vcf_snpeff_ann

  """
  # Rename Chromosome to be consistent with snpEff/Ensembl genomes.
  zcat ${vcf} | sed 's/NC_000962.3/Chromosome/g' | bgzip > ${sample_id}_renamed.vcf.gz
  #tabix ${sample_id}_renamed.vcf.gz

  # Run snpEff and then rename Chromosome.
  java -jar -Xmx8g ${snpeff_dir}/snpEff.jar eff ${params.snpeff_db} ${sample_id}_renamed.vcf.gz -c ${params.snpeff_config} -noStats -no-downstream -no-upstream -canon | sed 's/Chromosome/NC_000962.3/g'| bgzip > ${sample_id}_${variant_caller}_ann_snpeff.vcf.gz
  #tabix ${sample_id}_${variant_caller}_ann_snpeff.vcf.gz
  """

}
