//needs to start here so I will need to format the above options elsewhere in my pipeline 
process MIDAS2_DB_BUILD {
    //tag "$meta.id"
    label 'process_medium'

    conda {
        name = 'midas2'
        file = '/scicomp/home-pure/uel3/UnO_nf/nf-core-uno/modules/local/midas2/environment.yml'
    }
    //input:
    //val midasdb_name
    //val midasdb_dir

    output:
    path("my_midasdb_uhgg"), emit: midasdb
    path("my_midasdb_uhgg/metadata.tsv"), emit: metadata
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: '' //this may need to be put in the modules.config file, going to test as is for now then try the config file 
    def midas2_dbname = "--midasdb_name uhgg"
    def midas2_dbdir = "--midasdb_dir my_midasdb_uhgg"
    """
    midas2 database --init $midas2_dbname $midas2_dbdir

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        midas2: \$(echo \$(midas2 --version 2>&1) | sed 's/midas2 //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    mkdir my_midasdb_uhgg
    touch my_midasdb_uhgg/stub
    touch my_midasdb_uhgg/metadata.tsv
    """
}