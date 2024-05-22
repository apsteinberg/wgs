#!/bin/bash
#SBATCH --partition=componc_cpu,componc_gpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=20:00:00
#SBATCH --mem=8GB
#SBATCH --job-name=wgs
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=preskaa@mskcc.org
#SBATCH --output=slurm%j_seqtk.out


## activate nf-core conda environment
source /home/preskaa/miniconda3/bin/activate base
# load singularity
module load singularity
## example samplesheet
## technical replicates get merged ...
samplesheet=${HOME}/nanoseq/resources/samplesheet.csv
## specify path to out directory
outdir=/data1/shahs3/users/preskaa/APS017_Archive
test_outdir=${outdir}/wgs_test
## make tmp dir
tmpdir=/data1/shahs3/users/preskaa/tmp
mkdir -p ${tmpdir}
###
sif_path=/data1/shahs3/users/preskaa/singularity/wgs_alignment_latest.sif
input_yaml=${HOME}/wgs/hpc_submission/APS017_PDX_test_inputs.yaml
pipelinedir=${HOME}/wgs
mouse_refdir=/data1/shahs3/isabl_data_lake/assemblies/WGS-MM10/mouse/
refdir=/data1/shahs3/reference/ref-sarcoma/GRCh38/v45/
########
singularity exec ${sif_path} wgs alignment \
    --input_yaml ${input_yaml} \
    --outdir ${test_outdir} \
    --tmpdir ${tmpdir} \
    --pipelinedir ${pipelinedir} \
    --submit slurm \
    --maxjobs 1000 \
    --nocleanup \
    --loglevel DEBUG \
    --sentinel_only \
    --re-run \
    --refdir ${refdir}\
    --PDX \
    --mouse_refdir ${mouse_refdir}



