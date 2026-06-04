#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
M. tuberculosis variant identification pipeline
*/

// ----------------Workflow---------------- //

include { RESOURCESPREP } from './workflows/prep_resources.nf'
include { VARIANTCALLING } from './workflows/variant_calling.nf'

workflow {

  main:
  if (params.prep_resources) {
    
    RESOURCESPREP()

  }

  if (params.variant_calling) {

    VARIANTCALLING()

  }

  publish:
  fasta = params.prep_resources ? RESOURCESPREP.out.fasta : channel.empty()
  fasta_index = params.prep_resources ? RESOURCESPREP.out.fasta_index : channel.empty()
  gff = params.prep_resources ? RESOURCESPREP.out.gff : channel.empty()
  bwa_index = params.prep_resources ? RESOURCESPREP.out.bwa_index : channel.empty()
  bowtie_index = params.prep_resources ? RESOURCESPREP.out.bowtie_index : channel.empty()
  gatk_dict = params.prep_resources ? RESOURCESPREP.out.gatk_dict : channel.empty()
  snpeff = params.prep_resources ? RESOURCESPREP.out.snpeff : channel.empty()
  kraken_db = params.prep_resources ? RESOURCESPREP.out.kraken_db : channel.empty()
  fastqc_reports = params.variant_calling ? VARIANTCALLING.out.fastqc_reports : channel.empty()
  trimming_reports = params.variant_calling ? VARIANTCALLING.out.trimming_reports : channel.empty()
  trimmed_fastq_files = params.variant_calling ? VARIANTCALLING.out.trimmed_fastq_files : channel.empty()
  kraken_reports = params.variant_calling ? VARIANTCALLING.out.kraken_reports : channel.empty()
  kraken_filtered_files = params.variant_calling ? VARIANTCALLING.out.kraken_filtered_files : channel.empty()
  //bam_files = params.variant_calling ? VARIANTCALLING.out.bam_files : channel.empty()
  mapping_reports = params.variant_calling ? VARIANTCALLING.out.mapping_reports : channel.empty()
  coverage_stats = params.variant_calling ? VARIANTCALLING.out.coverage_stats : channel.empty()
  dup_metrics = params.variant_calling ? VARIANTCALLING.out.dup_metrics : channel.empty()
  amr_reports = params.variant_calling ? VARIANTCALLING.out.amr_reports : channel.empty()
  tbprofiler_reports = params.variant_calling ? VARIANTCALLING.out.tbprofiler_reports : channel.empty()
  tbprofiler_reports_json = params.variant_calling ? VARIANTCALLING.out.tbprofiler_reports_json : channel.empty()
  tbprofiler_errlog = params.variant_calling ? VARIANTCALLING.out.tbprofiler_errlog : channel.empty()
  gatk_gvcf = params.variant_calling ? VARIANTCALLING.out.gatk_gvcf : channel.empty()
  gatk_vcf_unfiltered = params.variant_calling ? VARIANTCALLING.out.gatk_vcf_unfiltered : channel.empty()
  gatk_vcf_unfiltered_index = params.variant_calling ? VARIANTCALLING.out.gatk_vcf_unfiltered_index : channel.empty()
  gatk_filtered_vcf = params.variant_calling ? VARIANTCALLING.out.gatk_filtered_vcf : channel.empty()
  gatk_filter_vcf_index = params.variant_calling ? VARIANTCALLING.out.gatk_filter_vcf_index : channel.empty()
  gatk_unmasked_fasta = params.variant_calling ? VARIANTCALLING.out.gatk_unmasked_fasta : channel.empty()
  gatk_masked_fasta = params.variant_calling ? VARIANTCALLING.out.gatk_masked_fasta : channel.empty()
  gatk_vcf_snpeff_ann = params.variant_calling ? VARIANTCALLING.out.gatk_vcf_snpeff_ann : channel.empty()
  gatk_vcf_snpeff_ann_index = params.variant_calling ? VARIANTCALLING.out.gatk_vcf_snpeff_ann_index : channel.empty()
  gatk_vcf_bcftools_ann = params.variant_calling ? VARIANTCALLING.out.gatk_vcf_bcftools_ann : channel.empty()
  lofreq_vcf_unfiltered = params.variant_calling ? VARIANTCALLING.out.lofreq_vcf_unfiltered : channel.empty()
  lofreq_vcf_filtered = params.variant_calling ? VARIANTCALLING.out.lofreq_vcf_filtered : channel.empty()
  lofreq_vcf_filtered_index = params.variant_calling ? VARIANTCALLING.out.lofreq_vcf_filtered_index : channel.empty()
  lofreq_vcf_snpeff_ann = params.variant_calling ? VARIANTCALLING.out.lofreq_vcf_snpeff_ann : channel.empty()
  lofreq_vcf_snpeff_ann_index = params.variant_calling ? VARIANTCALLING.out.lofreq_vcf_snpeff_ann_index : channel.empty()
  lofreq_vcf_bcftools_ann = params.variant_calling ? VARIANTCALLING.out.lofreq_vcf_bcftools_ann : channel.empty()
  run_summary = params.variant_calling ? VARIANTCALLING.out.run_summary : channel.empty()

}

