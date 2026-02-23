process IndexVCF {

  // Index VCF

  label 'variantcalling'

  input:
  tuple val(sample_id), val(batch), path(vcf)

  output:
  tuple val(sample_id), val(batch), path("*.tbi"), emit: vcf_index

  """
  # Index vcf
  tabix -p vcf ${vcf}
  """

}
