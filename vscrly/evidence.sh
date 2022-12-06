#!/bin/bash
# This dummy script counts the number and height of valid vsc for specific address
set -e 

# Gloval Vars
## General
BINARY="./bin/securityd"
JQ='jq'
DIR="./evidence"
LIMIT=100
## CHAINIDS
CHAINID1="neutron"
CHAINID2="gopher"
CHAINID3="hero"
CHAINID4="apollo"
CHAINID5="duality"
## RPCS
RPC1="https://${CHAINID1}-rpc.ztake.org:443"
RPC2="https://${CHAINID2}-rpc.ztake.org:443"
RPC3="https://${CHAINID3}-rpc.ztake.org:443"
RPC4="https://${CHAINID4}-rpc.ztake.org:443"
RPC5="https://${CHAINID5}-rpc.ztake.org:443"
## EVENTS
EVENTS1='ccv_packet.module=ccvconsumer&recv_packet.packet_dst_port=consumer&recv_packet.packet_dst_channel=channel-0&message.sender=neutron1ctprl2u2pgcdlc07r9wzkx3jj036v2lhs9d5kw'
EVENTS2='ccv_packet.module=ccvconsumer&recv_packet.packet_dst_port=consumer&recv_packet.packet_dst_channel=channel-0&message.sender=cosmos1ctprl2u2pgcdlc07r9wzkx3jj036v2lh56ykvf'
EVENTS3='ccv_packet.module=ccvconsumer&recv_packet.packet_dst_port=consumer&recv_packet.packet_dst_channel=channel-0&message.sender=cosmos1ctprl2u2pgcdlc07r9wzkx3jj036v2lh56ykvf'
EVENTS4='ccv_packet.module=ccvconsumer&recv_packet.packet_dst_port=consumer&recv_packet.packet_dst_channel=channel-0&message.sender=cosmos1ctprl2u2pgcdlc07r9wzkx3jj036v2lh56ykvf'
EVENTS5='ccv_packet.module=ccvconsumer&recv_packet.packet_dst_port=consumer&recv_packet.packet_dst_channel=channel-0&message.sender=cosmos1ctprl2u2pgcdlc07r9wzkx3jj036v2lh56ykvf'

# Fetch all
vsc-fetch() {
    # neutron
    echo "-> Fetching ${CHAINID1}"
    ${BINARY} query txs --events ${EVENTS1} --output json --limit ${LIMIT} --page 1 --node ${RPC1} | ${JQ} --raw-output '.txs[] | "TxHash " + .txhash + " Seq " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).packet.sequence + " Height " + .height' > ${DIR}/${CHAINID1}.evidence
    ${BINARY} query txs --events ${EVENTS1} --output json --limit ${LIMIT} --page 2 --node ${RPC1} | ${JQ} --raw-output '.txs[] | "TxHash " + .txhash + " Seq " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).packet.sequence + " Height " + .height' >> ${DIR}/${CHAINID1}.evidence
    ${BINARY} query txs --events ${EVENTS1} --output json --limit ${LIMIT} --page 3 --node ${RPC1} | ${JQ} --raw-output '.txs[] | "TxHash " + .txhash + " Seq " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).packet.sequence + " Height " + .height' >> ${DIR}/${CHAINID1}.evidence
    # gopher
    echo "-> Fetching ${CHAINID2}"
    ${BINARY} query txs --events ${EVENTS2} --output json --limit ${LIMIT} --page 1 --node ${RPC2} | ${JQ} --raw-output '.txs[] | "TxHash " + .txhash + " Seq " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).packet.sequence + " Height " + .height' > ${DIR}/${CHAINID2}.evidence
    # hero
    echo "-> Fetching ${CHAINID3}"
    ${BINARY} query txs --events ${EVENTS3} --output json --limit ${LIMIT} --page 1 --node ${RPC3} | ${JQ} --raw-output '.txs[] | "TxHash " + .txhash + " Seq " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).packet.sequence + " Height " + .height' > ${DIR}/${CHAINID3}.evidence
    # ${BINARY} query txs --events ${EVENTS3} --output json --limit ${LIMIT} --page 2 --node ${RPC3} | ${JQ} --raw-output '.txs[] | "TxHash " + .txhash + " Seq " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).packet.sequence + " Height " + .height' > ${DIR}/${CHAINID3}.evidence
    # apollo
    echo "-> Fetching ${CHAINID4}"
    ${BINARY} query txs --events ${EVENTS4} --output json --limit ${LIMIT} --page 1 --node ${RPC4} | ${JQ} --raw-output '.txs[] | "TxHash " + .txhash + " Seq " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).packet.sequence + " Height " + .height' > ${DIR}/${CHAINID4}.evidence
    # duality
    echo "-> Fetching ${CHAINID5}"
    ${BINARY} query txs --events ${EVENTS5} --output json --limit ${LIMIT} --page 1 --node ${RPC5} | ${JQ} --raw-output '.txs[] | "TxHash " + .txhash + " Seq " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).packet.sequence + " Height " + .height' > ${DIR}/${CHAINID5}.evidence
}

vsc-generate-analysis() {
    if [ -e "${DIR}/count" ]; then
        rm ${DIR}/count
    touch ${DIR}/count 
    fi
    
    # Count times
    for file in ${DIR}/*.evidence; do
        COUNT="$(basename ${file} .evidence) "
        COUNT+=$(wc -l < ${file})
        echo ${COUNT} >> ${DIR}/count
    done
}

vsc-evidence() {
    echo "It may take minutes to generate output..."
    vsc-fetch
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