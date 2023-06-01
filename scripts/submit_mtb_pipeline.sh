#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --account=walter
#SBATCH --partition=notchpeak
#SBATCH -o mtb-call_run-out-%j
#SBATCH -e mtb-call_run-err-%j
#SBATCH --mail-user=katharine.walter@hsc.utah.edu
#SBATCH --job-name=vitoria

module load nextflow/20.10 singularity/3.8.7

export WORKDIR=/uufs/chpc.utah.edu/common/home/walter-group1/tb/mtb-call2
export TMPDIR=/scratch/general/nfs1/u6045141/tmp
export NXF_SINGULARITY_CACHEDIR=$WORKDIR/images

echo "Job started at $(date)"
cd $WORKDIR
nextflow run main.nf -profile singularity
cd $HOME
echo "Job ended at $(date)"
