
// ----------------Workflow---------------- //

include { VariantsLoFreq } from '../../modules/variant_calling/variants_lofreq.nf'
include { IndexVCF as IndexFilteredVCF } from '../../modules/variant_calling/index_vcf.nf'
include { AnnotateVCFsnpEff } from '../../modules/variant_calling/annotate_vcf_snpeff.nf'
include { IndexVCF as IndexAnnotatedVCF } from '../../modules/variant_calling/index_vcf.nf'
include { AnnotateVCFBCFtools } from '../../modules/variant_calling/annotate_vcf_bcftools.nf'

workflow LOFREQ {

  take:
  reference_fasta
  reference_fasta_index
  bed_file
  bed_file_index
  vcf_header
  snpeff_dir
  bam_files
	
  main:
  // LOFREQ VARIANT CALLER ---------------- //

  // LoFreq calling
  VariantsLoFreq(reference_fasta, reference_fasta_index, bam_files)

  // Index vcf
  IndexFilteredVCF(VariantsLoFreq.out.lofreq_vcf_filtered)

  // ANNOTATE LOFREQ VCF ------------------ //

  // Join channels by sample_id and batch
  VariantsLoFreq.out.lofreq_vcf_filtered
    .join(IndexFilteredVCF.out.vcf_index, by: [0,1], remainder: false)
    .set{ snpeff_input }

  // Annotation with snpEff
  AnnotateVCFsnpEff("lofreq", snpeff_dir, snpeff_input)

  // Index vcf
  IndexAnnotatedVCF(AnnotateVCFsnpEff.out.vcf_snpeff_ann)

  // Join channels by sample_id and batch
  AnnotateVCFsnpEff.out.vcf_snpeff_ann
    .join(IndexAnnotatedVCF.out.vcf_index, by: [0,1], remainder: false)
    .set{ bcftools_input }

  // Annotation with bcftools
  AnnotateVCFBCFtools("lofreq", bed_file, bed_file_index, vcf_header, bcftools_input)

}
