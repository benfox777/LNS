#!/bin/bash

CONFIG_FILE=$1
source $CONFIG_FILE
echo $SERVER_NGS_PATH

RUN_ID=$2
#RUN_DATE=$3
RUN_NAME=$3 #$(ls $SERVER_NGS_PATH | grep $RUN_DATE)
TRIMMER_LEFT=$4
TRIMMER_RIGHT=$5

#local path for processing
RUN_PATH=$LOCAL_NGS_PATH/$RUN_NAME
echo $RUN_PATH
echo

FILE_PATH=$RUN_PATH/out
FASTQ_PATH=$FILE_PATH/fastq_tmp
FASTQ_DEMUX=$FILE_PATH/fastq
BAM_PATH=$FILE_PATH/bam
LOG_PATH=$FILE_PATH/log
VAR_PATH=$FILE_PATH/var
SPECIAL_POS_PATH=$FILE_PATH/special_pos
#SAMPLE_FILE=$RUN_PATH/Samples.txt
#TUMOR_BLOOD_FILE=$RUN_PATH/TumorBlood.csv
PLATYPUS_VAR=$FILE_PATH/var_platypus
#CNV_PATH=$FILE_PATH/cnv
#
#MAPPING=""
#SAMPLES=""

echo "RUN Agilent paired end with BWA mem"

echo "Lib: $RUN_ID"
echo "Run-Name: $RUN_NAME"
date
echo
echo "COPY"
echo
mkdir -p $LOCAL_NGS_PATH/$RUN_ID

#SAMPLE_COUNT=$(wc -l $SAMPLE_FILE)
echo $SAMPLE_COUNT

#COPY to local workstation
#time cp -rf $SERVER_NGS_PATH/$RUN_NAME $LOCAL_NGS_PATH

#Create output directories in the local run copy
mkdir -p $FASTQ_DEMUX
mkdir -p $FASTQ_PATH
mkdir -p $LOG_PATH
mkdir -p $BAM_PATH

#Generate FASTQ files
echo "Convert Bcl To Fastq"
bash $SCRIPT_PATH/bcl/convertBclToFastq.sh $RUN_PATH
#wait

