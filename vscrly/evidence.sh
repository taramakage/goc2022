#!/bin/bash
# This dummy script counts the number and height of valid vsc for specific address
set -e 

JQ='jq'
BINARY="./bin/securityd"
DIR="./evidence"
SUFFIX=".csv"

LIMIT=100
CHAINID=""
SENDER=""
SENDERS=("cosmos1ctprl2u2pgcdlc07r9wzkx3jj036v2lh56ykvf" "neutron1ctprl2u2pgcdlc07r9wzkx3jj036v2lhs9d5kw")
CHAINIDS=("neutron" "gopher" "hero" "apollo" "duality")

# Must set these vars before call this function
# - SENDER: ccvconsumer & sender
# - CHAINID: which chain to fetch
vsc-fetch() {
    # as var ref dosen't work, we define var here
    RPC="https://${CHAINID}-rpc.ztake.org:443"
    EVENTS="ccv_packet.module=ccvconsumer&recv_packet.packet_dst_port=consumer&recv_packet.packet_dst_channel=channel-0&message.sender=${SENDER}"

    # get the lastest page
    echo "  -> fetching lastest page number..."
    latest=$(${BINARY} query txs --events ${EVENTS} --output json --limit ${LIMIT} --node ${RPC} | ${JQ} --raw-output '."page_total"')
    output="${DIR}/${CHAINID}${SUFFIX}"
    echo "  -> lastest page number is ${latest}"
    if [ ! -f "${output}" ]; then
        touch ${output}
    fi

    # calulate the last page
    line=$(wc -l < ${output})
    last=$(( line/LIMIT + 1 ))
    position=$(((last-1) * LIMIT + 1))

    # delete content since position
    pattern="${position},\$d"
    sed -i $pattern ${output}
    
    # fetch vsc of the chain
    for (( i=${last}; i<=${latest}; i++)); do
        echo "  -> fetching on page ${i}..."
        ${BINARY} query txs --events ${EVENTS} --output json --limit ${LIMIT} --page ${i} --node ${RPC} | ${JQ} --raw-output '.txs[] | "TxHash " + .txhash + " Seq " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).packet.sequence + " Height " + .height' >> ${output}
    done
}

vsc-generate-analysis() {
    if [ -e "${DIR}/count" ]; then
        rm ${DIR}/count
    touch ${DIR}/count 
    fi
    
    # Count times
    for file in ${DIR}/*${SUFFIX}; do
        COUNT="$(basename ${file} ${SUFFIX}) "
        COUNT+=$(wc -l < ${file})
        echo ${COUNT} >> ${DIR}/count
    done
}

vsc-evidence() {
    echo "It may take minutes to process..."
    # for loop fetch
    for i in "${CHAINIDS[@]}"
    do 
        echo "-> fetching evidence on chain ${i}..."
        CHAINID=${i}
        if [ "${CHAINID}" = "neutron" ]; then
            SENDER=${SENDERS[1]}
        else 
            SENDER=${SENDERS[0]}
        fi 
        vsc-fetch
    done
    # generate output
    vsc-generate-analysis
}

# Script Entrance
if declare -f "$1" > /dev/null
then
    "$@"
else    
    echo "$1 is not a known function name" >& 2
    exit 1
fi