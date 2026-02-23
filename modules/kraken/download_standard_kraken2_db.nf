process DownloadStandardKraken2DB {
  
  // Download the standard K2 database
  label 'kraken2'

  errorStrategy 'ignore'

  publishDir "${params.resources_dir}/kraken_db", mode: "copy", pattern: "standard"

  input:

  output:
  path "standard", optional: true, emit: kraken_db

  """
  # Test that the link is good
  wget_test=\$(wget -S --spider "${params.kraken2_standard_db_link}" 2>&1)

  # Download if good link
  if [[ \${wget_test} == *"Remote file exists."* ]]
  then

    wget -w 1 --tries 20 --retry-connrefused --retry-on-host-error "${params.kraken2_standard_db_link}"

    # Decompress file
    tar -xvzf *.tar.gz

    # Move output to specified directory
    mkdir standard
    mv *.{k2d,map,kmer_distrib,tsv,txt,dmp} standard

  fi
  """

}
