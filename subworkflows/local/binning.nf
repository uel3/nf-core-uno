// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { MAXBIN2                              } from '../../modules/nf-core/maxbin2/main'
include { METABAT2_METABAT2                    } from '../../modules/nf-core/metabat2/metabat2/main'
include { METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS } from '../../modules/nf-core/metabat2/jgisummarizebamcontigdepths/main'
include { CONVERT_DEPTHS                       } from '../../modules/local/convert_depths'
include { ADJUST_MAXBIN2_EXT                   } from '../../modules/local/adjust_maxbin2_ext'

workflow BINNING {

    take:
    // TODO nf-core: edit input (take) channels
    assemblies           // channel: [ val(meta), path(assembly), path(bams), path(bais) ]
    reads                // channel: [ val(meta), [ reads ] ]

    main:

    ch_versions = Channel.empty()

    // TODO nf-core: substitute modules here for the modules of your subworkflow

    ch_summarizedepth_input = assemblies
                                .map { meta, assembly, bams, bais ->
                                        def meta_new = meta.clone()
                                    [ meta_new, bams, bais ]
                                }

    METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS ( ch_summarizedepth_input )

    ch_metabat_depths = METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.depth
        .map { meta, depths ->
            def meta_new = meta.clone()
            meta_new['binner'] = 'MetaBAT2'

            [ meta_new, depths ]
        }

    ch_versions = ch_versions.mix(METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.versions.first())

    // combine depths back with assemblies
    ch_metabat2_input = assemblies
        .map { meta, assembly, bams, bais ->
            def meta_new = meta.clone()
            meta_new['binner'] = 'MetaBAT2'

            [ meta_new, assembly, bams, bais ]
        }
        .join( ch_metabat_depths, by: 0 )
        .map { meta, assembly, bams, bais, depths ->
            [ meta, assembly, depths ]
        }
    CONVERT_DEPTHS ( ch_metabat2_input )
        ch_maxbin2_input = CONVERT_DEPTHS.out.output
            .map { meta, assembly, reads, depth ->
                    def meta_new = meta.clone()
                    meta_new['binner'] = 'MaxBin2'

                [ meta_new, assembly, reads, depth ]
            }
        ch_versions = ch_versions.mix(CONVERT_DEPTHS.out.versions.first())
    // main bins for decompressing for MAG_DEPTHS
    ch_final_bins_for_gunzip = Channel.empty()
    // final gzipped bins
    ch_binning_results_gzipped_final = Channel.empty()
    // run binning
    METABAT2_METABAT2 ( ch_metabat2_input )
        // before decompressing first have to separate and re-group due to limitation of GUNZIP module
        ch_final_bins_for_gunzip = ch_final_bins_for_gunzip.mix( METABAT2_METABAT2.out.fasta.transpose() )
        ch_binning_results_gzipped_final = ch_binning_results_gzipped_final.mix( METABAT2_METABAT2.out.fasta )
        ch_versions = ch_versions.mix(METABAT2_METABAT2.out.versions.first())
    MAXBIN2 ( ch_maxbin2_input )
    ADJUST_MAXBIN2_EXT ( MAXBIN2.out.binned_fastas )
        ch_final_bins_for_gunzip = ch_final_bins_for_gunzip.mix( ADJUST_MAXBIN2_EXT.out.renamed_bins.transpose() )
        ch_binning_results_gzipped_final = ch_binning_results_gzipped_final.mix( ADJUST_MAXBIN2_EXT.out.renamed_bins )
        ch_versions = ch_versions.mix(MAXBIN2.out.versions)
    
    emit:
    // TODO nf-core: edit emitted channels
    bins                                         = ch_final_bins_for_gunzip
    bins_gz                                      = ch_binning_results_gzipped_final
    //unbinned                                     = ch_splitfasta_results_gunzipped.groupTuple()
    //unbinned_gz                                  = SPLIT_FASTA.out.unbinned
    //depths_summary                               = MAG_DEPTHS_SUMMARY.out.summary
    metabat2depths                               = METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.depth
    versions                                     = ch_versions
}

