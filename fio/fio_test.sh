#!/bin/bash

for s in async_job; do
    for b in 8k 32k 128k 512k 2M 8M 32M; do
        for n in 1 4 8 16 32; do
            echo "Running {$s}_{$b}_{$n}.txt"
            BLOCKSIZE=$b \
            NUMJOBS=$n \
            fio fio_config.ini --section=$s > "$s"_"$b"_"$n".txt
        done
    done
done

grep WRITE *.txt | awk '{ split($4,a,"="); print $1, substr(a[2],0,length(a[2])-5)/1024, "MB/s"}' \
    > fio_results.txt
