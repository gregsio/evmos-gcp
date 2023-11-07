#!/bin/bash

set -e
trap 'echo "Error on line $LINENO";' ERR

CHAINID="${CHAIN_ID:-evmos_9000-4}"
MONIKER="testnetvalidator-gregsio"

# Remember to change to other types of keyring like 'file' in-case exposing to outside world,
# otherwise your balance will be wiped quickly
# The keyring test does not require private key to steal tokens from you
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
HOMEDIR="/evmos/evmosd"
CONFIGDIR="$HOMEDIR/config"
DATADIR="$HOMEDIR/data"

SNAPSHOTNAME="evmos_18472724.tar.lz4"

# Path variables
CONFIG="$CONFIGDIR/config.toml"
APP_TOML="$CONFIGDIR/app.toml"
GENESIS="$CONFIGDIR/genesis.json"

for cmd in jq curl lz4 evmosd; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "$cmd is required but it's not installed. Aborting."; exit 1; }
done


# Setup client config
evmosd config chain-id "$CHAINID" --home "$HOMEDIR"
evmosd config keyring-backend "$KEYRING" --home "$HOMEDIR"

update_or_add() {
    key=$1
    value=$2
    # Check if the instruction exists
    if grep -q "^$key = " $CONFIG; then
        # If the instruction exists, update it using sed
        sed -i -e "s/^$key = .*/$key = $value/" $CONFIG
    else
        # If the instruction doesn't exist, add it using echo
        echo "$key = $value" >> $CONFIG
    fi
}

# Configuration for snapshot sync
update_or_add "pruning" "\"custom\"" "$APP_TOML"
update_or_add "pruning-keep-recent" "100" "$APP_TOML"
update_or_add "pruning-keep-every" "0" "$APP_TOML"
update_or_add "pruning-interval" "10" "$APP_TOML"
sed -i 's/indexer = kv/indexer = null/g' "$CONFIG"

# Enable prometheus metrics and all APIs for dev node
sed -i 's/prometheus = false/prometheus = true/' "$CONFIG"
sed -i 's/prometheus-retention-time  = "0"/prometheus-retention-time  = "1000000000000"/g' "$APP_TOML"
sed -i 's/enabled = false/enabled = true/g' "$APP_TOML"
sed -i 's/enable = false/enable = true/g' "$APP_TOML"
# Don't enable memiavl by default
grep -q -F '[memiavl]' "$APP_TOML" && sed -i '/\[memiavl\]/,/^\[/ s/enable = true/enable = false/' "$APP_TOML"

# Stream the snapshot into database location.

curl -o - -L https://snapshots.polkachu.com/testnet-snapshots/evmos/${SNAPSHOTNAME} \
    | lz4 -c -d - \
    | tar -x -C $HOMEDIR \
    || { echo "snapshot ${SNAPSHOTNAME} not available, use the latest one. check https://polkachu.com/testnets/evmos/snapshots"; exit 1; }

cp ${DATADIR}/priv_validator_state.json  ${CONFIGDIR}/priv_validator_state.json

evmosd tendermint unsafe-reset-all --home $HOME/.evmosd --keep-addr-book

echo "evmosd tx staking create-validator ..."
evmosd tx staking create-validator \
--amount=1000000atevmos \
--pubkey=$(evmosd tendermint show-validator) \
--moniker="${MONIKER}" \
--chain-id='evmos_9000-4' \
--commission-rate="0.05" \
--commission-max-rate="0.10" \
--commission-max-change-rate="0.01" \
--min-self-delegation="1000000" \
--gas="auto" \
--gas-prices="0.025atevmos" \
--from='mykey' \
--home="${HOMEDIR}"
