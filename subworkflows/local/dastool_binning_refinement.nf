// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { DASTOOL_FASTATOCONTIG2BIN as DASTOOL_FASTATOCONTIG2BIN_METABAT2     } from '../../modules/nf-core/dastool/fastatocontig2bin/main'
include { DASTOOL_FASTATOCONTIG2BIN as DASTOOL_FASTATOCONTIG2BIN_MAXBIN2      } from '../../modules/nf-core/dastool/fastatocontig2bin/main'
include { DASTOOL_DASTOOL                                                     } from '../../modules/nf-core/dastool/dastool/main'
include { RENAME_PREDASTOOL                                                   } from '../../modules/local/rename_predastool'
include { RENAME_POSTDASTOOL                                                  } from '../../modules/local/rename_postdastool'

workflow DASTOOL_BINNING_REFINEMENT {

    take:
    
    ch_contigs_for_dastool // channel: [ val(meta), path(contigs) ]
    bins // channel: [val(meta), path(bins)]

    main:

    ch_versions = Channel.empty()

    // TODO nf-core: substitute modules here for the modules of your subworkflow
    ch_bins = bins
        .map { meta, bins ->
            def meta_new = meta - meta.subMap(['refinement'])
            [meta_new, bins]
        }
        .groupTuple()
        .map {
            meta, bins -> [meta, bins.flatten()]
        }
    // prepare bins for fastatocontig2bin, change ext to fa for all bins
    ch_bins_for_fastatocontig2bin = RENAME_PREDASTOOL(ch_bins).renamed_bins
                                        .branch {
                                            metabat2: it[0]['binner'] == 'MetaBAT2'
                                            maxbin2:  it[0]['binner'] == 'MaxBin2'
                                        }
    // Generate contig2bin files for DASTool input
    DASTOOL_FASTATOCONTIG2BIN_METABAT2 ( ch_bins_for_fastatocontig2bin.metabat2, "fa")
    DASTOOL_FASTATOCONTIG2BIN_MAXBIN2 ( ch_bins_for_fastatocontig2bin.maxbin2, "fa")

    // format channels for DasTool remove previous binner and group fastacontig2bin files
    ch_fastatocontig2bin_for_dastool = Channel.empty()
    ch_fastatocontig2bin_for_dastool = ch_fastatocontig2bin_for_dastool
                                    .mix(DASTOOL_FASTATOCONTIG2BIN_METABAT2.out.fastatocontig2bin)
                                    .mix(DASTOOL_FASTATOCONTIG2BIN_MAXBIN2.out.fastatocontig2bin)
                                    .map {
                                        meta, fastatocontig2bin ->
                                            def meta_new = meta - meta.subMap('binner')
                                            [ meta_new, fastatocontig2bin ]
                                    }
                                    .groupTuple(by: 0)
    ch_input_for_dastool = ch_contigs_for_dastool.join(ch_fastatocontig2bin_for_dastool, by: 0)

    ch_versions = ch_versions.mix(DASTOOL_FASTATOCONTIG2BIN_METABAT2.out.versions.first())
    ch_versions = ch_versions.mix(DASTOOL_FASTATOCONTIG2BIN_MAXBIN2.out.versions.first())
    
    // Run DAStool
    DASTOOL_DASTOOL(ch_input_for_dastool, [], [])
    ch_versions = ch_versions.mix(DASTOOL_DASTOOL.out.versions.first())
    
    ch_dastool_bins_newmeta = DASTOOL_DASTOOL.out.bins.transpose()
        .map {
            meta, bin ->
                if (bin.name != "unbinned.fa") {
                    def meta_new = meta + [binner: 'DASTool']
                    [ meta_new, bin ]
                }
            }
        .groupTuple()
        .map {
            meta, bins ->
                def meta_new = meta + [refinement: 'dastool_refined']
                [ meta_new, bins ]
            }
    ch_input_for_renamedastool = DASTOOL_DASTOOL.out.bins
        .map {
            meta, bins ->
                def meta_new = meta + [refinement: 'dastool_refined', binner: 'DASTool']
                [ meta_new, bins ]
            }
    RENAME_POSTDASTOOL ( ch_input_for_renamedastool )

    refined_unbins = RENAME_POSTDASTOOL.out.refined_unbins
        .map {
            meta, bins ->
                def meta_new = meta + [refinement: 'dastool_refined_unbinned']
                [meta_new, bins]
        }

    emit:
    refined_bins                = ch_dastool_bins_newmeta
    refined_unbins              = refined_unbins
    versions                    = ch_versions
}

