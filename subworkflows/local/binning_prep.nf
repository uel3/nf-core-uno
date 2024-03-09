// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { BOWTIE2_BUILDASSEMBLYINDEX } from '../../modules/local/bowtie2/buildassemblyindex'
include { BOWTIE2_ALIGNASSEMBLY      } from '../../modules/local/bowtie2/alignassembly'

workflow BINNING_PREP {

    take:
    assemblies           // channel: [ val(meta), path(assembly) ]
    reads                // channel: [ val(meta), [ reads ] ]

    main:
    // build bowtie2 index from coassembly of all reads using group 
    BOWTIE2_BUILDASSEMBLYINDEX (assemblies)
        ch_reads_bowtie2 = reads.map{ meta, reads -> [ meta.group, meta, reads] }
        ch_bowtie2_input = BOWTIE2_BUILDASSEMBLYINDEX.out.bt2_index
            .map {meta, assembly, index -> [meta.group, meta, assembly, index ] }
            .combine(ch_reads_bowtie2, by:0)
            .map {group, assembly_meta, assembly, index, reads_meta, reads -> [assembly_meta, assembly, index, reads_meta, reads ]}
    
    BOWTIE2_ALIGNASSEMBLY (ch_bowtie2_input)
    ch_grouped_mappings = BOWTIE2_ALIGNASSEMBLY.out.mappings
        .groupTuple(by:0)
        .map {meta, assembly, bams, bais -> [meta, assembly.sort()[0], bams, bais ] }

    emit:
    // TODO nf-core: edit emitted channels
    bowtie2_assembly_multiqc = BOWTIE2_ALIGNASSEMBLY.out.log.map { assembly_meta, reads_meta, log -> [ log ] }
    bowtie2_version          = BOWTIE2_ALIGNASSEMBLY.out.versions
    grouped_mappings         = ch_grouped_mappings
}