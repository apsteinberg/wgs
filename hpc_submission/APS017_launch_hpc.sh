#!/bin/bash
#SBATCH --partition=componc_cpu,componc_gpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=20:00:00
#SBATCH --mem=8GB
#SBATCH --job-name=wgs
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
sif_path=/data1/shahs3/users/preskaa/singularity/wgs_alignment_0531_test.sif
input_yaml=${HOME}/wgs/hpc_submission/APS017_PDX_test_inputs.yaml
context_yaml=${HOME}/wgs/hpc_submission/APS017_PDX_test_context_config.yaml
pipelinedir=${HOME}/wgs
mouse_refdir=/data1/shahs3/isabl_data_lake/assemblies/WGS-MM10/mouse
refdir=/data1/shahs3/reference/ref-sarcoma/GRCh38/v45
output_prefix=${test_outdir}/TCDO-SAR-034-PDX
########
mkdir -p ${test_outdir}
cd ${test_outdir}


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
    pip install ${pipelinedir}/. && \
    export PATH=\"\$HOME/.local/bin:\$PATH\" && \
    wgs alignment \
        --input_yaml ${input_yaml} \
        --output_prefix ${output_prefix} \
        --loglevel DEBUG \
        --submit slurm \
        --context_config ${context_yaml} \
        --maxjobs 1000 \
        --nativespec ' -p componc_cpu -N 1 -n {ncpus} --mem={mem}G -t {walltime} ' \
        --refdir ${refdir} \
        --nocleanup \
        --picard_mem 18 \
        --PDX \
        --mouse_refdir ${mouse_refdir}"



