process TrimFastQ {

  // Trim reads for quality

  label 'trimgalore'

  //publishDir "${projectDir}/results/${batch}/${sample_id}/trim", mode: "copy", pattern: "*_val_{1,2}.fq.gz"
  publishDir "${projectDir}/results/${batch}/${sample_id}/trim", mode: "copy", pattern: "*_fastqc.{html,zip}"
  publishDir "${projectDir}/results/${batch}/${sample_id}/trim", mode: "copy", pattern: "*_trimming_report.txt"

  input:
  tuple val(sample_id), path(read1), path(read2), val(batch)

  output:
  path "*_fastqc.{html,zip}"
  path "*_trimming_report.txt", emit: trimming_reports
  tuple val(sample_id), path("{${sample_id}_val_1.fq.gz,${sample_id}_trimmed.fq.gz}"), path("{${sample_id}_val_2.fq.gz,mock.trim.fastq}"), val(batch), emit: trimmed_fastq_files

  """
  # Trim adapters and short reads, for all platforms but NextSeq
  if [[ "${read2}" == "mock.fastq" ]]
  then

    if [ "${params.nextseq}" = false ]
    then
    
      trim_galore \
      --cores \$SLURM_CPUS_ON_NODE \
      --output_dir . \
      --basename ${sample_id} \
      --fastqc \
      --gzip \
      ${read1}
    
    # Trim adapters and short reads, for NextSeq
    else
    
      trim_galore \
      --cores 4 \
      --cores \$SLURM_CPUS_ON_NODE \
      --output_dir . \
      --basename ${sample_id} \
      --nextseq ${params.nextseq_qual_threshold} \
      --fastqc \
      --gzip \
      ${read1}
    
    fi

    # Adding mock read2 output
    touch mock.trim.fastq

  else

    if [ "${params.nextseq}" = false ]
    then
    
      trim_galore \
      --cores \$SLURM_CPUS_ON_NODE \
      --output_dir . \
      --basename ${sample_id} \
      --fastqc \
      --gzip \
      --paired \
      ${read1} ${read2}
    
    # Trim adapters and short reads, for NextSeq
    else
    
      trim_galore \
      --cores 4 \
      --cores \$SLURM_CPUS_ON_NODE \
      --output_dir . \
      --basename ${sample_id} \
      --nextseq ${params.nextseq_qual_threshold} \
      --fastqc \
      --gzip \
      --paired \
      ${read1} ${read2}
    
    fi

  fi
  """

}