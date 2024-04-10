include { MIDAS2_RUN_SPECIES } from '../../modules/local/midas2/midas2runspecies'
include { MIDAS2_RUN_SNPS    } from '../../modules/local/midas2/midas2runsnps'

workflow MIDAS2_SPECIES_SNPS_PARSE {

	take:
	reads                // channel: [ val(meta), [ reads ] ]
	
	main:
	MIDAS2_RUN_SPECIES(reads)
	
	MIDAS2_RUN_SNPS(MIDAS2_RUN_SPECIES.out, reads)

	
	emit:
	midas2_species_log          = MIDAS2_RUN_SPECIES.out.species_log
    midas2_species_id           = MIDAS2_RUN_SPECIES.out.species_id
	midas2_snps_log             = MIDAS2_RUN_SNPS.out.snps_log
    midas2_snps                 = MIDAS2_RUN_SNPS.out.midas2_snps
	midas2_pileup               = MIDAS2_RUN_SNPS.out.per_species_pileup
	midas2_species_snps_version = MIDAS2_RUN_SNPS.out.versions
}
	
