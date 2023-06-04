#!/usr/bin/env bash
# https://developers.mixin.one/docs/mainnet/guide/full-node-join
node_url="mixin-node-01.b1.run:7239"

set -e

if ! which git 2>&1 > /dev/null; then
	echo "Please install 'git' first"
	exit 1
fi

if ! which go 2>&1 > /dev/null; then
	echo "Please install 'go' first"
	exit 1
fi

<<comment
if ! which mixin-cli 2>&1 > /dev/null; then
	echo "Installing mixin-cli"
	git clone https://github.com/fox-one/mixin-cli.git
	cd mixin-cli
	go install
	cd ..
fi	
comment

# Generating Mainnet Private Keys and Addresses
git clone https://github.com/MixinNetwork/mixin.git
cd mixin
go build

./mixin createaddress -public > signer.key
./mixin createaddress -public > payee.key
echo "Signer key saved in singer.key"
echo "Payee key saved in payee.key"

# Transfering Collateral Tokens to bots
# Depositing Collateral Tokens To Mainnet Address
# This can done by using MVM Contract. TODO
deposit_hash=""

signer_address=$(grep -oE 'address: ([[:xdigit:]]+)' "signer.key" | awk '{print $NF}')
signer_view_key=$(grep -oE 'view key: ([[:xdigit:]]+)' "signer.key" | awk '{print $NF}')
signer_spend_key=$(grep -oE 'spend key: ([[:xdigit:]]+)' "signer.key" | awk '{print $NF}')

payee_address=$(grep -oE 'spend key: ([[:xdigit:]]+)' "signer.key" | awk '{print $NF}')
payee_view_key=$(grep -oE 'view key: ([[:xdigit:]]+)' "payee.key" | awk '{print $NF}')
payee_spend_key=$(grep -oE 'spend key: ([[:xdigit:]]+)' "payee.key" | awk '{print $NF}')

key="${signer_view_key}${signer_spend_key}"
extra=${./mixin decodeaddress -a ${signer_address} | grep 'public spend key:' | awk '{print $NF}'}
asset="a99c2e0e2b1da4d648755ef19bd95139acbbe6564cfb06dec7cd34931ca72cdc"    # XIN ID
transaction_data=${./mixin --node $node_url gettransaction --hash $deposit_hash}
inputs_hash=$(echo "$transaction_data" | jq -r '.inputs[0].hash')
inputs_index=$(echo "$transaction_data" | jq -r '.inputs[0].index')
inputs="[{"hash": "$inputs_hash", "index":$inputs_index}]"
outputs="[{"type": 163, "amount": "$amount"}]"

raw_result=${./mixin -n $node_url signrawtransaction -key $key -raw "{"version":1,"asset":"$asset","inputs":$inputs,"outputs":$outputs,"extra":$extra}"}
raw="raw_result"

result=${./mixin -n $node_url sendrawtransaction -raw $raw}
echo $result
