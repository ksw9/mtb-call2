process BowtieIndex {

  // Generate a Bowtie2 index

  label 'mapping'

  publishDir "${params.resources_dir}/bowtie2_index", mode: "copy", pattern: "*.{amb,ann,bwt,pac,sa}"

  input:
  tuple val(strain_name), path(fasta), path(fasta_index)

  output:
  tuple val("${strain_name}"), path("*.amb"), path("*.ann"), path("*.bwt"), path("*.pac"), path("*.sa"), emit: bowtie_index

  """
  bowtie2-build ${fasta} ${params.bowtie_index_prefix}
  """

}
