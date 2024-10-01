process Kraken {

  // Filter reads taxonomically with Kraken
  
  label 'kraken2'

  //publishDir "${projectDir}/results/${batch}/${sample_id}/kraken", mode: "copy", pattern: "*_kr_{1,2}.fq.gz"
  publishDir "${projectDir}/results/${batch}/${sample_id}/kraken", mode: "copy", pattern: "*_kraken.report"

  input:
  path(kraken_db)
  tuple val(sample_id), path(read1), path(read2), val(batch)

  output:
  path "*_kraken.report", emit: kraken_reports
  tuple val(sample_id), path("{${sample_id}_kr_1.fq.gz,${sample_id}_kr.fq.gz}"), path("{${sample_id}_kr_2.fq.gz,mock.kr.fastq}"), val(batch), emit: kraken_filtered_files

  """
  if [[ "${read2}" == "mock.trim.fastq" ]]
  then

    # run kraken to taxonomically classify paired-end reads and write output file.
    kraken2 --db . --gzip-compressed --threads \$SLURM_CPUS_ON_NODE --report ${sample_id}_kraken.report --use-names ${read1} --output ${sample_id}.out

    # Get list of reads from Mycobacterium
    grep -E 'Mycobacterium (taxid 1763)|Mycobacterium tuberculosis' ${sample_id}.out | awk '{print \$2}' > ${sample_id}_reads.list
    
    # Use seqtk to select reads corresponding to the Mycobacterium genus and not corresponding to species other than M. tuberculosis
    seqtk subseq ${read1} ${sample_id}_reads.list | bgzip > ${sample_id}_kr.fq.gz

    # Adding mock read2 output
    touch mock.kr.fastq

  else

    # run kraken to taxonomically classify paired-end reads and write output file.
    kraken2 --db . --paired --gzip-compressed --threads \$SLURM_CPUS_ON_NODE --report ${sample_id}_kraken.report --use-names ${read1} ${read2} --output ${sample_id}.out

    # Get list of reads from Mycobacterium
    grep -E 'Mycobacterium (taxid 1763)|Mycobacterium tuberculosis' ${sample_id}.out | awk '{print \$2}' > ${sample_id}_reads.list
    
    # Use seqtk to select reads corresponding to the Mycobacterium genus and not corresponding to species other than M. tuberculosis
    seqtk subseq ${read1} ${sample_id}_reads.list | bgzip > ${sample_id}_kr_1.fq.gz
    seqtk subseq ${read2} ${sample_id}_reads.list | bgzip > ${sample_id}_kr_2.fq.gz

  fi

"""
}
