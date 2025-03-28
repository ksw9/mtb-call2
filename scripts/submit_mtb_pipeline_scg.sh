#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --account=jandr
#SBATCH --partition=batch
#SBATCH -o mtb-call_run-out-%j
#SBATCH -e mtb-call_run-err-%j
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kwalter@stanford.edu
#SBATCH --job-name=test

module load java nextflow
# module load singularity # don't use on Stanford SCG

export WORKDIR=/labs/jandr/walter/tb/mtb-call2
export TMPDIR=/tmp/kwalter
export NXF_SINGULARITY_CACHEDIR=$WORKDIR/images

echo "Job started at $(date)"
cd $WORKDIR
nextflow run main.nf -profile singularity,variant_calling
cd $HOME
echo "Job ended at $(date)"
