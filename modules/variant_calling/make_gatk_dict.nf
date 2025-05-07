process MakeGatkDict {

  // Generate a GATK dictionary

  label 'variantcalling'

  publishDir "${params.resources_dir}/${species}_gatk_dictionary", mode: "copy", pattern: "*.dict"

  input:
  tuple val(species), path(fasta), path(fasta_index)

  output:
  tuple val("${species}"), path("*.dict"), emit: gatk_dictionary

  """
  gatk CreateSequenceDictionary -R ${fasta}
  """

}
