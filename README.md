# GoC 2022

Better to run these script on and config rpc to your node machine to enhance speed.

## Count VSC

Directory
- `evidence` evidence output for an address
- `statistic`
  - `chain` fetched vsc data on a specific chain
  - `output` vsc count times for all addresses
- `config` config for rly 


Count vsc relay times of different addresses:

1. `vim vscrly/vscrly.sh` and config consumer chain name
2. `./vscrly/vsc.sh vsc-fetch-all`

Get vsc evidence for a specific address:

1. `vim ./vscrly/evidence.sh` and config address and chain
2. `./vscrly/evidence.sh vsc-evidence`

## Compare VSC

> Thanks to @clemensgg

1. `npm install`
2. `npm run cmp-vsc`