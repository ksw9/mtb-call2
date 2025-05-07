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

  if [ ${params.fasta_vcf_sites_only} == false ]
  then 
  
    # Output 1 - Consensus without ppe masking and with indels exclusion. Positions absent from VCF will be included as consensus.
    bcftools consensus --include "(TYPE!='indel')" --fasta-ref ${reference} --missing 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}.fa

    # Output 2 - Consensus with ppe masking and indels exclusion. Positions absent from VCF will be included as consensus.
    bcftools consensus --include "(TYPE!='indel')" --mask ${bed_file} --fasta-ref ${reference} --missing 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}_PPEmask.fa
  
  else
  
    # Output 1 - Consensus without ppe masking and with indels exclusion.
    bcftools consensus --include "(TYPE!='indel')" --fasta-ref ${reference} --missing 'N' --absent 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}.fa

    # Output 2 - Consensus with ppe masking and indels exclusion.
    bcftools consensus --include "(TYPE!='indel')" --mask ${bed_file} --fasta-ref ${reference} --missing 'N' --absent 'N' ${vcf} | \
    sed "s/>NC_000962.3 Mycobacterium tuberculosis H37Rv, complete genome/>${sample_id}/g" > ${sample_id}_${variant_caller}_PPEmask.fa
  
  fi
  """

}
