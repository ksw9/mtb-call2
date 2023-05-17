process Kraken {

  // Filter reads taxonomically with Kraken
  
  label 'slurm'

  //publishDir "${projectDir}/results/${batch}/${sample_id}/kraken", mode: "copy", pattern: "*_kr_{1,2}.fq.gz"
  publishDir "${projectDir}/results/${batch}/${sample_id}/kraken", mode: "copy", pattern: "*_kraken.report"

  input:
  path(kraken_db)
  tuple val(sample_id), path(read1), path(read2), val(batch)

  output:
  path "*_kraken.report", emit: kraken_reports
  tuple val("${sample_id}"), path("${sample_id}_kr_1.fq.gz"), path("${sample_id}_kr_2.fq.gz"), val("${batch}"), emit: kraken_filtered_files

  """
  # run kraken to taxonomically classify paired-end reads and write output file.
  kraken2 --db . --paired --gzip-compressed --threads \$SLURM_CPUS_ON_NODE --report ${sample_id}_kraken.report --use-names ${read1} ${read2} --output ${sample_id}.out

  # Remove Illumina suffixes from read names (Kraken reads list does not include suffixes) 
  zcat ${read1} | sed 's|/1\$||' | bgzip > ${sample_id}_plain_1.fq.gz
  zcat ${read2} | sed 's|/2\$||' | bgzip > ${sample_id}_plain_2.fq.gz

  # Select for reads directly assigned to Mycobacterium genus (G) (taxid 1763), reads assigned directly to Mycobacterium tuberculosis complex (G1) (taxid 77643), and reads assigned to Mycobacterium tuberculosis (S) and children. *this includes reads assigned to Mtb and those assigned to the genus, but not a different species.
  # N.B. A space is added to the header name to make them unique (otherwise a grep call with @ID123 would get not just @ID123, but also @ID1234, etc)
  grep -E 'Mycobacterium (taxid 1763)|Mycobacterium tuberculosis' ${sample_id}.out | awk '{print \$2" "}' > ${sample_id}_reads.list
  echo "" >> ${sample_id}_reads.list # Add empty line otherwise last read name will not be passed to while call at lines 39,51

  # Use bbmap to select reads corresponding to taxa of interest.
  # filterbyname.sh int=false in1=${sample_id}_plain_1.fq.gz  in2=${sample_id}_plain_2.fq.gz  out1=${sample_id}_kr_1.fq.gz out2=${sample_id}_kr_2.fq.gz names=${sample_id}_reads.list include=true overwrite=true
  
  # bbmap tends to glitch, so the following code is meant to replace it
  bgzip -d ${sample_id}_plain_1.fq.gz
  awk '{ if(\$0 ~ /@/) { print \$0" " } else { print \$0 } }' ${sample_id}_plain_1.fq > ${sample_id}_plain_1_mod.fq
  #awk '{ print }' ${sample_id}_reads.list | grep -f - -A 3 ${sample_id}_plain_1_mod.fq | bgzip > ${sample_id}_kr_1.fq.gz

  while read -r pattern
  do

    # Find first pattern occurrence and stop
    grep "\$pattern" -m 1 -A 3 ${sample_id}_plain_1_mod.fq

  done < ${sample_id}_reads.list | bgzip > ${sample_id}_kr_1.fq.gz
  
  bgzip -d ${sample_id}_plain_2.fq.gz
  awk '{ if(\$0 ~ /@/) { print \$0" " } else { print \$0 } }' ${sample_id}_plain_2.fq > ${sample_id}_plain_2_mod.fq
  #awk '{ print }' ${sample_id}_reads.list | grep -f - -A 3 ${sample_id}_plain_2_mod.fq | bgzip > ${sample_id}_kr_2.fq.gz

  while read -r pattern
  do

    # Find first pattern occurrence and stop
    grep "\$pattern" -m 1 -A 3 ${sample_id}_plain_2_mod.fq

  done < ${sample_id}_reads.list | bgzip > ${sample_id}_kr_2.fq.gz
  
  # Summarize Kraken statistics. 
  #${projectDir}/scripts/kraken_stats.sh ${sample_id}_kraken.report
  """

}
