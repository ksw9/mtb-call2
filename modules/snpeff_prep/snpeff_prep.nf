process SnpeffPrep {

  // Prep databases for SnpEff

  label 'download_refs'

  publishDir "${params.resources_dir}", mode: "copy", pattern: "snpEff"

  input:
  tuple val(strain_name), path(gff)

  output:
  path "snpEff", emit: snpeff

  """
  # Download SnpEff for gene annotation.
  wget ${params.snpeff_url}

  # Unzip file
  unzip snpEff_latest_core.zip

  ### Building annotations
  # Step 1. Configure a new genome
  echo "" >> snpEff/snpEff.config
  echo "# Mycobacterium tuberculosis genome, version ${params.assembly_identifier}" >> snpEff/snpEff.config
  echo "${params.snpeff_db}.genome : Mycobacterium_tuberculosis_${params.snpeff_db}" >> snpEff/snpEff.config

  # Step 2. Building a database from GFF
  mkdir -p snpEff/data/${params.snpeff_db}
  cp ${gff} snpEff/data/${params.snpeff_db}/genes.gff
  java -jar snpEff/snpEff.jar build -gff3 -v -noCheckCds -noCheckProtein ${params.snpeff_db}
  """

}
