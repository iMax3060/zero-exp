#!/bin/bash

source functions.sh || (echo "functions.sh not found!"; exit)
source config.sh || (echo "config.sh not found!"; exit)

# Arguments
# $1 = ID string of the snapshot; name of folder created/replaced
SNAPID=$1

[ -n "$SNAPID" ] || die "Missing argument: snapshot name"
[ -n "$SNAPDIR" ] || die "Global variable SNAPDIR must be defined"
SOURCE=$SNAPDIR/$SNAPID

set -e

for d in "${!DEVS[@]}"; do
    mountpath=${MOUNTPOINT[$d]}
    use_btrfs=${USE_BTRFS[$d]}

    echo -n "Copying $d ... "
    if [ "$use_btrfs" = true ]; then
        # rsync will be instantaneous if first old/shadow copy was already made
        rsync -a $SOURCE/$d $mountpath/old/$d
        if [ -d $mountpath/new ]; then
            # delete current dirty-copy snapshot
            btrfs subvolume delete $mountpath/new
        fi
        # create new dirty snapshot from shadow one
        btrfs subvolume snapshot $mountpath/old $mountpath/new
        ln -fs $mountpath/new/$s $mountpath/db
    else
        rsync -a --delete $SOURCE/$d $mountpath/$d
    fi
    echo "OK"
done
