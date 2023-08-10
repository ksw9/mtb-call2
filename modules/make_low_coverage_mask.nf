process MakeLowCoverageMask {

  // Creating a bed file with low coverage sites
  
  label 'variantcalling'

  publishDir "${projectDir}/results/${batch}/${sample_id}/vars", mode: "copy", pattern: "*.bed.gz"

  input:
  tuple val(sample_id), path(bam), val(batch)

  output:
  tuple val(sample_id), path("${sample_id}_low_coverage_mask.bed.gz"), val(batch), emit: low_coverage_mask

  """
  # Compute depth for bam file at each position
  samtools depth -a ${bam} > ${sample_id}_depth.txt

  # Create bed mask for low coverage sites
  awk -v min_depth=${params.depth_threshold} '{ if (\$3 < min_depth) { print \$1"\t"\$2-1"\t"\$2"\t"\$1"_"\$2"_lowcoverage" } }' ${sample_id}_depth.txt | bgzip > ${sample_id}_low_coverage_mask.bed.gz
  """

}
