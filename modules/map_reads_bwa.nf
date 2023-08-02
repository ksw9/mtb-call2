process MapReads_BWA {

  // Map reads and remove duplicates in same step
  
  label 'mapping'

  //publishDir "${projectDir}/results/${batch}/${sample_id}/bams", mode: "copy", pattern: "*_merged_mrkdup.bam"
  publishDir "${projectDir}/results/${batch}/${sample_id}/stats", mode: "copy", pattern: "*_mapping.log"
  publishDir "${projectDir}/results/${batch}/${sample_id}/stats", mode: "copy", pattern: "*_coverage_stats.txt"
  publishDir "${projectDir}/results/${batch}/${sample_id}/stats", mode: "copy", pattern: "*_marked_dup_metrics.txt"

  input:
  each path(reference_fasta)
  path(bwa_index)
  tuple val(sample_id), path(read1), path(read2), val(batch)

  output:
  tuple val(sample_id), path("${sample_id}_merged_mrkdup.bam"), val(batch), emit: bam_files
  path "${sample_id}_mapping.log", emit: mapping_reports
  path "${sample_id}_coverage_stats.txt", emit: coverage_stats
  path "${sample_id}_marked_dup_metrics.txt", emit: dup_metrics

  """
  # Get machine id_lane from SRA read identifier (old Illumina fastq format)
  read_name=\$(zcat ${read1} | head -n 1)
  read_name=\${read_name/@}
  read_name=\$(echo \${read_name} | cut -d' ' -f1)
  flowcell="\$(echo \${read_name} | cut -d: -f1-2)"
  barcode="\$(echo \${read_name} | cut -d: -f3)"
  lane="\$(echo \${read_name} | cut -d: -f4)"
  if [ "\$flowcell" == "\$lane" ]; then 
    ID=\${read_name}
    PU=\${read_name}
  else 
    ID="\${flowcell}'.'\${lane}"
    PU="\${flowcell}'.'\${barcode}'.'\${lane}"
  fi
  
  # Mapping with BWA
  bwa mem \
  -t \$SLURM_CPUS_ON_NODE \
  ${reference_fasta} \
  ${read1} ${read2} > temp.sam

  # Sort and convert to bam
  gatk SortSam \
  -I temp.sam \
  -O temp.bam \
  -SORT_ORDER coordinate

  # Extracting mapping stats
  sambamba flagstat -t \$SLURM_CPUS_ON_NODE temp.bam > ${sample_id}_mapping.log

  # Collect coverage stats with Picard
  picard CollectWgsMetrics \
  R=${reference_fasta} \
  I=temp.bam \
  O=${sample_id}_coverage_stats.txt

  # Add/replace read groups for post-processing with GATK
  picard AddOrReplaceReadGroups \
  INPUT=temp.bam \
  OUTPUT=temp_rg.bam \
  RGID=\${ID} \
  RGLB=${params.library} \
  RGPU=\${PU} \
  RGPL=${params.seq_platform} \
  RGSM=${sample_id}

  # Mark duplicates & produce library complexity metrics
  gatk MarkDuplicates \
  -I temp_rg.bam \
  -O ${sample_id}_merged_mrkdup.bam  \
  -M ${sample_id}_marked_dup_metrics.txt  
      
  # Mark duplicates with Spark (also sorts BAM) & produce library complexity metrics
  # Need to use Java 7 or Java 11 (https://gatk.broadinstitute.org/hc/en-us/community/posts/4417665825307-java-lang-reflect-InaccessibleObjectException-Unable-to-make-field-transient-java-lang-Object-java-util-ArrayList-elementData-accessible-module-java-base-does-not-opens-java-util-to-unnamed-module-3bf44630)
  #gatk MarkDuplicatesSpark \
  #-I temp_rg.bam \
  #-O ${sample_id}_merged_mrkdup.bam \
  #-M ${sample_id}_marked_dup_metrics.txt  
  
  # Base (Quality Score) Recalibration: not done because no 'known variants.'
  """

}