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

for d in "${!MOUNTPOINT[@]}"; do
    targetdir=${MOUNTPOINT[$d]}
    use_btrfs=${USE_BTRFS[$d]}

    if [ "$use_btrfs" = true ]; then
        if [ ! -d $targetdir/old ]; then
            btrfs subvolume create $targetdir/old
            echo -n "Copying $d ... "
            rsync -a $SOURCE/$d $targetdir/old/
            echo "OK"
        fi

        if [ -d $targetdir/new ]; then
            # delete current dirty-copy snapshot
            btrfs subvolume delete $targetdir/new
        fi

        # create new dirty snapshot from shadow one
        btrfs subvolume snapshot $targetdir/old $targetdir/new
        ln -fs $targetdir/new/$d $targetdir/$d
    else
        echo -n "Copying $d ... "
        if [ -e $SOURCE/$d ]; then
            # -a is equivalent to -rlptgoD, but we dont want to copy symlinks (-L instead of -l)
            rsync -rptgoDL --delete --inplace $SOURCE/$d $targetdir/
            echo "OK"
        else
            if [ -d $targetdir/$d ]; then
                rm -rf $targetdir/$d/*
            # not deleting db and backup because it's not really required in any practical scenario
            # else
                # rm -rf $targetdir/$d
            fi
            echo "NOT FOUND"
        fi
    fi
done
