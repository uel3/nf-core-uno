#!/usr/bin/env python3

import pandas as pd
import yaml
import argparse

def combine_midas2_reports(input_files, output_file):
    # Read all MIDAS2 report files
    df_list = []
    for file in input_files:
        df = pd.read_csv(file, sep='\t')
        df_list.append(df)
    
    # Combine all dataframes
    combined_df = pd.concat(df_list, ignore_index=True)

    # Create a unique identifier combining sample_name and species_id
    combined_df['unique_id'] = combined_df['sample_name'].astype(str) + '_' + combined_df['species_id'].astype(str)

    # Create headers dictionary
    headers = {
        'sample_name': {'title': 'Sample'},
        'species_id': {'title': 'Species ID'},
        'genome_length': {'title': 'Genome Length'},
        'covered_bases': {'title': 'Covered Bases'},
        'total_depth': {'title': 'Total Depth'},
        'aligned_reads': {'title': 'Aligned Reads'},
        'mapped_reads': {'title': 'Mapped Reads'},
        'fraction_covered': {'title': 'Fraction Covered'},
        'mean_coverage': {'title': 'Mean Coverage'},
        'Lineage': {'title': 'Lineage'},
        'Continent': {'title': 'Continent'}
    }

    # Convert the DataFrame to the required format
    data_yaml = combined_df.set_index('unique_id').to_dict(orient='index')

    # Create the full YAML dictionary
    yaml_dict = {
        'id': 'midas2_species_abundance',
        'section_name': 'MIDAS2 Species Abundance',
        'description': 'MIDAS2 species abundance results for all samples',
        'plot_type': 'table',
        'pconfig': {
            'id': 'midas2_species_abundance',
            'title': 'MIDAS2 Species Abundance'
        },
        'headers': headers,
        'data': data_yaml
    }

    # Write to a YAML file
    with open(output_file, 'w') as file:
        yaml.dump(yaml_dict, file, sort_keys=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Combine MIDAS2 reports for MultiQC')
    parser.add_argument('-i', '--input', nargs='+', required=True, help='Input MIDAS2 report files')
    parser.add_argument('-y', '--yaml', required=True, help='Output YAML file for MultiQC')
    
    args = parser.parse_args()
    
    combine_midas2_reports(args.input, args.yaml)