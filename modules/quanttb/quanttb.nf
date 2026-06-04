process QuantTB {

  // Detect evidence of mixed infections from FASTQ using QuantTB
  
  label 'slurm'

  //publishDir "${projectDir}/results/${batch}/${sample_id}/stats", mode: "copy", pattern: "*_quanttb.csv"

  input:
  tuple val(sample_id), val(batch), path(read1), path(read2)

  output:
  tuple val(sample_id), val(batch), path("${sample_id}_quanttb.csv"), emit: quantb_report

  script:
  """
  # Detect evidence of mixed infections from FASTQ
  quanttb quant -f ${read1} ${read2} -abres -resout -o ${sample_id}_quanttb.csv
  """

}