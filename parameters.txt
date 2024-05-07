##parameters for current UnO pipeline
MIDAS2 default settings
MIDAS2 is set to run by default by skip_midas2 = false

midas2_run_snps uses the following threshold by default
midas2_snps_select_by = 'median_marker_coverage,unique_fraction_covered'
midas2_median_marker_coverage  = '2'
midas2_unique_fraction_covered = '0.5'

Trimmomatic adapter sequence is available in assets folder due to issue with Trimmomatic not finding TruSeq3 adapters in module 
adapter_seqeunce = "${projectDir}/assets/TruSeq3-PE.fa"
qual_trim = 20:30:10:8:True LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
method = PE

Host removal default setting is null-host removal will not happen by default, providing --host_genome 'GRCh38' will initiate host removal process
host_genome = null

Assembly default settings are set for co-assembly
coassemble_group                     = true
MEGAHIT memory settings are set to use 0.9 of max memory to avoid timing out during coassembly, max memory is set in to 128GB in nextflow.config
withName: MEGAHIT {
    memory        = { params.max_memory }}


Binning default settings are to map reads to coassembly based on group information provided in input samplesheet.csv, post binning analyses will be performed on refined bins only
binning_map_mode                     = 'group'
postbinning_input                    = 'refined_bins_only' 