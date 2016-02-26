#!/bin/bash

declare -A DEVS
declare -A MOUNTPOINT
declare -A USE_BTRFS

# SSDs
DEVS[log]=/dev/sda1
DEVS[archive]=/dev/sdg1
DEVS[db]=/dev/sdh1
# DEVS[backup]=/dev/sdi1

# HDDs
# DEVS[log]=/dev/sdf1
# DEVS[archive]=/dev/sdb1
# DEVS[db]=/dev/sdd1
# DEVS[backup]=/dev/sde1

MOUNTPOINT[log]=/mnt/log
MOUNTPOINT[archive]=/mnt/archive
MOUNTPOINT[db]=/mnt/db
MOUNTPOINT[backup]=/mnt/backup

# Whether to use btrfs or ext3 (w/o journal)
USE_BTRFS[log]=false
USE_BTRFS[archive]=false
USE_BTRFS[db]=true
USE_BTRFS[backup]=false

# Where snapshots of data and log will be saved
SNAPDIR=/mnt/snap

MOUNTOPTS="noatime,noexec,noauto,nodev,nosuid"

# Options passed to zero/kits by default
MAX_THREADS=24
WORKSPACE=20000
BUFSIZE=90000
LOGSIZE=80000
