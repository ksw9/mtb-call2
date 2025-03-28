
// ----------------Workflow---------------- //

include { DownloadRefs } from '../../modules/download_refs/download_ref.nf'
include { FastaIndex } from '../../modules/ref_indexing/fasta_indexing.nf'
include { BwaIndex } from '../../modules/mapping/bwa_indexing.nf'
include { BowtieIndex } from '../../modules/mapping/bowtie_indexing.nf'
include { MakeGatkDict } from '../../modules/variant_calling/make_gatk_dict.nf'
include { SnpeffInputPrep } from '../../modules/snpeff_prep/snpeff_input_prep.nf'

workflow GENOMERESOURCES {

  take:
  assembly_identifier
  strain_name
	
  main:
  // Channel for scripts directory
  scripts_dir = Channel.fromPath("${projectDir}/scripts")

  // DOWNLOAD REFERENCE GENOMES ----------- //

  DownloadRefs(assembly_identifier, strain_name)

  // FASTA INDEXING ----------------------- //

  // Index fasta
  FastaIndex(DownloadRefs.out.fasta)

  // Merge channels
  DownloadRefs.out.fasta
  .join(FastaIndex.out.fasta_index, by: 0, remainder: false)
  .set{ indexed_fasta }

  // MAPPING TOOL INDEXING ---------------- //
  
  // BWA index
  BwaIndex(indexed_fasta)

  // Bowtie2 index
  BowtieIndex(indexed_fasta)

  // GATK DICTIONARY GENERATION ----------- //

  MakeGatkDict(indexed_fasta)

  // SNPEFF INPUT PREP

  // Merge channels
  DownloadRefs.out.fasta
  .join(DownloadRefs.out.gtf, by: 0, remainder: false)
  .set{ fasta_and_gtf }

  SnpeffInputPrep(fasta_and_gtf)

  emit:
  snpeff_input = SnpeffInputPrep.out.snpeff_input

}
