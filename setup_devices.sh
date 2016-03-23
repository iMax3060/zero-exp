#!/bin/bash

# Use this file to set device paths and format them
# Optional "--force" argument to overwrite existing partitions

source functions.sh || (echo "functions.sh not found!"; exit)
source config.sh || (echo "config.sh not found!"; exit)

set -e

FORCE=false
if [[ "$1" == "--force" ]]; then
    FORCE=true
    shift 1
fi

ITER=${!DEVS[@]}
if [ -n "$1" ]; then
    ITER=$1
fi

for d in $ITER; do
    devpath=${DEVS[$d]} 
    mountpath=${MOUNTPOINT[$d]}
    use_btrfs=${USE_BTRFS[$d]}

    formatDevice $devpath $mountpath $use_btrfs
    echo "---------------------------------------------------------"
done
