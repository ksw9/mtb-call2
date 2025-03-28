
// ----------------Workflow---------------- //

include { VariantsLoFreq } from '../../modules/variant_calling/variants_lofreq.nf'
include { AnnotateVCF } from '../../modules/variant_calling/annotate_vcf.nf'

workflow LOFREQ {

  take:
  bam_files
	
  main:
  // LOFREQ VARIANT CALLER ---------------- //

  // Channel for genome reference fasta
  reference_fasta = Channel.fromPath("${params.resources_dir}/${params.reference_fasta_path}")

  // Channel for genome reference fasta index
  reference_fasta_index = Channel.fromPath("${params.resources_dir}/${params.reference_fasta_index_path}")

  // Channel for ppe masking bed file required by "gatk VariantFiltration" in VariantsGATK
  bed_file = Channel.fromPath("${params.resources_dir}/${params.bed_path}")

  // Channel for ppe masking bed file index required by "gatk VariantFiltration" in VariantsGATK
  bed_file_index = Channel.fromPath("${params.resources_dir}/${params.bed_index_path}")

  // VCF header
  vcf_header = Channel.fromPath("${params.resources_dir}/${params.vcf_header}")

  // Variant calling
  VariantsLoFreq(reference_fasta, reference_fasta_index, bam_files)

  // ANNOTATE LOFREQ VCF ------------------ //

  // Channels for snpEff resources
  Channel.fromPath("${params.resources_dir}/${params.snpeff_dir}")
  .set{ snpeff_dir }

  // Annotation
  AnnotateVCF("lofreq", snpeff_dir, bed_file, bed_file_index, vcf_header, VariantsLoFreq.out.lofreq_filt_vcf)

}
