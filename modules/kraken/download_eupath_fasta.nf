process DownloadEuPath {
	
  // Download EuPathDB46 fasta sequences
  label 'kraken2'

  input:
  val db

  output:
  path "${db}", emit: fasta_dir

  """
  # Download EuPathDB46 seqid2taxid.map
  wget -w 1 --tries 20 --retry-connrefused --retry-on-host-error ftp://ftp.ccb.jhu.edu/pub/data/EuPathDB46/seqid2taxid.map

  # Download sequences
  wget -w 1 --tries 20 --retry-connrefused --retry-on-host-error ftp://ftp.ccb.jhu.edu/pub/data/EuPathDB46/${db}.tgz
  tar -xzvf ${db}.tgz
  mv \$(basename -s '46' ${db}) ${db} # Databases are named with '46' in gzipped file, but once uncompressed, folder is missing '46'
  rm ${db}.tgz

  # Make headers compatible with Kraken2, then add sequence to library
  for fasta in ${db}/*.fna
  do

    # Get the first fasta sequence header so as to find the taxid
    sample_header=\$(grep -E '^>.*' \${fasta} | head -1)

    # Find taxid for species
    if [[ "\${sample_header}" == *"kraken:taxid|"* ]]
    then

      taxid=\$(echo \${sample_header} | sed 's/>//g' | grep -f - seqid2taxid.map | head -1 | awk '{ print \$2 }')

    else

      taxid=\$(echo \${sample_header} | sed 's/>//g' | sed 's/ //g' | sed 's/|//g' | grep -f - seqid2taxid.map | head -1 | awk '{ print \$2 }')

    fi

    # Modify sequence headers to be compatible with Kraken2
    awk -v taxid=\${taxid} '{ if(\$0 ~ /^>.*/ && \$0 !~ />kraken.*/) { print \$1"|kraken:taxid|"taxid } else { print \$0 } }' \${fasta} > corrected_fasta.fna

    # Replace 'x' bases with 'N'
    awk '{ if(\$0 ~ /^>/) { print \$0 } else { gsub(/x/, "N", \$0) ; print \$0 } }' corrected_fasta.fna > corrected_fasta_xreplaced.fna

    # Replace fasta
    mv corrected_fasta_xreplaced.fna \${fasta}

  done

  # Remove EuPathDB46 seqid2taxid.map (was only needed to convert sequence names to be Kraken2 compatible)
  rm seqid2taxid.map
  """

}
