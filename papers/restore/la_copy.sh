#!/bin/bash

while true; do
    rsync -qavz /mnt/log/log/ /mnt/archive/copy_log/
done
