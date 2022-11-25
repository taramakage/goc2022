#!/bin/bash
# This script counts on valid vsc message relayed by each address on Sputnik consumer chain.

BINARY='./sputnik'
JQ='jq'
RPC='https://sputnik-rpc.ztake.org:443'
EVENTS='ccv_packet.module=ccvconsumer'
LIMIT=30
VSC='vsc-output.txt'
ANALYSIS='vsc-analysis.txt'

# Remove Output
rm ${VSC} ${ANALYSIS}

# Get PageNumber
echo "Fetching total page number..."
PAGE=$(${BINARY} query txs --events ${EVENTS} --output json --limit 1 --node ${RPC} | ${JQ} '."page_total"')
echo "--> Total page number is ${PAGE}."

# Query Loop  
PAGE=1
echo "Fetching txs..."
for ((i=1;i<=PAGE;i++)); do 
    echo "--> Fetching page ${i} on ${RPC} at $(date +"%T")"
    ${BINARY} query txs --events ${EVENTS} --output json --limit ${LIMIT} --page ${i} --node ${RPC} | ${JQ} --raw-output '.txs[] | "Signer " + (.tx.body.messages[] | select(."@type"=="/ibc.core.channel.v1.MsgRecvPacket" and .packet."source_port"=="provider")).signer + " Height " + .height + " TxHash " + .txhash' >> ${VSC}
done
echo "Finish fetching."

# Sort by signer then height
echo "Generating analysis file ${ANALYSIS}..."
sort -k2,2 -k4,4n < ${VSC} | cut -d ' ' -f 2 | uniq -c | sort -k1,1n | awk '{print $2,$1}' >> ${ANALYSIS}                  
sed -i '1s/^/Signer                                        Times\n/' ${ANALYSIS}
echo "--> Done."