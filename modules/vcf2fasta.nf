process ConvertVCF {

  // Convert single sample VCF to fasta

  label 'variantcalling'

  publishDir "${projectDir}/results/${batch}/${sample_id}/fasta", mode: "copy", pattern: "*.fa"

  input:
  each variant_caller
  each path(reference)
  tuple val(sample_id), val(batch), path(vcf), path(low_coverage_mask)
  each path(bed_file)
  each path(bed_index)

  output:
  path "${sample_id}_${variant_caller}.fa", emit: unmasked_fasta
  path "${sample_id}_${variant_caller}_PPEmask.fa", emit: masked_fasta

  """
  # Index vcf
  tabix -p vcf ${vcf}

  # Combine ppe bed_file to low_coverage_mask
  zcat ${low_coverage_mask} > full_mask_unsorted.bed
  zcat ${bed_file} >> full_mask_unsorted.bed

  # Sort bed file
  cat full_mask_unsorted.bed | sort -k1,1 -k2,2n | bgzip > full_mask.bed.gz

  # Indexing low_coverage_mask and full_mask bed file
  tabix -p bed ${low_coverage_mask}
  tabix -p bed full_mask.bed.gz

  # N.B. The vcf files come from individual samples, so no need to specify --sample in bcftools consensus (also, LoFreq does not store sample name info in the vcf).

  if [ ${params.variants_only} == false ]
  then 
  
    # Output 1 - Consensus without ppe masking, but with quality filters applied and low coverage masking (exclude indels)
    bcftools consensus --include "(TYPE!='indel') && (QUAL >= ${params.qual_threshold} || RGQ >= ${params.qual_threshold})" --mask ${low_coverage_mask} --fasta-ref ${reference} --missing 'N' --absent 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}.fa

    # Output 2 - Consensus with low coverage and ppe masking and quality filters applied (exclude indels)
    bcftools consensus --include "(TYPE!='indel') && (QUAL >= ${params.qual_threshold} || RGQ >= ${params.qual_threshold})" --mask full_mask.bed.gz --fasta-ref ${reference} --missing 'N' --absent 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}_PPEmask.fa
  
  else
  
    # Output 1 - Consensus without ppe masking, but with quality filters applied and low coverage masking (exclude indels). Positions absent from VCF will be included as consensus. 
    bcftools consensus --include "(TYPE!='indel') && (QUAL >= ${params.qual_threshold} || RGQ >= ${params.qual_threshold})" --mask ${low_coverage_mask} --fasta-ref ${reference} --missing 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}.fa

    # Output 2 - Consensus with low coverage and ppe masking and quality filters applied (exclude indels). Positions absent from VCF will be included as consensus. 
    bcftools consensus --include "(TYPE!='indel') && (QUAL >= ${params.qual_threshold} || RGQ >= ${params.qual_threshold})" --mask full_mask.bed.gz --fasta-ref ${reference} --missing 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}_PPEmask.fa
  
  fi
  """

}
