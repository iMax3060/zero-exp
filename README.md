# zero-exp
A collection of scripts to run experiments with the [Zero storage manager](https://github.com/caetanosauer/zero).

This repository also includes repeatability information and experiment data for papers we published with Zero.

## Overview

The scripts in this repository assist in the execution of experiments by managing common configuration and base data, supporting automatic execution of Zero commands with varying arguments, and saving results in a organized folder structure.
The repository also includes tools that process the generated data to produce plots and diagrams used in some of the papers we published.
This README focuses solely on the former scripts -- for details about how to reproduce the actual experiments in our papers, see the sub-folders.

We consider five main steps in the experiment execution process -- each of which is supported by a specific script.
These are explained in detail in the next sections below.

## Preparing the environment

Since the Zero storage manager was developed mainly to prototype techniques for database recovery, the execution of an experiment usually involves multiple dedicated storage devices.
These are: recovery log, database, log archive, and backups.
The script `setup_devices.sh` prepares these devices by formatting and mounting their respective filesystems.
If no dedicated device is required for some of these four storage components, this step can be skipped or adapted so that only the required devices are processed.

The script supports an arbitrary number of devices, each of which is referred to using a keyword. The device configuration must be saved in the file `config.sh`, which is read by `setup_devices.sh`.
For each device, one entry must be added to the pre-defined bash arrays `DEVS` and `MOUNTPOINT`. For example:

```bash
DEVS[log]=/dev/sda1
DEVS[db]=/dev/sdb1

MOUNTPOINT[log]=/mnt/log
MOUNTPOINT[db]=/mnt/db
```

If no dedicated device is required, thus skipping formatting and mounting and simply using an existing filesystem path, then the corresponding entry must be omitted from the `DEVS` array and the path is defined in `MOUNTPOINT`. For example, to use a dedicated log device and store the database in a normal directory:

```bash
DEVS[log]=/dev/sda1

MOUNTPOINT[log]=/mnt/log
MOUNTPOINT[db]=/dev/shm/zero/db
```

This works because the formatting happens in a loop over the `DEVS` array. An additional array `USE_BTRFS` can be defined to mount a filesystem as btrfs.
This is supported natively by our scripts because snapshots can be managed more efficienty in btrfs (see [Managing snapshots](#managing-snapshots) below).

The script must be run as root, and it verifies, for each filesystem being mounted, if it already exists before proceeding -- if that's the case, the user is prompted for a confirmation. To ignore this prompt, the argument `--force` can be passed.

Once the `config.sh` file is created (a [sample one](./config.sh) is provided with the repository, the script can be invoked with:

```
sudo ./setup_devices.sh
```

## Loading data

## Managing snapshots

## Running experiments

## Processing results
