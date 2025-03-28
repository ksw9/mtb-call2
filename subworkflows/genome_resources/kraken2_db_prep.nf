
// ----------------Workflow---------------- //

include { GetNCBILinks } from '../../modules/kraken/get_ncbi_links.nf'
include { DownloadNCBI } from '../../modules/kraken/download_ncbi_fasta.nf'
include { DownloadEuPath } from '../../modules/kraken/download_eupath_fasta.nf'
include { GenerateKraken2DB } from '../../modules/kraken/generate_kraken2_db.nf'

workflow GENERATEKRAKEN2DB {

  main:
  // DOWNLOAD NCBI REFERENCE GENOMES ------ //

  // Create list of NCBI ftp links
  GetNCBILinks()

  // Reshape
  GetNCBILinks.out.ftp_links
    .splitCsv(header: true, sep: '\t')
    .map{row -> tuple(row.group, row.taxid, row.file_name, row.ftp_link)}
    .set{ ftp_links }

  // Download sequences from NCBI
  DownloadNCBI(ftp_links)

  // DOWNLOAD EUPATHDB46 REFERENCES ------- //

  // Channel for EuPathDB46 databases
  Channel
    .fromList( ['AmoebaDB46', 'CryptoDB46', 'FungiDB46', 'GiardiaDB46', 'MicrosporidiaDB46', 'PiroplasmaDB46', 'PlasmoDB46', 'ToxoDB46', 'TrichDB46', 'TriTrypDB46'] )
    .set{ eupath_dbs }

  // Download EuPath sequences
  DownloadEuPath(eupath_dbs)

  // BUILD KRAKEN2 DB --------------------- //

  GenerateKraken2DB(DownloadNCBI.out.fasta.collect(), DownloadEuPath.out.fasta_dir.collect())

}
