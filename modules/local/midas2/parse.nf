process MIDAS2_PARSE {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::bioawk=1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioawk:1.0--hed695b0_5' :
        'biocontainers/bioawk:1.0--hed695b0_5' }"

    
    input:
    path midas2_metadata
    tuple val(meta), path(midas2_snps)
    

    output:
    tuple val(meta.id), path("${meta.id}_midas2_species_ID_mqc.tsv"), emit: snps_id_list
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    if [ -s "${midas2_snps}" ]; then
        awk -F'\\t' 'NR==FNR{a[\$1]=\$18 "\\t" \$19; next}
                     FNR==1{print "sample_name\\t" \$0 "\\tLineage\\tContinent"; next}
                     {print "${meta.id}\\t" \$0 "\\t" (a[\$1] ? a[\$1] : "NA\\tNA")}' ${midas2_metadata} ${midas2_snps} > ${prefix}_midas2_species_ID_mqc.tsv
    else
        echo -e "sample_name\\terror\\tLineage\\tContinent" > ${meta.id}_midas2_species_ID_mqc.tsv
        echo -e "${meta.id}\\tNo MIDAS2 SNPs results for ${meta.id}\\tNA\\tNA" >> ${meta.id}_midas2_species_ID_mqc.tsv
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | head -n1 | awk '{print \$3}')
    END_VERSIONS
    """
}    
