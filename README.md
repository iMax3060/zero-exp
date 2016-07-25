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

Furthermore, a variable `MOUNTOPTS` must be defined for the mount options:

```bash
MOUNTOPTS="noatime,noexec,noauto,nodev,nosuid"
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

Once the `config.sh` file is created (a [sample one](./config.sh) is provided with the repository), the script can be invoked with:

```
sudo ./setup_devices.sh
```

## Data loading and single runs

The script `run_kits.sh` is a simple wrapper over the Kits benchmark suite included with Zero.
It simply invokes it with the given arguments, adding the devices specified in `config.sh` and initialized with `setup_devices.sh` to the command line automatically.
It saves the standard output in the file `out1.txt` and the error output in `out2.txt`.
Furthermore, it produces resource utilization reports using the Linux tools `mpstat` and `iostat` -- these are saved in the files `mpstat.txt` and `iostat.txt`, respectively.

For documentation on the options that can be passed to Kits, see the [Zero repository](https://github.com/caetanosauer/zero). To load data into empty devices, the `--load` option must be given.
The following example loads a TPC-C database with scaling factor 10 and 5 loader threads:

```bash
./run_kits.sh -b tpcc -q 10 -t 5 --load
```

To see the console output, a little bash trick can be used:

```bash
./run_kits.sh -b tpcc -q 10 -t 5 --load &
tail -f out?.txt
```

To disable saving the output to a file and run the benchmark through the GNU debugger (`gdb`), the argument `--debug` can be given, but it *must* be the first argument in the list:

```bash
./run_kits.sh --debug -b tpcc -q 10 -t 5 --load
```

## Managing snapshots

In order to use a common database snapshot for each experiment, our scripts support saving and loading *snapshots* into a pre-determined folder.
This is configured in `config.sh` with the variable `SNAPDIR`:

```bash
SNAPDIR=/mnt/snap
```

After running a benchmark or just loading benchmark data with `run_kits.sh` a snapshot can be created with `save_snapshot.sh` and loaded at a later point in time (erasing the current database state) with `load_snapshot.sh`.
Each snapshot has a name, which corresponds to the folder in which the data is stored in `SNAPDIR`.
To save the data loaded previously in a snapshot named `tpcc-10`, use:

```bash
./save_snapshot.sh tpcc-10
```

Then, let's say we run a 60-second benchmark with 5 threads:

```bash
./run_kits.sh -b tpcc -q 10 -t 5 --duration 60
```

Now, we erase the data (probably saving the output files `out1.txt` and `out2.txt` for later processing) and run the same benchmark again, now with 2 threads:

```bash
./load_snapshot.sh tpcc-10
./run_kits.sh -b tpcc -q 10 -t 2 --duration 60
```

Snapshots can be saved at any point in time and with an arbitrary name. They work by simply preforming `rsync` operations on the directories (or mountpoints) configured in `config.sh`.

## Running experiments

The script `repeat.sh` supports iterating over different configuration inputs for the `run_kits.sh` command. It takes a configuration script as argument, which can be used to perform arbitrary pre- and post-processing actions (usually loading or saving a snapshot and processing log files to collect experiment data).

The configurations through which the script iterates are specified in an associative array `CFG`. For example:

```bash
CFG[buffer-1GB]="--sm_bufpoolsize 1024"
CFG[buffer-5GB]="--sm_bufpoolsize 5120"
CFG[buffer-10GB]="--sm_bufpoolsize 10240"
```

For each element in `CFG`, the `run_kits.sh` command is executed with a base configuration overriden with the arguments specified in that element. To specify the base configuration, a variable `BASE_CFG` must be defined with a path to a configuration file. This can be done in the same script as the `CFG` definition with the `cat` command:

```bash
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
threads=10
queried_sf=10
duration=60
EOF
```

Remember that paths to database and log devices need not be explicitly specified, since the `run_kits.sh` script extracts them from `config.sh`.

To specifiy pre- and post-processing actions, two "hook" functions can be defined: `beforeHook` and `afterHook`. For example:

```bash
function beforeHook()
{
    load_snapshot.sh tpcc-10
    [ $? -eq 0 ] || return 1;
}

function afterHook()
{
    zapps agglog -l ${MOUNTPOINT[log]}/log -t xct_end > agglog.txt
}
```

In this example, the before-hook loads the snapshot called `tpcc-10`; this is done to ensure that each experiment iteration runs on the same initial database. The after-hook uses the `agglog` command of the Zero store manager to extract the number of committed transactions for each second of the experiment by scanning the log. Note that the path to the log is availble in the `MOINTPOINT` array, which is imported automatically by the repeat script.

Once the experiment configuration file is saved, say, in `exp_config.sh`, the repeat script can be invoked with:

```bash
./repeat.sh exp_config.sh
```

For more examples of experiment configuration scripts, see the sub-directories under the `papers` directory.

## Processing results
