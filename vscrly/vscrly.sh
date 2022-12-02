#!/bin/bash
# This script counts on valid vsc message relayed by each address on Sputnik consumer chain.
set -e 

# Gloval Vars
CHAINID="neutron"
BINARY="./bin/securityd"
RPC="https://${CHAINID}-rpc.ztake.org:443"
OUTPUT="./output"

JQ='jq'
EVENTS='ccv_packet.module=ccvconsumer'
LIMIT=10
DATADIR='./vscdata'
VSCSUFFIX='.vscfile.output'
ANALYSIS='analysis.output'
STARTPAGE="1"
ENDPAGE="1"

# Make directory for vsc data
vsc-mkdir() {
    if [ ! -d "${DATADIR}/${CHAINID}" ]; then
        echo "Making directory: ${DATADIR}/${CHAINID}"
        mkdir -p ${DATADIR}/${CHAINID}
    else
        echo "Directory already exists."
    fi
}

# Get Lateset Page Number
vsc-fetch-latest-page() {
    echo "Fetching newest total page number with page limit ${LIMIT}..."
    ENDPAGE=$(${BINARY} query txs --events ${EVENTS} --output json --limit ${LIMIT} --node ${RPC} | ${JQ} --raw-output '."page_total"')
    echo "--> Total page number is ${ENDPAGE}."
}

# Generate Analysis File
vsc-generate-analysis() {
    # Check there's no empty file
    echo "Checking fetched data..."
    for file in ${DATADIR}/${CHAINID}/*${VSCSUFFIX}; do
        if [[ -z $(grep '[^[:space:]]' $file) ]]; then
            echo "--> $file is empty, unable to continue..."
            exit 1
        fi
    done
    echo "Passing check."

    ANLSTMP=${DATADIR}/${CHAINID}/${ANALYSIS}.tmp
    echo "Generating analysis file ${ANALYSIS}..."
    touch ${ANLSTMP}
    for file in ${DATADIR}/${CHAINID}/*${VSCSUFFIX}; do
        cat ${file} >> ${ANLSTMP}
    done
    sort -k2,2 -k4,4n < ${ANLSTMP} | cut -d ' ' -f 2 | uniq -c | sort -k1,1n | awk '{print $2,$1}' > ${DATADIR}/${CHAINID}/${ANALYSIS}
    sed -i '1s/^/Signer                                        Times\n/' ${DATADIR}/${CHAINID}/${ANALYSIS}
    rm ${ANLSTMP}
    mv ${DATADIR}/${CHAINID}/${ANALYSIS} ${OUTPUT}/${CHAINID}.output
    echo "--> Done."    
}

# Retry fetch events
vsc-retry-fetch() {
    for file in ${DATADIR}/${CHAINID}/*${VSCSUFFIX}; do
        if [[ -z $(grep '[^[:space:]]' $file) ]]; then
            echo "--> $file is empty..."
            number=$(echo $file | sed -e s/[^0-9]//g)
            ${BINARY} query txs --events ${EVENTS} --output json --limit ${LIMIT} --page ${number} --node ${RPC} | ${JQ} --raw-output '.txs[] | "Signer " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).signer + " Height " + .height + " TxHash " + .txhash' > ${file}
        fi
    done
}

# Fetch single page
vsc-fetch-single() {
    vsc-mkdir

    if [ "$#" -ne 1 ]; then
        echo "Page arg not speicified"
        exit 1
    fi

    VSCFILE=${DATADIR}/${CHAINID}/${1}${VSCSUFFIX}
    ${BINARY} query txs --events ${EVENTS} --output json --limit ${LIMIT} --page ${1} --node ${RPC} | ${JQ} --raw-output '.txs[] | "Signer " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).signer + " Height " + .height + " TxHash " + .txhash' > ${VSCFILE}
}

vsc-fetch-all() {
    vsc-mkdir

    vsc-fetch-latest-page

    # Get Last Fechted Page Number
    STARTPAGE=$(ls -av ${DATADIR}/${CHAINID} | grep ${VSCSUFFIX} | tail -1 | sed -e s/[^0-9]//g )
    if [ -z "${STARTPAGE}" ]; then
        STARTPAGE="1"
    fi
    echo "Last Fetching page number is ${STARTPAGE}"

    # Query Loop 
    echo "Fetching txs..."
    for (( i=${STARTPAGE}; i<=${ENDPAGE}; i++ )); do 
        echo "--> Fetching page ${i} on ${RPC} at $(date +"%T")"
        VSCFILE=${DATADIR}/${CHAINID}/${i}${VSCSUFFIX}
        ${BINARY} query txs --events ${EVENTS} --output json --limit ${LIMIT} --page ${i} --node ${RPC} | ${JQ} --raw-output '.txs[] | "Signer " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).signer + " Height " + .height + " TxHash " + .txhash' > ${VSCFILE}
    done
    echo "Finish fetching."

    # Retry at most three times
    for (( i=1; i<=3; i++ )) do 
        echo "--> retry $i times"
        vsc-retry-fetch
    done

    # Generate Analysis
    vsc-generate-analysis
}

# Test Function
checkpage() {
    vsc-mkdir

    echo "Fetching page ${i} twice with page limit ${LIMIT}..."
    echo "--> Fetching for the first time..."
    ${BINARY} query txs --events ${EVENTS} --output json --limit ${LIMIT} --page ${1} --node ${RPC} | ${JQ} --raw-output . > ${DATADIR}/test-1
    sleep 1
    echo "--> Fetching for the second time..."
    ${BINARY} query txs --events ${EVENTS} --output json --limit ${LIMIT} --page ${1} --node ${RPC} | ${JQ} --raw-output . > ${DATADIR}/test-2
    if cmp -s ${DATADIR}/test-1 ${DATADIR}/test-2
    then
        echo "--> The files match."
    else
        echo "--> WARN: The files are different."
    fi
    rm ${DATADIR}/test-1 ${DATADIR}/test-2
}

# Script Entrance
if declare -f "$1" > /dev/null
then
    "$@"
else    
    echo "$1 is not a known function name" >& 2
    exit 1
fi