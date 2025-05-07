process FastaIndex {

  // Index a fasta file

  label 'mapping'

  publishDir "${params.resources_dir}/refs", mode: "copy", pattern: "*.fai"

  input:
  tuple val(strain_name), path(fasta)

  output:
  tuple val("${strain_name}"), path("${fasta}.fai"), emit: fasta_index

  """
  samtools faidx ${fasta}
  """

}
