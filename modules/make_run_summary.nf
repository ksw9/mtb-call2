process SummarizeRun {

  // Parse logs from TrimGalore, Kraken, BWA/Bowtie2, Tb-Profiler
  
  label 'makesummary'

  publishDir "${projectDir}/results", mode: "copy", pattern: "pipeline_run_summary_*.tsv"

  input:
  path reads_list
  path trimming_reports
  path kraken_reports
  path mapping_reports
  path coverage_stats
  path dup_metrics
  path tbprofiler_reports

  output:
  path "pipeline_run_summary_*.tsv"

  """
  python ${projectDir}/scripts/make_run_summary.py --reads_list_file ${reads_list}
  """

}