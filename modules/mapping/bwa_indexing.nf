process BwaIndex {

  // Generate a BWA index

  label 'mapping'

  publishDir "${params.resources_dir}/bwa_index", mode: "copy", pattern: "*.{amb,ann,bwt,pac,sa}"

  input:
  tuple val(strain_name), path(fasta), path(fasta_index)

  output:
  tuple val("${strain_name}"), path("*.amb"), path("*.ann"), path("*.bwt"), path("*.pac"), path("*.sa"), emit: bwa_index

  """
  bwa index ${fasta}
  """

}
