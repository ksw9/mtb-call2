
// ----------------Workflow---------------- //

include { VariantsGATK } from '../../modules/variant_calling/variants_gatk.nf'
include { IndexVCF as IndexRawVCF } from '../../modules/variant_calling/index_vcf.nf'
include { IndexVCF as IndexFilteredVCF } from '../../modules/variant_calling/index_vcf.nf'
include { FilterVCF } from '../../modules/variant_calling/filter_vcf.nf'
include { ConvertVCF } from '../../modules/variant_calling/vcf2fasta.nf'
include { AnnotateVCFsnpEff } from '../../modules/variant_calling/annotate_vcf_snpeff.nf'
include { IndexVCF as IndexAnnotatedVCF } from '../../modules/variant_calling/index_vcf.nf'
include { AnnotateVCFBCFtools } from '../../modules/variant_calling/annotate_vcf_bcftools.nf'

workflow GATK {

  take:
  scripts_dir
  reference_fasta
  reference_fasta_index
  gatk_dictionary
  bed_file
  bed_file_index
  vcf_header
  snpeff_dir
  bam_files
	
  main:
  // GATK VARIANT CALLER ------------------ //

  // Variant calling
  VariantsGATK(reference_fasta, reference_fasta_index, gatk_dictionary, bam_files)

  // Index vcf
  IndexRawVCF(VariantsGATK.out.gatk_vcf_unfiltered)

  // Filtering
  FilterVCF(scripts_dir, VariantsGATK.out.gatk_vcf_unfiltered)

  // Index vcf
  IndexFilteredVCF(FilterVCF.out.filtered_vcf)

  // CONVERTING VCF TO FASTA -------------- //

  // Define input
  if (params.use_filtered_vcf_for_fasta) {

    FilterVCF.out.filtered_vcf
      .join(IndexFilteredVCF.out.vcf_index, by: [0,1], remainder: false)
      .set{ vcf_to_fasta_input }

  }
  else {

    VariantsGATK.out.gatk_vcf_unfiltered
      .join(IndexRawVCF.out.vcf_index, by: [0,1], remainder: false)
      .set{ vcf_to_fasta_input }

  }

  // Convert vcf to fasta
  ConvertVCF("gatk", reference_fasta, vcf_to_fasta_input, bed_file, bed_file_index)

  // ANNOTATE GATK VCF -------------------- //

  // Join filtered vcf and index channels by sample_id and batch
  FilterVCF.out.filtered_vcf
    .join(IndexFilteredVCF.out.vcf_index, by: [0,1], remainder: false)
    .set{ snpeff_input }

  // Annotation with snpEff
  AnnotateVCFsnpEff("gatk", snpeff_dir, snpeff_input)

  // Index vcf
  IndexAnnotatedVCF(AnnotateVCFsnpEff.out.vcf_snpeff_ann)

  // Join channels by sample_id and batch
  AnnotateVCFsnpEff.out.vcf_snpeff_ann
    .join(IndexAnnotatedVCF.out.vcf_index, by: [0,1], remainder: false)
    .set{ bcftools_input }

  // Annotation with bcftools
  AnnotateVCFBCFtools("gatk", bed_file, bed_file_index, vcf_header, bcftools_input)

}
