#!/bin/bash
gaiad query provider consumer-genesis lycoris -o json | jq . > ccv.json
curl -s https://raw.githubusercontent.com/taramakage/ics-testnets/main/game-of-chains-2022/lycoris/lycoris-fresh-genesis.json  | jq . > fresh.json
jq -s '.[0].app_state.ccvconsumer = .[1] | .[0]' fresh.json ccv.json > lycoris-genesis.json
sha256sum lycoris-genesis.json