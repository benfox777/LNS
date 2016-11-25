#!/bin/bash

RUN_PATH=$1
LOG_PATH=$RUN_PATH/out/log

OUT_PATH=$RUN_PATH/out/fastq_tmp
#DEMUX_PATH=$RUN_PATH/out/fastq_tmp/demultiplex

echo $RUN_PATH
echo "Create paths"
mkdir -p $OUT_PATH
mkdir -p $LOG_PATH

echo "Create log file"
LOG_FILE=$LOG_PATH/bclToFastq.log
touch $LOG_FILE

echo "Generate fastq-file from bcl-files"
echo "Generate fastq-file from bcl-files" > $LOG_FILE
date >> $LOG_FILE
echo "" >> $LOG_FILE

echo "bcl2fastq output:" >> $LOG_FILE
#bcl error:  --ignore-missing-bcls

#bcl2fastq -i $RUN_PATH/Data/Intensities/BaseCalls -o $OUT_PATH -R $RUN_PATH -r 10 -w 10 -d 10 -p 14 --create-fastq-for-index-reads --barcode-mismatches 1 --ignore-missing-bcls
#bcl2fastq --runfolder-dir $RUN_PATH -p 12 --output-dir $OUT_PATH --no-lane-splitting
#bcl2fastq --output-dir $OUT_PATH --runfolder-dir $RUN_PATH -r 10 -w 10 -d 10 -p 14 --create-fastq-for-index-reads --barcode-mismatches 1 --ignore-missing-bcls --use-bases-mask Y75,I8,Y75
bcl2fastq --output-dir $OUT_PATH --runfolder-dir $RUN_PATH -r 10 -w 10 -d 10 -p 14 --create-fastq-for-index-reads --barcode-mismatches 1 --ignore-missing-bcls --use-bases-mask Y151,I6,I8,Y151
