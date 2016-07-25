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
    sourcedir=${MOUNTPOINT[$d]}
    use_btrfs=${USE_BTRFS[$d]}

    if [ "$use_btrfs" == "true" ]; then
        if [ -d $sourcedir/old ]; then
            # Delete old snapshot if already existing
            btrfs subvolume delete $sourcedir/old
        fi

        # Data is copied from "new" snapshot
        sourcedir=$sourcedir/new
    fi

    echo "Copying $d from $sourcedir to $TARGET"
    mkdir -p $TARGET
    if [ -e $sourcedir/$d ]; then
        rsync -aq --copy-links --delete $sourcedir/$d $TARGET
    fi
done

# Copy special output files
cp out?.txt $TARGET/ 2> /dev/null
