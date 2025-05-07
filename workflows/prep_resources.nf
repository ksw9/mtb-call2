
// ----------------Workflow---------------- //

include { GENOMERESOURCES } from '../subworkflows/genome_resources/genome_resources_prep.nf'
include { SnpeffPrep } from '../modules/snpeff_prep/snpeff_prep.nf'
include { GENERATEKRAKEN2DB } from '../subworkflows/genome_resources/kraken2_db_prep.nf'

workflow RESOURCESPREP {

  // DOWNLOAD AND PREP GENOME REFS -------- //

  GENOMERESOURCES(params.assembly_identifier, params.strain_name)

  // SNPEFF SETUP ------------------------- //

  SnpeffPrep(GENOMERESOURCES.out.snpeff_input)

  // GENERATE KRAKEN2 DATABASE ------------ //

  GENERATEKRAKEN2DB()

}