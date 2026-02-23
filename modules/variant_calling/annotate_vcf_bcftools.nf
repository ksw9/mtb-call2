process AnnotateVCFBCFtools {

  // Annotate VCF for variant examination
  
  label 'variantcalling'

  publishDir "${projectDir}/results/${batch}/${sample_id}/vars", mode: "copy", pattern: "*_${variant_caller}_ann.vcf.gz"

  input:
  each variant_caller
  each path(bed_file)
  each path(bed_file_index)
  each path(vcf_header)
  tuple val(sample_id), val(batch), path(vcf), path(index)

  output:
  tuple val(sample_id), val(batch), path("${sample_id}_${variant_caller}_ann.vcf.gz"), emit: vcf_bcftools_ann

  """
  # Also use bed file to annotate vcf, zip.
  bcftools annotate -a ${bed_file} -h ${vcf_header} -c CHROM,FROM,TO,FORMAT/PPE ${vcf} | bgzip > ${sample_id}_${variant_caller}_ann.vcf.gz
  """

}
