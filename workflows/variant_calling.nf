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
include { RunAMR } from '../modules/amr/amr.nf'
include { TbProfiler } from '../modules/tb_profiler/tb_profiler.nf'
include { GATK } from '../subworkflows/variant_calling/gatk_calling.nf'
include { LOFREQ } from '../subworkflows/variant_calling/lofreq_calling.nf'
include { SummarizeRun } from '../modules/summarize/make_run_summary.nf'

workflow VARIANTCALLING {

  // LOAD GENOME RESOURCES ---------------- //

  // Channel for scripts directory
  scripts_dir = Channel.fromPath("${projectDir}/scripts")

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

  // Channel for GATK dictionary (absolute path from params won't do since it has to be present in the dir where GATK is launched)
  gatk_dictionary = Channel.fromPath("${params.resources_dir}/${params.gatk_dictionary_path}")

  // Channel for BWA index
  Channel.fromPath("${params.resources_dir}/${params.bwa_index_path}/*{amb,ann,bwt,pac,sa}")
    .collect()
    .set{ bwa_index }

  // Channel for Bowtie2 index
  Channel.fromPath("${params.resources_dir}/${params.bowtie_index_path}/*bt2")
    .collect()
    .set{ bowtie_index }

  // Channel for Kraken2 database
  Channel.fromPath("${params.resources_dir}/${params.kraken_database_path}/*{kmer_distrib,k2d,txt,map}")
    .collect()
    .set{ kraken_database }

  // Channels for snpEff resources
  Channel.fromPath("${params.resources_dir}/${params.snpeff_dir}")
    .set{ snpeff_dir }

  // CREATING RAW-READS CHANNEL ----------- //

  Channel
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
  Channel
    .fromPath("${params.resources_dir}/${params.reads_list}")
    .set{reads_list_file}

  SummarizeRun(scripts_dir, reads_list_file, TrimFastQ.out.trimming_reports.flatten().collect(), Kraken.out.kraken_reports.collect(), mapping_reports.collect(), coverage_stats.collect(), dup_metrics.collect(), TbProfiler.out.tbprofiler_reports.collect())

}