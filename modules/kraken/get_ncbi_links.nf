process GetNCBILinks {
	
  // Get NCBI download links for bacteria, fungi, viral, human complete genomes
  label 'kraken2'

  input:

  output:
  path "ftp_links.tsv", emit: ftp_links

  """
  # Init output file
  touch ftp_links.tsv
  echo -e "group\ttaxid\tfile_name\tftp_link" > ftp_links.tsv

  for group in bacteria fungi viral "vertebrate_mammalian/Homo_sapiens/"
  do

      # Download assemblies list
      wget -w 1 --tries 20 --retry-connrefused --retry-on-host-error https://ftp.ncbi.nlm.nih.gov/genomes/refseq/\${group}/assembly_summary.txt

      # Filter for complete genomes
      grep -P "\tComplete Genome\t" assembly_summary.txt >> assembly_summary_filtered.txt

      # Format output
      awk \
      -v FS='\t' \
      -v OFS='\t' \
      -v group=\${group} \
      -v taxid_column=6 \
      -v accession_column=1 \
      -v name_column=16 \
      -v ftp_column=20 \
      '\$20 != "na" { printf "%s\t%s\t%s_%s_genomic.fna\t%s\\n",group,\$6,\$1,\$16,\$20 }' \
      assembly_summary_filtered.txt >> ftp_links.tsv

      # Remove temp files
      rm assembly_summary.txt assembly_summary_filtered.txt

  done
  """

}