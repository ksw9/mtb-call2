
// ----------------Workflow---------------- //

include { VariantsGATK } from '../../modules/variant_calling/variants_gatk.nf'
include { FilterVCF } from '../../modules/variant_calling/filter_vcf.nf'
include { ConvertVCF } from '../../modules/variant_calling/vcf2fasta.nf'
include { AnnotateVCF } from '../../modules/variant_calling/annotate_vcf.nf'

workflow GATK {

  take:
  bam_files
	
  main:
  // CREATE RESOURCES CHANNELS ------------ //

  // Creating channel for filter_vcf.py script
  filtering_script = Channel.fromPath("${projectDir}/scripts/filter_vcf.py")

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

  // GATK VARIANT CALLER ------------------ //

  // Variant calling
  VariantsGATK(reference_fasta, reference_fasta_index, gatk_dictionary, bam_files)

  // Filtering
  FilterVCF(filtering_script, VariantsGATK.out.gatk_vcf_unfiltered)

  // CONVERTING VCF TO FASTA -------------- //

  // Define input
  if (params.use_filtered_vcf_for_fasta) {

    vcf_to_fasta_input = FilterVCF.out.filtered_vcf

  }
  else {

    vcf_to_fasta_input = VariantsGATK.out.gatk_vcf_unfiltered

  }

  // Convert vcf to fasta
  ConvertVCF("gatk", reference_fasta, vcf_to_fasta_input, bed_file, bed_file_index)

  // ANNOTATE GATK VCF -------------------- //

  // Channels for snpEff resources
  Channel.fromPath("${params.resources_dir}/${params.snpeff_dir}")
  .set{ snpeff_dir }

  // Annotation
  AnnotateVCF("gatk", snpeff_dir, bed_file, bed_file_index, vcf_header, FilterVCF.out.filtered_vcf)

}
