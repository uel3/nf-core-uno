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
    tuple val(meta.id), path("${meta.id}_midas2_species_ID_mcq.tsv"), emit: snps_id_list
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    if [ -s "${midas2_snps}" ]; then
        awk -F'\\t' 'NR==FNR{a[\$1]=\$0; next} \$1 in a{print "${meta.id}", a[\$1], \$18, \$19}' ${midas2_snps} ${midas2_metadata} > ${prefix}_midas2_species_ID_mcq.tsv
    else
        echo "No MIDAS2 SNPs results for ${meta.id}" > ${meta.id}_midas2_species_ID_mcq.tsv
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | head -n1 | awk '{print \$3}')
    END_VERSIONS
    """
}    
