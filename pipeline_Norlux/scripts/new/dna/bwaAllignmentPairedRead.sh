#!/bin/bash
CONFIG_FILE=$1
source $CONFIG_FILE

BAM_DIR=$2
LOG_DIR=$3
RUN_ID=$4
RAW_SEQ_1=$5
RAW_SEQ_2=$6

echo $RAW_SEQ_1
echo $RAW_SEQ_2

FILE_NAME=$(basename "${RAW_SEQ_1}")

IFS='_' read -ra FILE_NAME_COMP <<< "$FILE_NAME"

SAMPLE_ID=${FILE_NAME_COMP[0]}
LANE_ID=${FILE_NAME_COMP[2]}

RUN_GROUP_HEADER="@RG\tID:${RUN_ID}_${LANE_ID}\tLB:Lib01\tSM:${SAMPLE_ID}\tPL:ILLUMINA"

RESULT_FILENAME=${SAMPLE_ID}_aligned

SCRATCH_DIR=${BAM_DIR}/tmp/${SAMPLE_ID}_${LANE_ID}

echo "SEQ1: ${RAW_SEQ_1}"
echo "SEQ2: ${RAW_SEQ_2}"
echo "SCRATCH_DIR: ${SCRATCH_DIR}"
echo "BAM_DIR: ${BAM_DIR}"
echo "RESULT_PATH: ${LOCAL_RESULT_PATH}"
echo "FILE_NAME: ${RESULT_FILENAME}"

#create the folder for specific run
mkdir -p ${SCRATCH_DIR}
mkdir -p ${BAM_DIR}

INDEX_PREFIX=$REFERENCE_PATH/hg19
REFERENCE=${INDEX_PREFIX}/ucsc.hg19.fa

alnThreadOptions=$DNA_BWA_MEM_PARALLEL

#baseBWACall="${BWA_BINARY} mem -t ${alnThreadOptions} -R ${RUN_GROUP_HEADER} ${REFERENCE}"

baseBWACall="${BWA_BINARY} mem -t ${alnThreadOptions} -M ${REFERENCE} -p"

echo "bwacall $baseBWACall $RAW_SEQ_1 $RAW_SEQ_2 $INDEX_SEQ"

UNZIPTOOL_OPTIONS="-c"

FNPIPE1=$SCRATCH_DIR/NAMED_PIPE1
FNPIPE2=$SCRATCH_DIR/NAMED_PIPE2

nice ${UNZIPTOOL} ${UNZIPTOOL_OPTIONS} ${RAW_SEQ_1}  > $FNPIPE1 &
nice ${UNZIPTOOL} ${UNZIPTOOL_OPTIONS} ${RAW_SEQ_2}  > $FNPIPE2 &

BWA_LOG=${LOG_DIR}/bwa_${RESULT_FILENAME}.log
date > ${BWA_LOG}
echo "" >> ${BWA_LOG}
SAM_LOG=${LOG_DIR}/samtools_${RESULT_FILENAME}.log
date > ${SAM_LOG}
echo "" >> ${SAM_LOG}

BAM_FILE=${SCRATCH_DIR}/${RESULT_FILENAME}.bam
SAMPESORT_MEMSIZE=2000000000

#alignment and creation of sorted bam
${baseBWACall} ${FNPIPE1} ${FNPIPE2} | ${SAMTOOLS_SORT_BINARY} view -uSbh - | ${SAMTOOLS_SORT_BINARY} sort -@ 8 -m ${SAMPESORT_MEMSIZE} > ${BAM_FILE}
#${baseBWACall} ${FNPIPE1} ${FNPIPE2} > ${BAM_FILE}_1
#${SAMTOOLS_SORT_BINARY} ${BAM_FILE} view -h -o ${BAM_FILE}_2
#${SAMTOOLS_SORT_BINARY} sort -@ 8 -m ${SAMPESORT_MEMSIZE} ${BAM_FILE}_2 > ${BAM_FILE}_3

${SAMTOOLS_SORT_BINARY} index ${BAM_FILE} > ${BAM_File}.bai

BAM_DUPREM=${SCRATCH_DIR}/${RESULT_FILENAME}.dupsMarked.bam
PICARD_LOG=${LOG_DIR}/picard_${RESULT_FILENAME}.log
java -jar /home/benflies/Bioinformatics/Tools/picard-tools-2.5.0/picard.jar MarkDuplicates I=${BAM_FILE} O=${BAM_DUPREM} M=$PICARD_LOG REMOVE_DUPLICATES=false

${SAMTOOLS_SORT_BINARY} index ${BAM_DUPREM}


#move and remove files
rm $FNPIPE1
rm $FNPIPE2
mv ${SCRATCH_DIR}/* ${BAM_DIR}

eval "nice $cmd" # execute the command
