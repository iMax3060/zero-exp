#!/usr/bin/env python3

import json
import subprocess
import sys
import os
from collections import OrderedDict

verbose = False

def vprint(*args, **kwargs):
    if verbose:
        print("Thread ",  os.getpid(),  ": ", *args, **kwargs)

class ExperimentsParser():

    def __init__(self, experimentFilename, useVerbose=False):
        global verbose
        verbose = useVerbose
        self.experimentFilename = experimentFilename
        try:
            vprint("Open experiment file: ", self.experimentFilename)
            configFile = open(experimentFilename, "r")
            vprint("Successfully opened experiment file: ", self.experimentFilename)
            vprint("Parse experiment file: ", self.experimentFilename)
            self.config = json.load(configFile)
            vprint("Successfully parsed experiment file: ", self.experimentFilename)
        except ValueError as e:
            print("There is a syntax-error in ", experimentFilename)
            print("For help finding the syntax error, check https://jsonformatter.curiousconcept.com/.")
            sys.stdout.flush()
            print(e.message)
            exit(1)
        finally:
            vprint("Close experiment file: ", self.experimentFilename)
            configFile.close()
            vprint("Successfully closed experiment file: ", self.experimentFilename)

        # Check if mandatory fields are configured:
        vprint("Check if the mandatory fields could be found in ", self.experimentFilename)
        try:
            self.config["partitions"]
            self.config["partitions"]["db"]
            self.config["partitions"]["log"]
            self.config["snapshotDirectory"]
        except KeyError as e:
            if e.args[0] == "partitions":
                print("There are no partitions configured in ", experimentFilename, ".")
                print("")
                self.helpConfig()
                exit(1)
            elif e.args[0] == "db":
                print("There is no db partition configured in ", experimentFilename, ".")
                print("")
                self.helpConfig()
                exit(1)
            elif e.args[0] == "log":
                print("There is no log partition configured in ", experimentFilename, ".")
                print("")
                self.helpConfig()
                exit(1)
            elif e.args[0] == "snapshotDirectory":
                print("There is no snapshotDirectory configured in ", experimentFilename, ".")
                print("")
                self.helpConfig()
                exit(1)

        try:
            self.config["partitions"]["db"]["mountpoint"]
        except KeyError as e:
            if e.args[0] == "mountpoint":
                print("There is no mountpoint of db configured in ", experimentFilename, ".")
                print("")
                self.helpConfig()
                exit(1)

        try:
            self.config["partitions"]["log"]["mountpoint"]
        except KeyError as e:
            if e.args[0] == "mountpoint":
                print("There is no mountpoint of db configured in ", experimentFilename, ".")
                print("")
                self.helpConfig()
                exit(1)

        try:
            self.config["partitions"]["archive"]["mountpoint"]
        except KeyError as e:
            if e.args[0] == "mountpoint":
                print("There is no mountpoint of db configured in ", experimentFilename, ".")
                print("")
                self.helpConfig()
                exit(1)

        try:
            self.config["partitions"]["backup"]["mountpoint"]
        except KeyError as e:
            if e.args[0] == "mountpoint":
                print("There is no mountpoint of db configured in ", experimentFilename, ".")
                print("")
                self.helpConfig()
                exit(1)
        vprint("Successfully checked if the mandatory fields could be found in ", self.experimentFilename)

        # Check if unknown fields are configured:
        vprint("Check if the unknown fields could be found in ", self.experimentFilename)
        partitions = self.getPartitions()
        partitions = list(filter(("db").__ne__, partitions))
        partitions = list(filter(("log").__ne__, partitions))
        partitions = list(filter(("archive").__ne__, partitions))
        partitions = list(filter(("backup").__ne__, partitions))
        if len(partitions) > 0:
            print("The following partitions couldn't be recognized: ", end="")
            print(*partitions, sep=', ')

        options = []
        for key, value in self.config.items():
            options.append(key)
        options = list(filter(("partitions").__ne__, options))
        options = list(filter(("snapshotDirectory").__ne__, options))
        options = list(filter(("mountOptions").__ne__, options))
        if len(options) > 0:
            print("The following parameters couldn't be recognized: ", end="")
            print(*options, sep=', ')
        vprint("Successfully checked if the unknown fields could be found in ", self.experimentFilename)

    def getPartitions(self):
        partitions = []
        for key, value in self.config["partitions"].items():
            partitions.append(key)
        partitions.sort()
        return partitions

    def getPartition(self, partitionName):
        return self.config["partitions"][partitionName]

    def getMountpoint(self, partitionName):
        return self.config["partitions"][partitionName]["mountpoint"]

    def getDevice(self, partitionName):
        try:
            return self.config["partitions"][partitionName]["device"]
        except KeyError as e:
            return ""

    def getUseBTRFS(self, partitionName):
        try:
            return self.config["partitions"][partitionName]["useBTRFS"]
        except KeyError as e:
            return False

    def getNumOfPartitions(self):
        return len(self.config["partitions"])

    def getSnapshotDirectory(self):
        return self.config["snapshotDirectory"]

    def getNumOfMountOptions(self):
        try:
            return len(self.config["mountOptions"])
        except KeyError as e:
            return 0

    def getMountOptions(self):
        try:
            return sorted(self.config["mountOptions"])
        except KeyError as e:
            return []

    def getMountOption(self, index):
        return sorted(self.config["mountOptions"])[index]

    def printConfig(self):
        for partition in self.getPartitions():
            print("{}:".format(partition))
            print("    mountpoint = {}".format(self.getMountpoint(partition)))
            print("    device = {}".format(self.getDevice(partition)))
            print("    useBTRFS = {}".format(self.getUseBTRFS(partition)))
        print("snapshotDirectory = {}".format(self.getSnapshotDirectory()))
        if self.getNumOfMountOptions() > 0:
            print('mountoptions = "', end='')
            print(*self.getMountOptions(), sep=',', end='')
            print('"')

    def helpConfig(self):
        print("example of a valid ", self.experimentFilename, ":")
        try:
            rows, columns = subprocess.check_output(['stty', 'size'], stderr=subprocess.DEVNULL).split()
        except:
            columns = 80
        print("#" * columns)
        print('{\n  "partitions": {\n    "log": {\n      "device": "/dev/sdc1",\n      "mountpoint": "/mnt/ssd0",\n      "useBTRFS": true\n    },\n    "db": {\n      "device": "/dev/sdd1",\n      "mountpoint": "/mnt/ssd1",\n      "useBTRFS": true\n    },\n    "archive": {\n      "device": "/dev/sda1",\n      "mountpoint": "/mnt/hdd0",\n      "useBTRFS": false\n    },\n    "backup": {\n      "device": "/dev/sdb1",\n      "mountpoint": "/mnt/hdd1",\n      "useBTRFS": false\n    }\n  },\n  "snapshotDirectory": "~/snapshots",\n  "_comment": {\n    "mountOptions": [\n      "noatime",\n      "noexec",\n      "noauto",\n      "nodev",\n      "nosuid"\n    ]\n  }\n}')
        print("#" * columns)
        print("")
        print("mandatory parameters:")

        mandatoryParameters = OrderedDict()
        mandatoryParameters['"partitions"'] = "Definition of locations where different data of zapps kits are stored."
        mandatoryParameters['"db"'] = "The file where the database file (--sm_dbfile) is stored."
        mandatoryParameters['"log"'] = "The directory where the log directory (--sm_logdir) is stored."
        mandatoryParameters['"mountpoint"'] = "The directory to store data (or where setup_devices.py mounts the \"device\")."
        mandatoryParameters['"snapshotDirectory"'] = "The directory where the script save_snapshot.py saves snapshots and where the scripts load_snapshot.py and repeat.py loads snapshots from."
        for key, value in mandatoryParameters.items():
            print("{:<20} {:<}".format(key, value))
        print("")
        print("optional parameters:")
        optionalParameters = OrderedDict()
        optionalParameters['"archive"'] = "The directory where the log archive directory (--sm_archdir) is stored."
        optionalParameters['"backup"'] = "The directory where the backup directory (--sm_backup_dir) is stored."
        optionalParameters['"device"'] = "The partition that is used to store data on (used by setup_devices.py)."
        optionalParameters['"useBTRFS"'] = "If the partition should be formatted using BTRFS instead of ext3 (used by setup_devices.py)."
        optionalParameters['"mountOptions"'] = "Mount options used by setup_devices.py."
        for key, value in optionalParameters.items():
            print("{:<20} {:<}".format(key, value))

def test():
    config = ConfigParser(useVerbose=True)
    config.printConfig()

if __name__ == '__main__':
    test()

