#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
INSERT PIPELINE DESCRIPTION
*/

// ----------------Workflow---------------- //

include { TrimFastQ } from './modules/trimgalore.nf'
include { Kraken } from './modules/kraken.nf'
include { QuantTB } from './modules/quanttb.nf'
include { MapReads_BWA } from './modules/map_reads_bwa.nf'
include { MapReads_Bowtie } from './modules/map_reads_bowtie.nf'
include { MakeLowCoverageMask } from './modules/make_low_coverage_mask.nf'
include { RunAMR } from './modules/amr.nf'
include { TbProfiler } from './modules/tb_profiler.nf'
include { GATK } from './workflows/gatk_calling.nf'
include { LOFREQ } from './workflows/lofreq_calling.nf'
include { SummarizeRun } from './modules/make_run_summary.nf'

workflow {

  // CREATING RAW-READS CHANNEL ----------- //

  Channel
  .fromPath("${params.resources_dir}/${params.reads_list}")
  .splitCsv(header: true, sep: '\t')
  .map{row -> tuple(row.sample, file(row.fastq_1), file(row.fastq_2), row.batch)}
  .set{raw_reads}

  // TRIMGALORE --------------------------- //

  TrimFastQ(raw_reads)

  // KRAKEN ------------------------------- //

  // Channel for Kraken2 database
  Channel.fromPath("${params.resources_dir}/${params.kraken_database_path}/*{kmer_distrib,k2d,txt,map}")
  .collect()
  .set{kraken_database}

  // Running Kraken2
  Kraken(kraken_database, TrimFastQ.out.trimmed_fastq_files)

  // QUANTTB ------------------------------ //

  //QuantTB(Kraken.out.kraken_filtered_files)

  // MAPPING READS ------------------------ //

  if (params.mapper == "bwa") {

    // MAPPING READS WITH BWA --------------- //

    // Channel for genome reference fasta
    reference_fasta = Channel.fromPath("${params.resources_dir}/${params.reference_fasta_path}")

    // Channel for BWA index
    Channel.fromPath("${params.resources_dir}/${params.bwa_index_path}/*{amb,ann,bwt,pac,sa}")
    .collect()
    .set{bwa_index}

    // Mapping and removing duplicates
    MapReads_BWA(reference_fasta, bwa_index, Kraken.out.kraken_filtered_files)

    bam_files = MapReads_BWA.out.bam_files

    mapping_reports = MapReads_BWA.out.mapping_reports

    coverage_stats = MapReads_BWA.out.coverage_stats

    dup_metrics = MapReads_BWA.out.dup_metrics

  }
  else {

    // MAPPING READS WITH BOWTIE2 ----------- //

    // Channel for Bowtie2 index
    Channel.fromPath("${params.resources_dir}/${params.bowtie_index_path}/*bt2")
    .collect()
    .set{bowtie_index}

    // Mapping and removing duplicates
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

  // Making a bed mask for low coverage regions
  MakeLowCoverageMask(bam_files)

  // GATK variant calling, consensus fasta generation, and cvs file annotation
  GATK(bam_files, MakeLowCoverageMask.out.low_coverage_mask)
  
  // Running LoFreq variant calling and cvs file annotation, if desired

  if (params.run_lofreq == true) {

    LOFREQ(bam_files)

  }

  // MAKING SUMMARY REPORT ---------------- //

  // Creating channel for make_run_summary.py script
  Channel
  .fromPath("${projectDir}/scripts/make_run_summary.py")
  .set{summary_script}
  
  // Creating channel for reads_list file (needed to parse trimming_reports)
  Channel
  .fromPath("${params.resources_dir}/${params.reads_list}")
  .set{reads_list_file}

  SummarizeRun(summary_script, reads_list_file, TrimFastQ.out.trimming_reports.flatten().collect(), Kraken.out.kraken_reports.collect(), mapping_reports.collect(), coverage_stats.collect(), dup_metrics.collect(), TbProfiler.out.tbprofiler_reports.collect())

}