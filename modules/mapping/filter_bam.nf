process FilterBam {

  // Bam filtering to remove unmapped, secondary, and supplementary alignments

  label 'mapping'

  //publishDir "${projectDir}/results/${batch}/${sample_id}/bams", mode: "copy", pattern: "*_filtered.bam"
  //publishDir "${projectDir}/results/${batch}/${sample_id}/bams", mode: "copy", pattern: "*_filtered.bam.bai"

  input:
  tuple val(sample_id), val(batch), path(bam), path(bai)

  output:
  tuple val(sample_id), val(batch), path("${sample_id}_filtered.bam"), path("${sample_id}_filtered.bam.bai"), emit: bam_files

  script:
  """
  # Filtering bam
  samtools view -bh -F 4 -F 256 -F 2048 ${bam} -o ${sample_id}_filtered.bam
  
  # Indexing bam
  samtools index ${sample_id}_filtered.bam
  """

}
