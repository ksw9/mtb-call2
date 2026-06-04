#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
M. tuberculosis variant identification pipeline
*/

// ----------------Workflow---------------- //

include { TrimFastQ } from '../modules/trimming/trimgalore.nf'
include { Kraken } from '../modules/kraken/kraken.nf'
include { QuantTB } from '../modules/quanttb/quanttb.nf'
include { MapReads_BWA } from '../modules/mapping/map_reads_bwa.nf'
include { MapReads_Bowtie } from '../modules/mapping/map_reads_bowtie.nf'
include { FilterBam } from '../modules/mapping/filter_bam.nf'
include { RunAMR } from '../modules/amr/amr.nf'
include { TbProfiler } from '../modules/tb_profiler/tb_profiler.nf'
include { GATK } from '../subworkflows/variant_calling/gatk_calling.nf'
include { LOFREQ } from '../subworkflows/variant_calling/lofreq_calling.nf'
include { SummarizeRun } from '../modules/summarize/make_run_summary.nf'

workflow VARIANTCALLING {

  main:
  // LOAD GENOME RESOURCES ---------------- //

  // Channel for scripts directory
  scripts_dir = channel.fromPath("${projectDir}/scripts")

  // Channel for genome reference fasta
  reference_fasta = channel.fromPath("${params.resources_dir}/${params.reference_fasta_path}")

  // Channel for genome reference fasta index
  reference_fasta_index = channel.fromPath("${params.resources_dir}/${params.reference_fasta_index_path}")

  // Channel for ppe masking bed file required by "gatk VariantFiltration" in VariantsGATK
  bed_file = channel.fromPath("${params.resources_dir}/${params.bed_path}")

  // Channel for ppe masking bed file index required by "gatk VariantFiltration" in VariantsGATK
  bed_file_index = channel.fromPath("${params.resources_dir}/${params.bed_index_path}")

  // VCF header
  vcf_header = channel.fromPath("${params.resources_dir}/${params.vcf_header}")

  // Channel for GATK dictionary (absolute path from params won't do since it has to be present in the dir where GATK is launched)
  gatk_dictionary = channel.fromPath("${params.resources_dir}/${params.gatk_dictionary_path}")

  // Channel for BWA index
  channel.fromPath("${params.resources_dir}/${params.bwa_index_path}/*{amb,ann,bwt,pac,sa}")
    .collect()
    .set{ bwa_index }

  // Channel for Bowtie2 index
  channel.fromPath("${params.resources_dir}/${params.bowtie_index_path}/*bt2")
    .collect()
    .set{ bowtie_index }

  // Channel for Kraken2 database
  channel.fromPath("${params.resources_dir}/${params.kraken_database_path}/*{kmer_distrib,k2d,txt,map}")
    .collect()
    .set{ kraken_database }

  // Channels for snpEff resources
  channel.fromPath("${params.resources_dir}/${params.snpeff_dir}")
    .set{ snpeff_dir }

  // CREATING RAW-READS CHANNEL ----------- //

  channel
    .fromPath("${params.resources_dir}/${params.reads_list}")
    .splitCsv(header: true, sep: '\t')
    .map{ row -> tuple(row.sample, row.batch, file(row.fastq_1), file(row.fastq_2)) }
    .set{ raw_reads }

  // TRIMGALORE --------------------------- //

  TrimFastQ(raw_reads)

  // KRAKEN ------------------------------- //

  Kraken(kraken_database, TrimFastQ.out.trimmed_fastq_files)

  // QUANTTB ------------------------------ //

  //QuantTB(Kraken.out.kraken_filtered_files)

  // MAPPING READS ------------------------ //

  if (params.mapper == "bwa") {

    // MAPPING READS WITH BWA --------------- //

    MapReads_BWA(reference_fasta, bwa_index, Kraken.out.kraken_filtered_files)

    bam_files = MapReads_BWA.out.bam_files

    mapping_reports = MapReads_BWA.out.mapping_reports

    coverage_stats = MapReads_BWA.out.coverage_stats

    dup_metrics = MapReads_BWA.out.dup_metrics

  }
  else {

    // MAPPING READS WITH BOWTIE2 ----------- //

    MapReads_Bowtie(reference_fasta, bowtie_index, Kraken.out.kraken_filtered_files)

    bam_files = MapReads_Bowtie.out.bam_files

    mapping_reports = MapReads_Bowtie.out.mapping_reports

    coverage_stats = MapReads_Bowtie.out.coverage_stats

    dup_metrics = MapReads_Bowtie.out.dup_metrics

  }

  // FILTER BAM (OPTIONAL) ---------------- //

  if (params.filter_bam == true) {

    FilterBam(bam_files)

    bam_files = FilterBam.out.bam_files

  }

  // AMR ---------------------------------- //

  RunAMR(bam_files)

  // TB PROFILER -------------------------- //

  TbProfiler(bam_files)

  // VARIANT CALLING ---------------------- //

  // GATK variant calling, consensus fasta generation, and cvs file annotation
  GATK(scripts_dir, reference_fasta, reference_fasta_index, gatk_dictionary, bed_file, bed_file_index, vcf_header, snpeff_dir, bam_files)
  
  // Running LoFreq variant calling and cvs file annotation, if desired

  if (params.run_lofreq == true) {

    LOFREQ(reference_fasta, reference_fasta_index, bed_file, bed_file_index, vcf_header, snpeff_dir, bam_files)

  }

  // MAKING SUMMARY REPORT ---------------- //
  
  // Creating channel for reads_list file (needed to parse trimming_reports)
  channel
    .fromPath("${params.resources_dir}/${params.reads_list}")
    .set{ reads_list_file }
  
  // Create collected reports channel without sample_id and batch values
  TrimFastQ.out.trimming_reports.map{ r -> r[2] }.flatten()
    .mix(Kraken.out.kraken_reports.map{ r -> r[2] }.flatten())
    .mix(mapping_reports.map{ r -> r[2] }.flatten())
    .mix(coverage_stats.map{ r -> r[2] }.flatten())
    .mix(dup_metrics.map{ r -> r[2] }.flatten())
    .mix(TbProfiler.out.tbprofiler_reports.map{ r -> r[2] }.flatten())
    .collect()
    .set{ reports }

  // Summarize run
  SummarizeRun(scripts_dir, reads_list_file, reports)

  emit:
  fastqc_reports = TrimFastQ.out.fastqc_reports
  trimming_reports = TrimFastQ.out.trimming_reports
  trimmed_fastq_files = TrimFastQ.out.trimmed_fastq_files
  kraken_reports = Kraken.out.kraken_reports
  kraken_filtered_files = Kraken.out.kraken_filtered_files
  bam_files
  mapping_reports
  coverage_stats
  dup_metrics
  amr_reports = RunAMR.out.amr_report
  tbprofiler_reports = TbProfiler.out.tbprofiler_reports
  tbprofiler_reports_json = TbProfiler.out.tbprofiler_reports_json
  tbprofiler_errlog = TbProfiler.out.tbprofiler_errlog
  gatk_gvcf = GATK.out.gatk_gvcf
  gatk_vcf_unfiltered = GATK.out.gatk_vcf_unfiltered
  gatk_vcf_unfiltered_index = GATK.out.gatk_vcf_unfiltered_index
  gatk_filtered_vcf = GATK.out.gatk_filtered_vcf
  gatk_filter_vcf_index = GATK.out.gatk_filter_vcf_index
  gatk_unmasked_fasta = GATK.out.gatk_unmasked_fasta
  gatk_masked_fasta = GATK.out.gatk_masked_fasta
  gatk_vcf_snpeff_ann = GATK.out.gatk_vcf_snpeff_ann
  gatk_vcf_snpeff_ann_index = GATK.out.gatk_vcf_snpeff_ann_index
  gatk_vcf_bcftools_ann = GATK.out.gatk_vcf_bcftools_ann
  lofreq_vcf_unfiltered = params.run_lofreq ? LOFREQ.out.lofreq_vcf_unfiltered : channel.empty()
  lofreq_vcf_filtered = params.run_lofreq ? LOFREQ.out.lofreq_vcf_filtered : channel.empty()
  lofreq_vcf_filtered_index = params.run_lofreq ? LOFREQ.out.lofreq_vcf_filtered_index : channel.empty()
  lofreq_vcf_snpeff_ann = params.run_lofreq ? LOFREQ.out.lofreq_vcf_snpeff_ann : channel.empty()
  lofreq_vcf_snpeff_ann_index = params.run_lofreq ? LOFREQ.out.lofreq_vcf_snpeff_ann_index : channel.empty()
  lofreq_vcf_bcftools_ann = params.run_lofreq ? LOFREQ.out.lofreq_vcf_bcftools_ann : channel.empty()
  run_summary = SummarizeRun.out.run_summary

}