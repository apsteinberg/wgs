#!/bin/bash
#SBATCH --partition=componc_cpu,componc_gpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=20:00:00
#SBATCH --mem=20GB
#SBATCH --job-name=bwa
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=preskaa@mskcc.org
#SBATCH --output=slurm%j_pdxtest.out


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
context_yaml=${HOME}/wgs/hpc_submission/APS017_PDX_test_context_config.yaml
pipelinedir=${HOME}/wgs
mouse_refdir=/data1/shahs3/isabl_data_lake/assemblies/WGS-MM10/mouse
refdir=/data1/shahs3/reference/ref-sarcoma/GRCh38/v45
output_prefix=TCDO-SAR-034-PDX
########


cd /data1/shahs3/reference/ref-sarcoma/GRCh38/v45

singularity exec \
    -B /var/run/munge \
    -B /usr/lib64/libmunge.so.2 \
    -B /usr/lib64/libmunge.so.2.0.0 \
    -B /run/munge \
    -B /usr/bin/squeue \
    -B /usr/bin/scontrol \
    -B /usr/bin/sacct \
    -B /usr/bin/scancel \
    -B /usr/bin/sbatch \
    -B /usr/lib64/slurm \
    -B /etc/slurm \
    --bind /data1/shahs3 \
    ${sif_path} /bin/bash -c "\
    echo 'slurm:x:300:300::/opt/slurm/slurm:/bin/false' >> /etc/passwd && \
    bwa index GRCh38.primary_assembly.genome.fa"



