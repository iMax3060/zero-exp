#!/bin/bash

declare -A DEVS
declare -A MOUNTPOINT
declare -A USE_BTRFS

# SSDs
DEVS[log]=/dev/sda1
DEVS[archive]=/dev/sdg1
DEVS[db]=/dev/sdh1
DEVS[backup]=/dev/sdi1

# HDDs
# DEVS[log]=/dev/sdf1
# DEVS[archive]=/dev/sdb1
# DEVS[db]=/dev/sdd1
# DEVS[backup]=/dev/sde1

# # MOUNTPOINT[log]=/dev/shm/log
# MOUNTPOINT[log]=/mnt/log
# # MOUNTPOINT[archive]=/dev/shm/archive
# MOUNTPOINT[archive]=/mnt/archive
# MOUNTPOINT[db]=/mnt/db
# MOUNTPOINT[backup]=/mnt/backup

# hyper server fast SSD
MOUNTPOINT[log]=/data/csauer
MOUNTPOINT[archive]=/data/csauer
MOUNTPOINT[db]=/data/csauer
MOUNTPOINT[leveldb]=/data/csauer

# Whether to use btrfs or ext3 (w/o journal)
USE_BTRFS[log]=false
USE_BTRFS[archive]=false
USE_BTRFS[db]=false
USE_BTRFS[backup]=false

# Where snapshots of data and log will be saved
SNAPDIR=/data/csauer/snap

MOUNTOPTS="noatime,noexec,noauto,nodev,nosuid"
