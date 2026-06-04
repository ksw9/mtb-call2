process SummarizeRun {

  // Parse logs from TrimGalore, Kraken, BWA/Bowtie2, Tb-Profiler
  
  label 'makesummary'

  //publishDir "${projectDir}/results", mode: "copy", pattern: "*_run_summary_*.tsv"

  input:
  path scripts_dir
  path reads_list
  path reports

  output:
  path "*_run_summary_*.tsv", emit: run_summary

  script:
  """
  python ${scripts_dir}/make_run_summary.py --reads_list_file ${reads_list}
  """

}
