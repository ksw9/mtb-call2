#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
INSERT PIPELINE DESCRIPTION
*/

// ----------------Workflow---------------- //

include { RESOURCESPREP } from './workflows/prep_resources.nf'
include { VARIANTCALLING } from './workflows/variant_calling.nf'

workflow {

  if (params.prep_resources) {
    
    RESOURCESPREP()

  }

  if (params.variant_calling) {

    VARIANTCALLING()

  }

}