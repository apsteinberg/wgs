#!/bin/bash

## specify path to out directory
outdir=/Users/preskaa/PycharmProjects/wgs/alignment_test
test_outdir=${outdir}/wgs_test
## make tmp dir
###
input_yaml=/Users/preskaa/PycharmProjects/wgs/hpc_submission/APS017_local_inputs.yaml
mouse_refdir=${outdir}/reference/mouse
refdir=${outdir}/reference/human
output_prefix=TCDO-SAR-034-PDX
context_config=/Users/preskaa/PycharmProjects/wgs/hpc_submission/APS017_local_context.yaml
########
wgs alignment \
    --input_yaml ${input_yaml} \
    --output_prefix ${test_outdir} \
    --loglevel DEBUG \
    --refdir ${refdir}\
    --submit local \
    --sentinel_only \
    --nocleanup \
    --picard_mem 18 \
    --context_config ${context_config} \
    --PDX \
    --mouse_refdir ${mouse_refdir}



