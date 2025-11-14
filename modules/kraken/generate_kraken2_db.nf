process GenerateKraken2DB {
	
	// Build a Kraken2 database with bacteria, fungi, viral, human complete genomes, and EuPathDB46 (eukaryotic pathogen genomes)
  label 'kraken2'

  publishDir "${params.resources_dir}/kraken_db", mode: "copy", pattern: "standard_plus_eupath46"

  input:
  path ncbi_fasta
  path eupath_fasta_dirs

  output:
  path "standard_plus_eupath46", emit: kraken_db

  """
  # Make folder for database
  db_dir=standard_plus_eupath46
  mkdir -p \${db_dir}

  # Download kraken2 taxonomy
  kraken2-build --db \${db_dir} --download-taxonomy

  # Add ncbi sequences to library folder
  for fasta in *.fna
  do

    # Add sequence to library
    if [[ \${fasta} == "nomasking_"* ]]
    then

      fasta_renamed=\$(echo "\${fasta}" | sed "s/nomasking_//g")
      mv \${fasta} \${fasta_renamed}
      kraken2-build --db \${db_dir} --add-to-library \${fasta_renamed} --no-masking

    else
      
      kraken2-build --db \${db_dir} --add-to-library \${fasta}

    fi

  done

  # Add EuPathDB46 (eukaryotic pathogen genomes) sequences to library folder
  for db in AmoebaDB46 CryptoDB46 FungiDB46 GiardiaDB46 MicrosporidiaDB46 PiroplasmaDB46 PlasmoDB46 ToxoDB46 TrichDB46 TriTrypDB46
  do

    # Add individual sequences to library
    for fasta in \${db}/*fna
    do

      # Add sequence to library
      kraken2-build --db \${db_dir} --add-to-library \${fasta}

    done

  done

  # Build database
  kraken2-build --build --threads \${SLURM_CPUS_ON_NODE} --db \${db_dir}

  # Clean up
  kraken2-build --clean --db \${db_dir}
  """

}
