
// Pipeline Input parameters

publishDir = [
            path: { "${params.outdir}/MIDAS2" },
            mode: params.publish_dir_mode,
            saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
        ]
workflow {

    midasdb_uhgg_ch = MIDAS2_DB_BUILD ()
    midas2_species_ch = MIDAS2_SPECIES_SNPS( file(params.input) )
    MIDAS2_PARSE( midas2_species_ch.midas2_snps, midasdb_uhgg_ch.db_file )
    //may need to make these seperate--not sure yet

}
//needs to start here so I will need to format the above options elsewhere in my pipeline 
process MIDAS2_DB_BUILD {
    tag{"MIDAS2_DB_BUILD ughh_db"}
    label 'midas2'//changing this to point to midas_changed env in config

    conda "${moduleDir}/environment.yml"
    
    output:
    path( "my_midasdb_uhgg/*" ), emit: uhgg_db
    path( "my_midasdb_uhgg/metadata.tsv" ), emit: db_file

    script:
    """
    midas2 database --init --midasdb_name uhgg --midasdb_dir my_midasdb_uhgg
    """

    stub:
    """
    mkdir my_midasdb_uhgg
    touch my_midasdb_uhgg/stub
    touch my_midasdb_uhgg/metadata.tsv
    """
}
/*
 * MIDAS2 run species to get list of potential species in sample. 
 */
process MIDAS2_SPECIES_SNPS {
    //errorStrategy 'ignore'
    tag{"MIDAS2_SPECIES ${reads_trimmed}"}
    label 'midas2'

    conda 'midas2_environment.yml'

    input:
    tuple val(meta), path(reads)

    output:
    path( "midas2_output/${sample_id}/species/log.txt" )
    path( "midas2_output/${sample_id}/species/species_profile.tsv" ), emit: species_id
    path( "midas2_output/${sample_id}/temp/*" ), optional: true //adding the optional: true keeps nf from throwing error
    path( "midas2_output/${sample_id}/snps/log.txt" )
    path( "midas2_output/${sample_id}/snps/snps_summary.tsv"), emit: midas2_snps
    path( "midas2_output/${sample_id}/snps/*.snps.tsv.lz4" )
    path( "midas2_output/${sample_id}/bt2_indexes/snps/*" ), optional: true
   

    script: //getting an error that midas2 cannot find hs-blastn but it is in the midas_changes env located :/scicomp/home-pure/uel3/.conda/envs/midas_changed/bin/hs-blastn
    //need to include -profile conda when running the script to activate the correct environment $nextflow run MIDAS2.nf -profile conda sge
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    midas2 run_species \
      --sample_name ${sample_id} \
      -1 ${reads[0]} \
      -2 ${reads[1]} \
      --midasdb_name uhgg \
      --midasdb_dir my_midasdb_uhgg \
      --num_cores 8 \
      midas2_output
    midas2 run_snps \
      --sample_name ${sample_id} \
      -1 ${reads[0]} \
      -2 ${reads[1]} \
      --midasdb_name uhgg \
      --midasdb_dir my_midasdb_uhgg \
      --select_by median_marker_coverage,unique_fraction_covered \
      --select_threshold=2,0.5 \
      --num_cores 8 \
      midas2_output
    """

    stub:
    """
    mkdir midas2_output
    mkdir midas2_output/${sample_id}
    mkdir midas2_output/${sample_id}/species
    touch midas2_output/${sample_id}/species/log.txt
    touch midas2_output/${sample_id}/species/species_profile.tsv
    mkdir midas2_output/${sample_id}/temp
    touch midas2_output/${sample_id}/temp/stub
    mkdir midas2_output/${sample_id}/bt2_indexes
    mkdir midas2_output/${sample_id}/bt2_indexes/snps
    touch midas2_output/${sample_id}/bt2_indexes/snps/stub
    mkdir midas2_output/${sample_id}/snps
    touch midas2_output/${sample_id}/snps/log.txt
    touch midas2_output/${sample_id}/snps/snps_summary.tsv
    touch midas2_output/${Sample_id}/snps/stub.snps.tsv.lz4
    """
    // a run through of this process resulted in a command error that stopped the process-this output was '[ScoreBlkKbpUngappedCalc] Warning: Could not calculate ungapped Karlin-Altschul parameters due to an invalid query sequence. Please verify the query sequence(s) and/or filtering options.' 
    //this type of error should not stop the process going to add an ignore error statement to see if it will work even with the warning 
    //adding the ignore statement allows the process to run but I am not getting the correct output-required me to restructure my outputs-since the outdir is called in the script, I needed to remove it from my publishDir call but also include it expected output
    
}
/*
 * Parse MIDAS2 output to get readable list of potential species in sample. 
 */
process MIDAS2_PARSE {
    tag{"MIDAS2_PARSE ${midas2_snps_id}"} //need to include variables for species and snps MIDAS2 outputs

    publishDir("${params.outdir}/MIDAS2/midas2_output", mode: 'copy') 

    input:
    path ( midas2_snps_id )
    path ( midas2_metadata )

    output:
    path( "midas2_species_ID.txt" ), emit: snps_id_list

    shell:
    """
    awk 'NR==FNR{a[\$1]=\$0;next}\$1 in a{print a[\$1], \$18, \$19}' ${midas2_snps_id} ${midas2_metadata} > midas2_species_ID.txt
    """
    
    stub:
    """
    mkdir midas2_ouptut/${sample.id}
    mkdir midas2_ouptut/${sample.id}/midas2_species_ID.txt
    """
}
/*
========================================================================================
   Workflow Event Handler
========================================================================================
*/

workflow.onComplete {

   println ( workflow.success ? """
       Pipeline execution summary
       ---------------------------
       Completed at: ${workflow.complete}
       Duration    : ${workflow.duration}
       Success     : ${workflow.success}
       workDir     : ${workflow.workDir}
       exit status : ${workflow.exitStatus}
       """ : """
       Failed: ${workflow.errorReport}
       exit status : ${workflow.exitStatus}
       """
   )
}
/*
========================================================================================
   THE END
========================================================================================
*/

