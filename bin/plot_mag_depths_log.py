#!/usr/bin/env python

import sys
import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

def parse_args(args=None):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--depths",
        required=True,
        metavar="FILE",
        help="Combined TSV file containing bin depths for all assemblies, binning methods and samples.",
    )
    parser.add_argument(
        "--groups",
        required=True,
        metavar="FILE",
        help="File in TSV format containing group information for samples: sample, group",
    )
    parser.add_argument(
        "--out", required=True, metavar="FILE", type=str, help="Output file name for the heatmap."
    )
    return parser.parse_args(args)

def main(args=None):
    args = parse_args(args)

    # Load data
    df = pd.read_csv(args.depths, sep="\t", index_col=0)
    groups = pd.read_csv(args.groups, sep="\t", index_col=0, names=["sample", "group"])

    # Log transform the data, adding a small value to handle zeros
    small_value = 1e-6  # can be change for data scale
    df_log = np.log10(df + small_value)

    # Prepare colors for group information
    color_map = dict(zip(groups["group"].unique(), sns.color_palette(n_colors=len(groups["group"].unique()))))

    # Plot heatmap
    plt.figure(figsize=(12, 10))
    bin_labels = True if len(df) <= 30 else False
    g = sns.clustermap(
        df_log,
        row_cluster=True,
        yticklabels=bin_labels,
        cmap="vlag",
        center=0,
        col_colors=groups.group.map(color_map),
        figsize=(6,6)
    )
    g.ax_heatmap.set_xlabel("Samples")
    g.ax_heatmap.set_ylabel("MAGs")
    plt.savefig(args.out)
    plt.close()

if __name__ == "__main__":
    sys.exit(main())