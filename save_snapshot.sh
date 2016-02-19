#!/bin/bash

source functions.sh || (echo "functions.sh not found!"; exit)
source config.sh || (echo "config.sh not found!"; exit)

# Arguments
# $1 = ID string of the snapshot; name of folder created/replaced
SNAPID=$1

[ -n "$SNAPID" ] || die "Missing argument: snapshot name"
[ -n "$SNAPDIR" ] || die "Global variable SNAPDIR must be defined"
TARGET=$SNAPDIR/$SNAPID

set -e

for d in "${!DEVS[@]}"; do
    mountpath=${MOUNTPOINT[$d]}
    use_btrfs=${USE_BTRFS[$d]}

    mkdir -p $TARGET
    rsync -aq --copy-links --delete $mountpath/$d $TARGET/$d
done

# Copy special output files
cp out?.txt $TARGET/
