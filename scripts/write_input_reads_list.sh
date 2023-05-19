#!/bin/bash

#####################################################
#### Create input reads list from data directory ####
#####################################################
## Create reads list input with full paths to benchmark data.

DATA_DIR=$1 # path to data directory
list_name=$2 # name of input reads list
suffix_1=${3:-_R1_001.fastq.gz} # FASTQ_1 suffix
batch=${list_name} # defines batch as list_name

# Define suffix_2
suffix_2=${suffix_1/R1/R2}

# Create list with headers
echo -e "sample\tfastq_1\tfastq_2\tbatch" > resources/input/${list_name}.tsv

# Populate list
for fastq_1 in ${DATA_DIR}/*${suffix_1}; do
  fastq_2=${fastq_1/$suffix_1/$suffix_2}
  echo $fastq_2
  samp=$(basename ${fastq_1/$suffix_1})
  echo -e "${samp}\t${fastq_1}\t${fastq_2}\t${batch}" >> resources/input/${list_name}.tsv
done
