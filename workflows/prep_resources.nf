
// ----------------Workflow---------------- //

include { GENOMERESOURCES } from '../subworkflows/genome_resources/genome_resources_prep.nf'
include { SnpeffPrep } from '../modules/snpeff_prep/snpeff_prep.nf'
include { DownloadStandardKraken2DB } from '../modules/kraken/download_standard_kraken2_db.nf'
include { GENERATEKRAKEN2DB } from '../subworkflows/genome_resources/kraken2_db_prep.nf'

workflow RESOURCESPREP {

  // DOWNLOAD AND PREP GENOME REFS -------- //

  GENOMERESOURCES(params.assembly_identifier, params.strain_name)

  // SNPEFF SETUP ------------------------- //

  SnpeffPrep(GENOMERESOURCES.out.snpeff_input)

  // GENERATE KRAKEN2 DATABASE ------------ //

  if (params.kraken2_database_download == "standard") {

    DownloadStandardKraken2DB()

  }
  else if (params.kraken2_database_download == "expanded") {

    GENERATEKRAKEN2DB()

  }
  else if (params.kraken2_database_download != "none") {

    println("ERROR: invalid kraken2_database_download value.")

  }

}