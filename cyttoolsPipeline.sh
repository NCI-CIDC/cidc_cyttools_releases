#!/bin/bash

# Usage: Update/confirm SOURCE_DATA, CYTTOOLS_LOCATION, FCS_DIR, PANEL, METADATA, RESULTS_BLANKS, and RESULTS_CLUSTERING
# ./cyttoolsPipeline.sh <BATCH SIZE FOR PROCESS>  &> /media/analysis/output_Ub24/pipeline.log
# Example: ./cyttoolsPipeline.sh 5 &> /media/analysis/output_Ub24/pipeline.log

# Fill in the varibles below with the locations of your various files
SOURCE_DATA="gs://" #Location of data on portal
CYTTOOLS_LOCATION="/home/pipeline/cyttools/" #Location of cyttools code
FCS_DIR="/media/analysis/input_data_Ub24/" #Local location of source data
BATCH_SIZE=$1  #Size of batches used for FlowSOM processing and post-processing
PANEL="/media/analysis/results_blank_Ub24/panelFile.txt" #Local location to store dataset panel
METADATA="/media/analysis/results_blank_Ub24/MetaDataFile.txt" #Local location to store dataset metadata
RESULTS_BLANKS="/media/analysis/results_blank_Ub24/" #Local location to store Rdata object
RESULTS_CLUSTERING="/media/analysis/output_Ub24/clustering/" #Local location to store pipeline output

# Clean up previous runs
rm -r /media/analysis/input_data_Ub24/*
rm /media/analysis/results_blank_Ub24/*
rm -r /media/analysis/output_Ub24/clustering/*

# Pull in SOURCE_DATA
gcloud storage cp "$SOURCE_DATA" "$FCS_DIR"

cd $CYTTOOLS_LOCATION

# if needed, generate panel and meta data files. DO THIS BEFORE YOU RUN THE MAIN ANALYSIS SCRIPT (EG FLOWSOM)!
Rscript cyttools.R --makePanelBlank "$FCS_DIR" "$RESULTS_BLANKS"
Rscript cyttools.R --makeMetaDataBlank "$FCS_DIR" "$RESULTS_BLANKS"

# Get a list of files in the main directory and calculate the number of subdirectories (ie batches)
FILES=("$FCS_DIR"/*)
FILE_COUNT=${#FILES[@]}
NUM_SUBDIRS=$(( (FILE_COUNT + BATCH_SIZE - 1) / BATCH_SIZE ))

# Subdivide Input Data into smaller batches
source divide_input_data.sh "$BATCH_SIZE" "$FCS_DIR" 

# perform clustering analysis on batches, WARNING FlowSOM takes a long time to run and will eat up most of your memory
for ((i=0; i<$NUM_SUBDIRS; i++)); do
    Rscript cyttools.R --cluster=FlowSOM "$FCS_DIR/subdir_$i" "$PANEL" "$RESULTS_CLUSTERING"
done