mv $FASTQ_PATH/* $FASTQ_DEMUX/

#Trim low-quality bases from FASTQ reads
echo "TRIMMER"
find $FASTQ_DEMUX -name "*R1*.fastq.gz" | grep -v I1 | grep -v Undetermined | grep -v trimmed | sort | parallel -P$DNA_PARALLEL_ALIGNMENT -n1 bash $SCRIPT_PATH/qc/fastxTrimmer_bothSites.sh $CONFIG_FILE $TRIMMER_LEFT $TRIMMER_RIGHT $FASTQ_DEMUX
find $FASTQ_DEMUX -name "*R2*.fastq.gz" | grep -v I1 | grep -v Undetermined | grep -v trimmed | sort | parallel -P$DNA_PARALLEL_ALIGNMENT -n1 bash $SCRIPT_PATH/qc/fastxTrimmer_bothSites.sh $CONFIG_FILE $TRIMMER_LEFT $TRIMMER_RIGHT $FASTQ_DEMUX
#wait

#Perform a Quality Control on FASTQ files
echo "FASTQC"
time bash $SCRIPT_PATH/qc/generateFastqc.sh $CONFIG_FILE $RUN_PATH &
#wait

#Align reads to reference genome (hg19)
echo "ALIGNMENT"
SCRIPT="bash $SCRIPT_PATH/dna/bwaAllignmentPairedRead.sh $CONFIG_FILE $BAM_PATH $LOG_PATH $RUN_ID"

find $FASTQ_DEMUX -name "*_trimmed.fastq.gz" | grep -v I1 | grep -v Undetermined | sort | parallel -P $DNA_PARALLEL_ALIGNMENT -n2 $SCRIPT

#Not needed
#echo "MERGE"
#find $BAM_PATH -name "*.bam" | grep dupsMarked | grep -v Undetermined | grep -v MERGED | grep -v withDups | sort | parallel -P$DNA_PARALLEL_ALIGNMENT -N 4 bash $SCRIPT_PATH/dna/mergeLaneBamFiles.sh $CONFIG_FILE $BAM_PATH $LOG_PATH

#Special_POS
#echo "SPECIAL POSITION"
#bash $SCRIPT_PATH/dna/runSpecialPos_analysis_seqrun.sh $CONFIG_FILE $BAM_PATH $SPECIAL_POS_PATH &

#CNV
#echo "CNV"
#mkdir -p $CNV_PATH
##move the target selection into the run script to enable parallel
#i=1
#while read sample; do
#    IFS=',' read -ra SAMPLE_COMP <<< "$sample"
#    SAMPLE_ID=${SAMPLE_COMP[0]}
#    PANEL_TYPE=${SAMPLE_COMP[2]}
#    echo "Start cnv $SAMPLE_ID $PANEL_TYPE"
#
#    Rscript $SCRIPT_PATH/cnv/cnv_analysis_seqCNA_seqRun.R $SERVER_RESULT_PATH $CNV_PATH $PANEL_TYPE $SAMPLE_ID $BAM_PATH/${SAMPLE_ID}_MERGED.bam  $RUN_ID &
#
#    if [ $(($i % $DNA_PARALLEL_ALIGNMENT)) = 0 ]; then
#        wait
#    fi
#    i=$(($i +1))
#done <$SAMPLE_FILE
#
#wait
#
echo "Variant Calling using Samtools for SNVs and Platypus for Indels"
#
mkdir -p $VAR_PATH
mkdir -p $PLATYPUS_VAR

ACT_BED_FILE=$SCRIPT_PATH/bed/3003971_Covered.bed

find $BAM_PATH -name "*.dupsMarked.bam" | while read fname; do
      bash $SCRIPT_PATH/dna/runSamtools_mpileup_SingleCase.sh $CONFIG_FILE $VAR_PATH $ACT_BED_FILE $fname #&
      #bash $SCRIPT_PATH/dna/runPlatypus.sh $CONFIG_FILE $PLATYPUS_VAR $ACT_BED_FILE $fname
done

#move the target selection into the run script to enable parallel
#i=1
#while read sample; do
#    IFS=',' read -ra SAMPLE_COMP <<< "$sample"
#    SAMPLE_ID=${SAMPLE_COMP[0]}
#    PANEL_TYPE=${SAMPLE_COMP[2]}
#    echo "Start alignment $SAMPLE_ID $PANEL_TYPE"
#    ACT_BAM_FILE=$BAM_PATH/${SAMPLE_ID}_MERGED.bam
#    ACT_BED_FILE="NA"
#
#    if [ "$PANEL_TYPE" == "NPHD2015A" ]; then
#        ACT_BED_FILE=$SCRIPT_PATH/bed/0720431/0720431_Covered_adaptedChrom.bed
#    #elif  [ "$PANEL_TYPE" == "MNG2015A" ]; then
#	  #   ACT_BED_FILE=$SCRIPT_PATH/bed/meningiom/0737331_Covered_adaptedChr.bed
#    #elif   [ "$PANEL_TYPE" == "EXON_V5" ]; then
#	  #   ACT_BED_FILE=$SCRIPT_PATH/bed/S04380110/S04380110_Covered_adapted.bed
#    fi
#
#    bash $SCRIPT_PATH/dna/runSamtools_mpileup_SingleCase.sh  $CONFIG_FILE $VAR_PATH $ACT_BED_FILE $ACT_BAM_FILE  &
#    bash $SCRIPT_PATH/dna/runPlatypus.sh $CONFIG_FILE $PLATYPUS_VAR $ACT_BED_FILE $ACT_BAM_FILE &
#    if [ $(($i % $DNA_PARALLEL_ALIGNMENT)) = 0 ]; then
#        wait
#    fi
#    i=$(($i +1))
#done <$SAMPLE_FILE
#
#wait
#
#
#echo "TUMOR SUB BLOOD"
#
#while read pair; do
#    IFS=',' read -ra SAMPLE_PAIR <<< "$pair"
#
#     bash $SCRIPT_PATH/dna/TumorSubBlood_vcf.sh $CONFIG_FILE $FILE_PATH/var "MPILEUP" ${SAMPLE_PAIR[0]} ${SAMPLE_PAIR[1]} &
#     bash $SCRIPT_PATH/dna/TumorSubBlood_vcf.sh $CONFIG_FILE $FILE_PATH/var_platypus "PLATYPUS" ${SAMPLE_PAIR[0]} ${SAMPLE_PAIR[1]} &
#done <$TUMOR_BLOOD_FILE
#
#wait
#
#echo "COVERAGE"
#coverage analysis
#
#COVERAGE_PATH=$FILE_PATH/coverage
#mkdir -p $COVERAGE_PATH
#
#
#i=1
#while read sample; do
#    IFS=',' read -ra SAMPLE_COMP <<< "$sample"
#    SAMPLE_ID=${SAMPLE_COMP[0]}
#    PANEL_TYPE=${SAMPLE_COMP[2]}
#    echo $SAMPLE_ID $PANEL_TYPE
#    ACT_BAM_FILE=$BAM_PATH/${SAMPLE_ID}_MERGED.bam
#    ACT_BED_FILE="NA"
#
#    if [ "$PANEL_TYPE" == "NPHD2015A" ]; then
#        ACT_BED_FILE=$SCRIPT_PATH/bed/0720431/0720431_Covered_adaptedChrom.bed
#    elif  [ "$PANEL_TYPE" == "MNG2015A" ]; then
#	ACT_BED_FILE=$SCRIPT_PATH/bed/meningiom/0737331_Covered_adaptedChr.bed
#    elif   [ "$PANEL_TYPE" == "EXON_V5" ]; then
#	ACT_BED_FILE=$SCRIPT_PATH/bed/S04380110/S04380110_Covered_adapted.bed
#    fi
#
#  Rscript $SCRIPT_PATH/qc/CoverageTEQC.R $COVERAGE_PATH $ACT_BED_FILE $ACT_BAM_FILE &
#
#
#    if [ $(($i % $DNA_PARALLEL_ALIGNMENT)) = 0 ]; then
#        wait
#    fi
#    i=$(($i +1))
#done <$SAMPLE_FILE
#
#wait
#
#Rscript $SCRIPT_PATH/qc/CoverageSummary_Mixed.R $COVERAGE_PATH $SAMPLE_FILE $SCRIPT_PATH/bed
#

echo "Analysis ready!"
