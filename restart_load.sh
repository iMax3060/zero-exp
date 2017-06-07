#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SNAPSHOT=db-750

# assumption: snapshot is loaded in the snapshot dir
for LV in 1 2 4 8 16 32 64 128; do
    NEW_SNAPSHOT=$SNAPSHOT"-shifting-"$LV
    mkdir -p $SNAPDIR/$NEW_SNAPSHOT
    ./load_snapshot.sh $SNAPSHOT
    ./run_kits.sh -c papers/fineline/genlog_db.cfg --logVolume $((LV * 1000))
    rsync --delete -aq ${MOUNTPOINT[log]}/log/ $SNAPDIR/$NEW_SNAPSHOT/log/
    rm -f $SNAPDIR/$NEW_SNAPSHOT/db
    ln -s $SNAPDIR/$SNAPSHOT/db $SNAPDIR/$NEW_SNAPSHOT/db
done
