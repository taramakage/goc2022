#!/bin/bash
export ACCOUNT="cosmos1ctprl2u2pgcdlc07r9wzkx3jj036v2lh56ykvf"
gaiad tx gov submit-proposal consumer-addition lycoris-proposal.json \
--from=$ACCOUNT \
--chain-id=provider \
--home=/mnt/.gaia


gaiad tx gov submit-proposal consumer-removal lycoris-proposal-stop.json \
--from=$ACCOUNT \
--chain-id=provider \
--home=/mnt/.gaia