process SummarizeRun {

  // Parse logs from TrimGalore, Kraken, BWA/Bowtie2, Tb-Profiler
  
  label 'makesummary'

  publishDir "${projectDir}/results", mode: "copy", pattern: "*_run_summary_*.tsv"

  input:
  path summary_script
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
  python ${summary_script} --reads_list_file ${reads_list}
  """

}