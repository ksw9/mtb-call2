
// ----------------Workflow---------------- //

include { VariantsGATK } from '../modules/variants_gatk.nf'
include { ConvertVCF } from '../modules/vcf2fasta.nf'
include { AnnotateVCF } from '../modules/annotate_vcf.nf'

workflow GATK {

  take:
  bam_files
  low_coverage_mask
	
  main:
  // GATK VARIANT CALLER ------------------ //

  // Channel for genome reference fasta (absolute path from params won't do since the fasta index has to be in same dir for GATK)
  reference_fasta = Channel.fromPath("${params.resources_dir}/${params.reference_fasta_path}")

  // Channel for genome reference fasta index
  reference_fasta_index = Channel.fromPath("${params.resources_dir}/${params.reference_fasta_index_path}")

  // Channel for GATK dictionary (absolute path from params won't do since it has to be present in the dir where GATK is launched)
  gatk_dictionary = Channel.fromPath("${params.resources_dir}/${params.gatk_dictionary_path}")

  // Channel for ppe masking bed file required by "gatk VariantFiltration" in VariantsGATK
  bed_file = Channel.fromPath("${params.resources_dir}/${params.bed_path}")

  // Channel for ppe masking bed file index required by "gatk VariantFiltration" in VariantsGATK
  bed_file_index = Channel.fromPath("${params.resources_dir}/${params.bed_index_path}")

  // VCF header
  vcf_header = Channel.fromPath("${params.resources_dir}/${params.vcf_header}")

  // Variant calling
  VariantsGATK(reference_fasta, reference_fasta_index, gatk_dictionary, bam_files)

  // CONVERTING VCF TO FASTA -------------- //

  // Join VariantsGATK.out.gatk_vcf_filt and low_coverage mask
  VariantsGATK.out.gatk_vcf_filt
  .join(low_coverage_mask, by: [0,2], remainder: false)
  .set{ vcf_to_fasta_input }

  // Convert vcf to fasta
  ConvertVCF("gatk", reference_fasta, vcf_to_fasta_input, bed_file, bed_file_index)

  // ANNOTATE GATK VCF -------------------- //

  // Channels for snpEff resources
  Channel.fromPath("${params.resources_dir}/${params.snpeff_dir}")
    .set{ snpeff_dir }

  // Annotation
  AnnotateVCF("gatk", snpeff_dir, bed_file, bed_file_index, vcf_header, VariantsGATK.out.gatk_vcf_filt)

}
