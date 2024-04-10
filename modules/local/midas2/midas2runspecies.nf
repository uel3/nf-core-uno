process MIDAS2_RUN_SPECIES {
    //errorStrategy 'ignore'
    publishDir "${params.outdir}/midas2_output", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'

    conda {
        name = 'midas2'
        file = '/scicomp/home-pure/uel3/UnO_nf/nf-core-uno/modules/local/midas2/environment.yml'
    }

    input:
    tuple val(meta), path(reads)

    output:
    path( "midas2_output/${meta.id}/species/log.txt" ), emit: species_log
    path( "midas2_output/${meta.id}/species/species_profile.tsv" ), emit: species_id
    //path( "midas2_output/${meta.id}/temp/*" ), optional: true //adding the optional: true keeps nf from throwing error
       

    script: //getting an error that midas2 cannot find hs-blastn but it is in the midas_changes env located :/scicomp/home-pure/uel3/.conda/envs/midas_changed/bin/hs-blastn
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def midas2_dbname = "--midasdb_name uhgg"
    def midas2_dbdir = "--midasdb_dir my_midasdb_uhgg"
    def outdir = "midas2_output"
    """
    midas2 run_species \
      $outdir \
      --sample_name $prefix \
      -1 ${reads[0]} \
      -2 ${reads[1]} \
      $midas2_dbname \
      $midas2_dbdir \
      --num_cores $task.cpus
      """

    stub:
    """
    mkdir midas2_output
    mkdir midas2_output/${meta.id}
    mkdir midas2_output/${meta.id}/species
    touch midas2_output/${meta.id}/species/log.txt
    touch midas2_output/${meta.id}/species/species_profile.tsv
    """
}