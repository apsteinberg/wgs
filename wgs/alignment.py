import os
import sys

import pypeliner
import pypeliner.managed as mgd
from wgs.utils import helpers
from wgs.workflows import alignment


def alignment_workflow(args):
    inputs = helpers.load_yaml(args['input_yaml'])

    meta_yaml = os.path.join(args['out_dir'], 'metadata.yaml')
    input_yaml_blob = os.path.join(args['out_dir'], 'input.yaml')

    outputs = args['output_prefix'] + 'aligned.bam'
    out_bai = outputs + '.bai'
    outputs_tdf = args['output_prefix'] + 'aligned.bam.tdf'
    metrics_output = args['output_prefix'] + 'aligned_metrics.csv'
    metrics_tar = args['output_prefix'] + 'aligned_metrics.tar.gz'

    fastqs_r1, fastqs_r2 = helpers.get_fastqs(inputs)

    sample_info = inputs['readgroup_info']
    sample_id = sample_info['SM']

    pyp = pypeliner.app.Pypeline(config=args)
    workflow = pypeliner.workflow.Workflow()

    workflow.setobj(
        obj=mgd.OutputChunks('lane_id'),
        value=list(fastqs_r1.keys()),
    )

    # workflow.subworkflow(
    #     name="align_samples",
    #     func=alignment.align_samples,
    #     args=(
    #         mgd.InputFile('input.r1.fastq.gz', 'lane_id', fnames=fastqs_r1),
    #         mgd.InputFile('input.r2.fastq.gz', 'lane_id', fnames=fastqs_r2),
    #         mgd.Template(outputs),
    #         mgd.Template(metrics_output),
    #         mgd.Template(metrics_tar),
    #         mgd.Template(outputs_tdf),
    #         sample_info,
    #         args['refdir'],
    #         sample_id
    #     ),
    #     kwargs={'single_node': args['single_node'],
    #             'picard_mem': args['picard_mem']}
    # )
    ## if we have a PDX sample ...
    if args["PDX"]:
        ## align to human
        workflow.subworkflow(
            name="align_to_human",
            func=alignment.align_samples,
            args=(
                mgd.InputFile('input.r1.fastq.gz', 'lane_id', fnames=fastqs_r1),
                mgd.InputFile('input.r2.fastq.gz', 'lane_id', fnames=fastqs_r2),
                mgd.OutputFile(args['output_prefix'] + 'human_aligned.bam'),
                mgd.OutputFile(metrics_output),
                mgd.OutputFile(metrics_tar),
                mgd.OutputFile(outputs_tdf),
                sample_info,
                args['refdir'],
                sample_id
            ),
            kwargs={'single_node': args['single_node'],
                    'picard_mem': args['picard_mem']}
        )
        ## align to mouse genome
        workflow.subworkflow(
            name="align_to_mouse",
            func=alignment.align_samples,
            args=(
                mgd.InputFile('input.r1.fastq.gz', 'lane_id', fnames=fastqs_r1),
                mgd.InputFile('input.r2.fastq.gz', 'lane_id', fnames=fastqs_r2),
                mgd.OutputFile(args['output_prefix'] + 'mouse_aligned.bam'),
                mgd.OutputFile(args['output_prefix'] + 'mouse_aligned_metrics.csv'),
                mgd.OutputFile(args['output_prefix'] + 'mouse_aligned_metrics.tar.gz'),
                mgd.OutputFile(args['output_prefix'] + 'mouse_aligned.bam.tdf'),
                sample_info,
                args['mouse_refdir'],
                sample_id
            ),
            kwargs={'single_node': args['single_node'],
                    'picard_mem': args['picard_mem']}
        )

        ## run disambiguate
        workflow.transform(
            name="disambiguate",
            ctx=helpers.get_default_ctx(
                memory=80,
                walltime='48:00',
                ncpus='2',
                disk=300
            ),
            func=alignment.disambiguate,
            args=(
                args["output_prefix"],
                mgd.InputFile(args['output_prefix'] + 'human_aligned.bam'),
                mgd.InputFile(args['output_prefix'] + 'mouse_aligned.bam'),
                mgd.TempOutputFile(args['output_prefix'] + ".disambiguatedSpeciesA.bam")
            ),
        )

        ## sort the disambiguated output
        workflow.transform(
            name='sort',
            ctx=helpers.get_default_ctx(
                memory=8,
                walltime='48:00',
                ncpus='8',
                disk=300
            ),
            func='wgs.workflows.alignment.tasks.bam_sort',
            args=(
                mgd.InputFile(args['output_prefix'] + ".disambiguatedSpeciesA.bam"),
                mgd.OutputFile(outputs),
                mgd.TempSpace('bam_sort_tempdir')
            ),
            kwargs={
                'threads': '8',
                'mem': '{}G'.format(8)
            }
        )

        ## index and flagstats disambiguated reads
        workflow.commandline(
            name='index',
            ctx=helpers.get_default_ctx(
                memory=4,
                walltime='16:00',
            ),
            args=(
                'samtools',
                'index',
                mgd.InputFile(outputs),
                mgd.OutputFile(out_bai)
            ),
        )

    else:
        workflow.subworkflow(
            name="align_samples",
            func=alignment.align_samples,
            args=(
                mgd.InputFile('input.r1.fastq.gz', 'lane_id', fnames=fastqs_r1),
                mgd.InputFile('input.r2.fastq.gz', 'lane_id', fnames=fastqs_r2),
                mgd.Template(outputs),
                mgd.Template(metrics_output),
                mgd.Template(metrics_tar),
                mgd.Template(outputs_tdf),
                sample_info,
                args['refdir'],
                sample_id
            ),
            kwargs={'single_node': args['single_node'],
                    'picard_mem': args['picard_mem']}
        )

    outputted_filenames = [
        outputs,
        outputs_tdf,
        metrics_output,
        metrics_tar,

    ]

    workflow.transform(
        name='generate_meta_files_results',
        func='wgs.utils.helpers.generate_and_upload_metadata',
        args=(
            sys.argv[0:],
            args['out_dir'],
            outputted_filenames,
            mgd.OutputFile(meta_yaml)
        ),
        kwargs={
            'input_yaml_data': inputs,
            'input_yaml': mgd.OutputFile(input_yaml_blob),
            'metadata': {'type': 'alignment'}
        }
    )

    pyp.run(workflow)
