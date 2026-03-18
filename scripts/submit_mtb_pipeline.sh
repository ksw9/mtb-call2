#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --account=
#SBATCH --partition=
#SBATCH -o mtb-call_run-out-%j
#SBATCH -e mtb-call_run-err-%j
#SBATCH --mail-user=
#SBATCH --job-name=

module load nextflow/20.10 singularity/3.8.7

export WORKDIR=${pwd}
export TMPDIR=
export NXF_SINGULARITY_CACHEDIR=

echo "Job started at $(date)"
nextflow run main.nf -profile singularity,variant_calling -resume
echo "Job ended at $(date)"
