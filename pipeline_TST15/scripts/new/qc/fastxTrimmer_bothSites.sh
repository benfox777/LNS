#!/bin/bash
CONFIG_FILE=$1
source $CONFIG_FILE

FIRST_BASE_KEEP=$2
TRIM_BASES_FROM_END=$3
FASTX_PATH=$4
RAW_SEQ_1=$5

RESULT_FILENAME=$(basename ${RAW_SEQ_1})
RESULT_FILENAME=${RESULT_FILENAME%".fastq.gz"}_trimmed.fastq.gz

echo "RESULT_FILENAME: ${RESULT_FILENAME}"

#create the folder for specific run
#mkdir -p ${FASTX_PATH}

UNZIPTOOL_OPTIONS="-c"
#${UNZIPTOOL} ${UNZIPTOOL_OPTIONS} ${RAW_SEQ_1} | mbuffer -q -m 800M -l /dev/null | ${FASTX_TRIMMER_BINARY} -z -f ${FIRST_BASE_KEEP} -l ${TRIM_BASES_FROM_END} -o ${FASTX_PATH}/${RESULT_FILENAME}
${UNZIPTOOL} ${UNZIPTOOL_OPTIONS} ${RAW_SEQ_1} | ${FASTX_TRIMMER_BINARY} -Q33 -z -o ${FASTX_PATH}/${RESULT_FILENAME}



#$trim_galore_binary $RAW_SEQ_1 -path_to_cutadapt /home/benflies/.local/bin/cutadapt -o ${FASTQ_DEMUX} --length 20 --quality 20 > ${RESULT_FILENAME}
