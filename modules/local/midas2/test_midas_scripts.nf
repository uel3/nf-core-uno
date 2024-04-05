#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
println "Starting the workflow..."
include { MIDAS2_DB_BUILD } from './builddb.nf'

workflow test_midas_scripts {
    MIDAS2_DB_BUILD()
}
