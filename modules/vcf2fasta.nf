process ConvertVCF {

  // Convert single sample VCF to fasta

  label 'variantcalling'

  publishDir "${projectDir}/results/${batch}/${sample_id}/fasta", mode: "copy", pattern: "*.fa"

  input:
  each variant_caller
  each path(reference)
  tuple val(sample_id), path(vcf), val(batch)
  each path(bed_file)
  each path(bed_index)

  output:
  path "${sample_id}_${variant_caller}.fa", emit: unmasked_fasta
  path "${sample_id}_${variant_caller}_PPEmask.fa", emit: masked_fasta

  """
  # Index vcf
  tabix -p vcf ${vcf}

  # N.B. The vcf files come from individual samples, so no need to specify --sample in bcftools consensus (also, LoFreq does not store sample name info in the vcf).

  if [ ${params.variants_only} == false ]
  then 
  
    # Output 1 - Consensus without ppe masking, but with quality filters applied (exclude indels)
    bcftools consensus --include "(TYPE!='indel' && FORMAT/DP >= ${params.depth_threshold}) && (QUAL >= ${params.qual_threshold}|| RGQ  >= ${params.qual_threshold})" --fasta-ref ${reference} --missing 'N' --absent 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}.fa

    # Output 2 - Consensus with ppe masking and quality filters applied (exclude indels)
    bcftools consensus --include "(TYPE!='indel' && FORMAT/DP >= ${params.depth_threshold}) && (QUAL >= ${params.qual_threshold}|| RGQ  >= ${params.qual_threshold})"  --mask ${bed_file} --fasta-ref ${reference} --absent 'N' --missing 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}_PPEmask.fa
  
  else

    # Output 1 - Consensus without ppe masking, but with quality filters applied (exclude indels). Positions absent from VCF will be included as consensus. 
    bcftools consensus --include "(TYPE!='indel' && FORMAT/DP >= ${params.depth_threshold}) && (QUAL >= ${params.qual_threshold}|| RGQ  >= ${params.qual_threshold})" --fasta-ref ${reference} --missing 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}.fa

    # Output 2 - Consensus with ppe masking and quality filters applied (exclude indels). Positions absent from VCF will be included as consensus. 
    bcftools consensus --include "(TYPE!='indel' && FORMAT/DP >= ${params.depth_threshold}) && (QUAL >= ${params.qual_threshold}|| RGQ  >= ${params.qual_threshold})"  --mask ${bed_file} --fasta-ref ${reference} --missing 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}_PPEmask.fa
  
  fi
  """

}
