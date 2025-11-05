process BowtieIndex {

  // Generate a Bowtie2 index

  label 'mapping'

  publishDir "${params.resources_dir}/bowtie2_index", mode: "copy", pattern: "*.bt2"

  input:
  tuple val(strain_name), path(fasta), path(fasta_index)

  output:
  tuple val("${strain_name}"), path("*.bt2"), emit: bowtie_index

  """
  bowtie2-build -f ${fasta} ${params.bowtie_index_prefix}
  """

}