output {

  fasta {
    path "${params.resources_dir}/refs"
  }
  fasta_index {
    path "${params.resources_dir}/refs"
  }
  gff {
    path "${params.resources_dir}/refs"
  }
  bwa_index {
    path "${params.resources_dir}/bwa_index"
  }
  bowtie_index {
    path "${params.resources_dir}/bowtie2_index"
  }
  gatk_dict {
    path { out -> "${params.resources_dir}/${out[0]}_gatk_dictionary" }
  }
  snpeff {
    path "${params.resources_dir}"
  }
  kraken_db {
    path "${params.resources_dir}/kraken_db"
  }
  fastqc_reports {
    path { out -> "results/${out[1]}/${out[0]}/trim" }
  }
  trimming_reports {
    path { out -> "results/${out[1]}/${out[0]}/trim" }
  }
  trimmed_fastq_files {
    path { out -> "results/${out[1]}/${out[0]}/trim" }
  }
  kraken_reports {
    path { out -> "results/${out[1]}/${out[0]}/kraken" }
  }
  kraken_filtered_files {
    path { out -> "results/${out[1]}/${out[0]}/kraken" }
  }
  //bam_files {
  //  path { out -> "results/${out[1]}/${out[0]}/bams" }
  //}
  mapping_reports {
    path { out -> "results/${out[1]}/${out[0]}/stats" }
  }
  coverage_stats {
    path { out -> "results/${out[1]}/${out[0]}/stats" }
  }
  dup_metrics {
    path { out -> "results/${out[1]}/${out[0]}/stats" }
  }
  amr_reports {
    path { out -> "results/${out[1]}/${out[0]}/stats" }
  }
  tbprofiler_reports {
    path { out -> "results/${out[1]}/${out[0]}/stats" }
  }
  tbprofiler_reports_json {
    path { out -> "results/${out[1]}/${out[0]}/stats" }
  }
  tbprofiler_errlog {
    path { out -> "results/${out[1]}/${out[0]}/stats" }
  }
  gatk_gvcf {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  gatk_vcf_unfiltered {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  gatk_vcf_unfiltered_index {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  gatk_filtered_vcf {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  gatk_filter_vcf_index {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  gatk_unmasked_fasta {
    path { out -> "results/${out[1]}/${out[0]}/fasta" }
  }
  gatk_masked_fasta {
    path { out -> "results/${out[1]}/${out[0]}/fasta" }
  }
  gatk_vcf_snpeff_ann {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  gatk_vcf_snpeff_ann_index {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  gatk_vcf_bcftools_ann {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  lofreq_vcf_unfiltered {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  lofreq_vcf_filtered {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  lofreq_vcf_filtered_index {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  lofreq_vcf_snpeff_ann {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  lofreq_vcf_snpeff_ann_index {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  lofreq_vcf_bcftools_ann {
    path { out -> "results/${out[1]}/${out[0]}/vars" }
  }
  run_summary {
    path "results"
  }

}