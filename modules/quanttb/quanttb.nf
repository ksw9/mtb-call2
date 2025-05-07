process QuantTB {

  // Detect evidence of mixed infections from FASTQ using QuantTB
  
  label 'slurm'

  publishDir "${projectDir}/results/${batch}/${sample_id}/stats", mode: "copy", pattern: "*_quanttb.csv"

  input:
  tuple val(sample_id), path(read1), path(read2), val(batch)

  output:
  path "${sample_id}_quanttb.csv"

  """
  # Detect evidence of mixed infections from FASTQ
  quanttb quant -f ${read1} ${read2} -abres -resout -o ${sample_id}_quanttb.csv
  """

}