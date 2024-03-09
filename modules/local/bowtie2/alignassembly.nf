// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/modules/nf-core/
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process BOWTIE2_ALIGNASSEMBLY {
    tag "${assembly_meta.assembler}-${assembly_meta.id}-${reads_meta.id}"

    conda "bioconda::bowtie2=2.4.2 bioconda::samtools=1.11 conda-forge::pigz=2.3.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:577a697be67b5ae9b16f637fd723b8263a3898b3-0' :
        'biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:577a697be67b5ae9b16f637fd723b8263a3898b3-0' }"

    input:
    tuple val(assembly_meta), path(assembly), path(index), val(reads_meta), path(reads)

    output:
    tuple val(assembly_meta), path(assembly), path("${assembly_meta.assembler}-${assembly_meta.id}-${reads_meta.id}.bam"), path("${assembly_meta.assembler}-${assembly_meta.id}-${reads_meta.id}.bam.bai"), emit: mappings
    tuple val(assembly_meta), val(reads_meta), path("*.bowtie2.log")                                                                                                                                      , emit: log
    path "versions.yml"                                                                                                                                                                                   , emit: versions

    script:
    def args = task.ext.args ?: ''
    def name = "${assembly_meta.assembler}-${assembly_meta.id}-${reads_meta.id}"
    def input = "-1 \"${reads[0]}\" -2 \"${reads[1]}\""
    """
    INDEX=`find -L ./ -name "*.rev.1.bt2l" -o -name "*.rev.1.bt2" | sed 's/.rev.1.bt2l//' | sed 's/.rev.1.bt2//'`
    bowtie2 \\
        -p "${task.cpus}" \\
        -x \$INDEX \\
        $input \\
        2> "${name}.bowtie2.log" | \
        samtools view -@ "${task.cpus}" -bS | \
        samtools sort -@ "${task.cpus}" -o "${name}.bam"
    samtools index "${name}.bam"

    if [ ${name} = "${assembly_meta.assembler}-${assembly_meta.id}-${assembly_meta.id}" ] ; then
        mv "${name}.bowtie2.log" "${assembly_meta.assembler}-${assembly_meta.id}.bowtie2.log"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
    END_VERSIONS
    """
}
