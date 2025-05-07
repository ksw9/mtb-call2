process SnpeffInputPrep {

  // Prep input gff for SnpEff database creation

  label 'download_refs'

  input:
  tuple val(strain_name), path(fasta), path(gff)

  output:
  tuple val("${strain_name}"), path("${strain_name}_genes.gff"), emit: snpeff_input

  """
  # Add fasta sequence to gff
  cp ${gff} ${strain_name}_genes.gff
  echo "" >> ${strain_name}_genes.gff
  echo "##FASTA" >> ${strain_name}_genes.gff
  cat ${fasta} >> ${strain_name}_genes.gff
  """

}