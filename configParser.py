#!/usr/bin/env python3

import json
import subprocess
import sys
import os
import gettext
from collections import OrderedDict
from jsonschema import SchemaError, Draft4Validator
from functions import eprint, extractQuotedSubstring, formatKeyValueDictionary, formatHeading, formatFile, boxText

verbose = False

def vprint(*args, **kwargs):
    if verbose:
        print("Thread " + str(os.getpid()) + ": ", *args, **kwargs)
        sys.stdout.flush()

de = gettext.translation("configParser", localedir="locale", languages=["de"])
de.install()

class ConfigParser():

    configSchemaFilename = "configurationsSchema.json"

    def __init__(self, configFilename="config.json", useVerbose=False):
        global verbose
        verbose = useVerbose
        self.configFilename = configFilename

        try:
            vprint(_("Open configuration schema file: {configSchemaFilename}").format(**{"configSchemaFilename": self.configSchemaFilename}))
            configSchemaFile = open(self.configSchemaFilename, "r")
            vprint(_("successfully opened configuration schema file: {configSchemaFilename}").format(**{"configSchemaFilename": self.configSchemaFilename}))
            vprint(_("Parse configuration schema file: {configSchemaFilename}").format(**{"configSchemaFilename": self.configSchemaFilename}))
            configSchema = json.load(configSchemaFile)
            vprint(_("Successfully parsed configuration schema file: {configSchemaFilename}").format(**{"configSchemaFilename": self.configSchemaFilename}))
            vprint(_("Verify validity of configuration schema file: {configSchemaFilename}").format(**{"configSchemaFilename": self.configSchemaFilename}))
            configSchemaValidator = Draft4Validator(configSchema)
            Draft4Validator.check_schema(configSchema)
            vprint(_("Verified validity of configuration schema file: {configSchemaFilename}").format(**{"configSchemaFilename": self.configSchemaFilename}))

            try:
                vprint(_("Open configuration file: {configFilename}").format(**{"configFilename": self.configFilename}))
                configFile = open(configFilename, "r")
                vprint(_("Successfully opened configuration file: {configFilename}").format(**{"configFilename": self.configFilename}))
                vprint(_("Parse configuration file: {configFilename}").format(**{"configFilename": self.configFilename}))
                self.config = json.load(configFile)
                vprint(_("Successfully parsed configuration file: {configFilename}").format(**{"configFilename": self.configFilename}))
                vprint(_("Check the validity of the configuration file: {configFilename}").format(**{"configFilename": self.configFilename}))
                for validationError in sorted(configSchemaValidator.iter_errors(self.config), key=str):
                    if validationError.validator == "required":
                        if "partitions" in validationError.validator_value and extractQuotedSubstring(validationError.message) == "partitions":
                            eprint(_("There are no partitions configured in {configFilename}.").format(**{"configFilename": self.configFilename}))
                        elif "mountpoint" in validationError.validator_value and extractQuotedSubstring(validationError.message) == "mountpoint":
                            eprint(_("There is no mountpoint of the partition {partitionName} configured in {configFilename}.").format(**{"partitionName": validationError.path.pop(), "configFilename": self.configFilename}))
                    elif validationError.validator == "additionalProperties":
                        if validationError.validator_value == False:
                            if len(validationError.path) > 0:
                                parent = validationError.path.pop()
                                if parent == "partitions":
                                    eprint(_("The partition {partitionName} configured in {configFilename} is not known.").format(**{"partitionName": extractQuotedSubstring(validationError.message), "configFilename": self.configFilename}))
                                elif parent in ["db", "log", "archive", "backup"]:
                                    eprint(_("The partition configuration field {fieldName} configured in {configFilename} is not a known.").format(**{"fieldName": extractQuotedSubstring(validationError.message), "configFilename": self.configFilename}))
                            else:
                                eprint(_("The field {fieldName} configured in {configFilename} is not known.").format(**{"fieldName": extractQuotedSubstring(validationError.message), "configFilename": self.configFilename}))
                    elif validationError.validator == "type":
                        valueType = validationError.message.split(" is not of type ")
                        path = validationError.path.pop()
                        while len(validationError.path) > 0:
                            path = path + _(" under ") + validationError.path.pop()
                        eprint(_("The value {value} at {path} configured in {configFilename} is not of type {type}.").format(**{"value": valueType[0], "path": path, "configFilename": self.configFilename, "type": valueType[1].replace("'", "")}))
                    else:
                        eprint(_("Unknown error in {configFilename}: {errorMessage}").format(**{"configFilename": self.configFilename, "errorMessage": validationError.message}))
                if not configSchemaValidator.is_valid(self.config):
                    self.helpConfig()
                    vprint(_("Exit program due to an invalid configuration file."))
                    exit(1)
                vprint(_("Successfully checked the validity of the configuration file: {configFilename}").format(**{"configFilename": self.configFilename}))

            except FileNotFoundError as e:
                eprint(_("The configuration file {configFilename} could not be found.").format(**{"configFilename": self.configFilename}))
                vprint(_("Exit program as the configuration file does not exist."))
                exit(1)
            except ValueError as e:
                eprint(_("There is a syntax-error in {configFilename}.").format(**{"configFilename": self.configFilename}))
                eprint(_("For help finding the syntax error, check https://jsonformatter.curiousconcept.com/."))
                eprint(e.message)
                vprint(_("Exit program due to a syntax error in the configuration file."))
                exit(1)
            finally:
                vprint(_("Close configuration file: {configFilename}").format(**{"configFilename": self.configFilename}))
                configFile.close()
                vprint(_("Successfully closed configuration file: {configFilename}").format(**{"configFilename": self.configFilename}))
        except FileNotFoundError as e:
            eprint(_("The configuration schema file {configSchemaFilename} could not be found.").format(**{"configSchemaFilename": self.configSchemaFilename}))
            vprint(_("Exit program as the configuration schema file does not exist."))
            exit(1)
        except ValueError as e:
            eprint(_("There is a syntax-error in {configSchemaFilename}.").format(**{"configSchemaFilename": self.configSchemaFilename}))
            eprint(_("You are not supposed to change this file. Please restore the original version provived with this package."))
            eprint(e.message)
            vprint(_("Exit program due to a syntax error in the configuration schema file."))
            exit(1)
        except SchemaError as e:
            eprint(_("There is a syntax-error in {configSchemaFilename}.").format(**{"configSchemaFilename": self.configSchemaFilename}))
            eprint(_("You are not supposed to change this file. Please restore the original version provived with this package."))
            eprint(e.message)
            vprint(_("Exit program due to a syntax error in the configuration schema file."))
            exit(1)
        finally:
            vprint(_("Close configuration schema file: {configSchemaFilename}").format(**{"configSchemaFilename": self.configSchemaFilename}))
            configSchemaFile.close()
            vprint(_("Successfully closed configuration schema file: {configSchemaFilename}").format(**{"configSchemaFilename": self.configSchemaFilename}))

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

    def currentConfig(self):
        try:
            rows, columns = subprocess.check_output(['stty', 'size'], stderr=subprocess.DEVNULL).split()
        except:
            columns = 80
        formattedConfig = ""
        for partition in self.getPartitions():
            formattedConfig += "{}:".format(partition) + "\n"
            formattedConfig += "    mountpoint = {}".format(os.path.abspath(self.getMountpoint(partition))) + "\n"
            formattedConfig += "    device = {}".format(os.path.abspath(self.getDevice(partition))) + "\n"
            formattedConfig += "    useBTRFS = {}".format("true" if self.getUseBTRFS(partition) else "false") + "\n"
        formattedConfig += "snapshotDirectory = {}".format(os.path.abspath(self.getSnapshotDirectory())) + "\n"
        if self.getNumOfMountOptions() > 0:
            formattedConfig += "mountoptions = \"" + ",".join(self.getMountOptions()) + "\""
        formattedConfig = formatFile(formattedConfig, columns)
        formattedConfig = formatHeading(_("Current Configuration:"),
                                        columns) + "\n\n" + formattedConfig
        return formattedConfig

    def helpConfig(self):
        try:
            rows, columns = subprocess.check_output(['stty', 'size'], stderr=subprocess.DEVNULL).split()
        except:
            columns = 80
        print(formatHeading(_("Example of a valid configuration file:"), columns) + "\n")
        print(formatFile('{\n  "partitions": {\n    "log": {\n      "device": "/dev/sdc1",\n      "mountpoint": "/mnt/ssd0",\n      "useBTRFS": true\n    },\n    "db": {\n      "device": "/dev/sdd1",\n      "mountpoint": "/mnt/ssd1",\n      "useBTRFS": true\n    },\n    "archive": {\n      "device": "/dev/sda1",\n      "mountpoint": "/mnt/hdd0",\n      "useBTRFS": false\n    },\n    "backup": {\n      "device": "/dev/sdb1",\n      "mountpoint": "/mnt/hdd1",\n      "useBTRFS": false\n    }\n  },\n  "snapshotDirectory": "~/snapshots",\n  "_comment": {\n    "mountOptions": [\n      "noatime",\n      "noexec",\n      "noauto",\n      "nodev",\n      "nosuid"\n    ]\n  }\n}', maxWidth=columns))
        print("")

        mandatoryParameters = OrderedDict()
        mandatoryParameters['"partitions"'] = _("Definition of locations where different data of zapps kits are stored.")
        mandatoryParameters['"mountpoint"'] = _("The directory to store data (or where setup_devices.py mounts the \"device\").")
        optionalParameters = OrderedDict()
        optionalParameters['"db"'] = _("The file where the database file (--sm_dbfile) is stored.")
        optionalParameters['"log"'] = _("The directory where the log directory (--sm_logdir) is stored.")
        optionalParameters['"archive"'] = _("The directory where the log archive directory (--sm_archdir) is stored.")
        optionalParameters['"backup"'] = _("The directory where the backup directory (--sm_backup_dir) is stored.")
        optionalParameters['"device"'] = _("The partition that is used to store data on (used by setup_devices.py).")
        optionalParameters['"useBTRFS"'] = _("If the partition should be formatted using BTRFS instead of ext3 (used by setup_devices.py).")
        optionalParameters['"snapshotDirectory"'] = _("The directory where the script save_snapshot.py saves snapshots and where the scripts load_snapshot.py and repeat.py loads snapshots from.")
        optionalParameters['"mountOptions"'] = _("Mount options used by setup_devices.py.")

        helpText = ""
        helpText += _("Mandatory Parameters:") + "\n"
        helpText += formatKeyValueDictionary(mandatoryParameters, columns - 4) + "\n"
        helpText += "\n" + _("Optional Parameters:") + "\n"
        helpText += formatKeyValueDictionary(optionalParameters, columns - 4) + "\n"

        print(boxText(helpText, columns))

        sys.stdout.flush()

def test():
    config = ConfigParser(useVerbose=True)
    config.helpConfig()

if __name__ == '__main__':
    test()

