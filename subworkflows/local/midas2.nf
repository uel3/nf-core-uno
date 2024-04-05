include { MIDAS2_DB_BUILD } from '../../modules/local/midas2/builddb'

workflow MIDAS2 {

    take:
    //assemblies           // channel: [ val(meta), path(assembly) ]
    //reads                // channel: [ val(meta), [ reads ] ]

    main:
    // download the uhgg database 
    MIDAS2_DB_BUILD( 
    )
        
    emit:
    // TODO nf-core: edit emitted channels
    midas2_db = MIDAS2_DB_BUILD.out.midasdb
    midas2_db_metadata = MIDAS2_DB_BUILD.out.metadata
    midas2_db_version = MIDAS2_DB_BUILD.out.versions
}