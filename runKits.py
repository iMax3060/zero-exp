#!/usr/bin/env python3

import os
import signal
import subprocess
import threading
import argparse
import sys
import gettext
from functions import which, eprint
from configParser import ConfigParser

de = gettext.translation("runKits", localedir="locale", languages=["de"])
de.install()

verbose = False

def vprint(*args, **kwargs):
    if verbose:
        print("Thread " + str(os.getpid()) + ": ", *args, **kwargs)
        sys.stdout.flush()

class BackgroundThread(threading.Thread):
    def __init__(self, backgroundCommand, backgroundParameters, backgroundFilename):
        threading.Thread.__init__(self)
        self.backgroundCommand = backgroundCommand + " " + " ".join(backgroundParameters)
        self.backgroundFilename = backgroundFilename
        self.createdFiles = []
        self.background = None

    def run(self):
        vprint(_("Successfully spawned thread %s to run the command: %s") % (os.getpid(), self.backgroundCommand.split(" ")[0]))
        try:
            vprint(_("Open file: %s") % self.backgroundFilename)
            self.createdFiles.append(self.backgroundFilename)
            backgroundFile = open(self.backgroundFilename, "w")
            vprint(_("Successfully opened file: %s") % self.backgroundFilename)

            try:
                vprint(_("Spawn a new subprocess to run the shell command: %s") % self.backgroundCommand)
                self.background = subprocess.Popen(self.backgroundCommand, stdout=backgroundFile,
                                                   stderr=subprocess.DEVNULL, shell=True, preexec_fn=os.setsid)
                vprint(_("Successfully spawned subprocess %s to run the shell command: %s") % (self.background.pid, self.backgroundCommand))
                self.background.wait()

            finally:
                self.exit()

        finally:
            vprint(_("Flush file: %s") % self.backgroundFilename)
            backgroundFile.flush()
            vprint(_("Successfully flushed file: %s") % self.backgroundFilename)
            vprint(_("Close file: %s") % self.backgroundFilename)
            backgroundFile.close()
            vprint(_("Successfully closed file: %s") % self.backgroundFilename)
        vprint(_("Terminated thread %s to run the command: %s") % (os.getpid(), self.backgroundCommand.split(" ")[0]))

    def exit(self):
        if self.background is not None:
            vprint(_("Kill subprocess %s") % self.background.pid)
            os.killpg(os.getpgid(self.background.pid), signal.SIGTERM)
            vprint(_("Killed subprocess %s") % self.background.pid)
            self.background = None

    def getFilesList(self):
        return self.createdFiles

class BenchmarkRun():

    def __init__(self, benchmark, zappsCommand="zapps", zappsParameters=None, zappsStdoutFilename="out1.txt",
                 zappsStderrFilename="out2.txt",
                 debugActivate=False, debugCommand="gdb", debugParameters=None,
                 iostatActivate=True, iostatCommand="iostat", iostatParameters=None, iostatFilename="iostat.txt",
                 mpstatActivate=True, mpstatCommand="mpstat", mpstatParameters=None, mpstatFilename="mpstat.txt",
                 configFilename="config.json"):
        if zappsParameters is None:
            zappsParameters = []
        if iostatActivate and iostatParameters is None:
            iostatParameters = ["-d", "-m", "-t", "-x", "1"]
        if mpstatActivate and mpstatParameters is None:
            mpstatParameters = ["1"]
        if debugParameters is None:
            debugParameters = []
        self.benchmark = benchmark
        self.zappsCommand = zappsCommand
        self.zappsParameters = zappsParameters
        self.zappsStdoutFilename = zappsStdoutFilename
        self.zappsStderrFilename = zappsStderrFilename
        self.debugActivate = debugActivate
        self.debugCommand = debugCommand
        self.debugParameters = debugParameters
        self.debugParameters.extend(["-ex", "run", "--args"])
        if self.debugActivate:
            self.zappsStdoutFilename = ""
            self.zappsStderrFilename = ""
        self.iostatActivate = iostatActivate
        self.iostatCommand = iostatCommand
        self.iostatParameters = iostatParameters
        self.iostatFilename = iostatFilename
        self.mpstatActivate = mpstatActivate
        self.mpstatCommand = mpstatCommand
        self.mpstatParameters = mpstatParameters
        self.mpstatFilename = mpstatFilename
        self.configFilename = configFilename
        self.createdFiles = []

        if which(zappsCommand) is None:
            eprint(_("Command not found: %s") % zappsCommand)
            sys.exit(127)
        else:
            vprint(_("Located command %s at %s.") % (zappsCommand, which(zappsCommand)))

        if iostatActivate and which(iostatCommand) is None:
            eprint(_("Command not found: %s") % iostatCommand)
            sys.exit(127)
        else:
            vprint(_("Located command %s at %s.") % (iostatCommand, which(iostatCommand)))
        if mpstatActivate and which(mpstatCommand) is None:
            eprint(_("Command not found: %s") % mpstatCommand)
            sys.exit(127)
        else:
            vprint(_("Located command %s at %s.") % (mpstatCommand, which(mpstatCommand)))

    def runBenchmark(self):
        config = ConfigParser(self.configFilename, verbose)

        zappsCommand = []
        if self.debugActivate:
            zappsCommand.extend([self.debugCommand])
            zappsCommand.extend(self.debugParameters)
        zappsCommand.extend([self.zappsCommand, "kits"])
        for partition in config.getPartitions():
            if partition == "db":
                zappsCommand.extend(["--sm_dbfile", config.getMountpoint("db") + "/db"])
            elif partition == "log":
                zappsCommand.extend(["--sm_logdir", config.getMountpoint("log") + "/log"])
            elif partition == "archive":
                zappsCommand.extend(["--sm_archdir", config.getMountpoint("archive") + "/archive"])
            elif partition == "backup":
                zappsCommand.extend(["--sm_backup_dir", config.getMountpoint("backup") + "/backup"])
        zappsCommand.extend(["--benchmark", self.benchmark])
        zappsCommand.extend(self.zappsParameters)

        try:
            if self.zappsStdoutFilename != "":
                vprint(_("Open file: %s") % self.zappsStdoutFilename)
                self.createdFiles.append(self.zappsStdoutFilename)
                zappsStdoutFile = open(self.zappsStdoutFilename, "w")
                vprint(_("Successfully opened file: %s") % self.zappsStdoutFilename)
            else:
                zappsStdoutFile = None
            try:
                if self.zappsStderrFilename != "":
                    vprint(_("Open file: %s") % self.zappsStderrFilename)
                    self.createdFiles.append(self.zappsStderrFilename)
                    zappsStderrFile = open(self.zappsStderrFilename, "w")
                    vprint(_("Successfully opened file: %s") % self.zappsStderrFilename)
                else:
                    zappsStderrFile = None

                try:
                    if self.iostatActivate:
                        iostat = BackgroundThread(self.iostatCommand, self.iostatParameters, self.iostatFilename)
                        iostat.setName("iostatThread")
                        iostat.start()
                    try:
                        if self.mpstatActivate:
                            mpstat = BackgroundThread(self.mpstatCommand, self.mpstatParameters, self.mpstatFilename)
                            mpstat.setName("mpstatThread")
                            mpstat.start()

                        try:
                            vprint(_("Run zapps kits using the following command:\n%s") % " ".join(zappsCommand))
                            vprint(_("Spawn a new subprocess to run the command: %s") % zappsCommand)
                            zapps = subprocess.run(zappsCommand, stdout=zappsStdoutFile, stderr=zappsStderrFile, check=True)
                            vprint(_("The subprocess terminated that ran the command: %s") % zappsCommand)
                        except subprocess.CalledProcessError as e:
                            eprint(e.output)
                            sys.exit(e.returncode)

                    finally:
                        if self.mpstatActivate:
                            mpstat.exit()
                            mpstat.join()
                            self.createdFiles.extend(mpstat.getFilesList())
                finally:
                    if self.iostatActivate:
                        iostat.exit()
                        iostat.join()
                        self.createdFiles.extend(iostat.getFilesList())

            finally:
                if self.zappsStderrFilename != "":
                    vprint(_("Flush file: %s") % self.zappsStderrFilename)
                    zappsStderrFile.flush()
                    vprint(_("Successfully flushed file: %s") % self.zappsStderrFilename)
                    vprint(_("Close file: %s") % self.zappsStderrFilename)
                    zappsStderrFile.close()
                    vprint(_("Successfully closed file: %s") % self.zappsStderrFilename)
                else:
                    sys.stderr.flush()
        finally:
            if self.zappsStdoutFilename != "":
                vprint(_("Flush file: %s") % self.zappsStdoutFilename)
                zappsStdoutFile.flush()
                vprint(_("Successfully flushed file: %s") % self.zappsStdoutFilename)
                vprint(_("Close file: %s") % self.zappsStdoutFilename)
                zappsStdoutFile.close()
                vprint(_("Successfully closed file: %s") % self.zappsStdoutFilename)
            else:
                sys.stdout.flush()

        vprint(_("Created the following files:\n%s") % ", ".join(self.createdFiles))

    def getFilesList(self):
        return self.createdFiles

def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("-c", "--config", action="store", required=False)
    configFileName, sys.argv = parser.parse_known_args()
    baseconfig = []
    if configFileName.config is not None:
        with open(configFileName.config) as configFile:
            for config in configFile.read().splitlines():
                if config.find("=") != -1:
                    baseconfig.extend(["--" + config.partition("=")[::2][0], config.partition("=")[::2][1]])
    sys.argv.extend(baseconfig)

    parser = argparse.ArgumentParser(prog="runKits.py", description=_("Runs zapps kits of the Zero Storage Manager."))
    parser.add_argument("-d", "--debug", action="store_true", help=_("Run zapps kits in GDB."))
    parser.add_argument("-v", "--verbose", action="store_true",
                        help=_("Activate verbose mode where much diagnostic information is printed."))
    parser.add_argument("-b", "--benchmark", action="store",
                        help=_("The benchmark that gets executed by zapps kits."), required=True)
    parser.add_argument("zapps kits arguments", nargs='?',
                        help=_("Other arguments used by zapps kits (see zapps kits --help for more information)."))
    runKitsArgs = parser.parse_known_args(sys.argv)[0]
    runKitsArgs = vars(runKitsArgs)
    runKitsArgs.pop("zapps kits arguments", None)

    # The following is a hack used to show the [zapps kits arguments] is usage/help but not to miss any of the
    # arguments for zapps kits:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("-d", "--debug", action="store_true")
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("-b", "--benchmark", action="store", required=True)
    zappsArgs = parser.parse_known_args(sys.argv)[1]

    global verbose
    verbose = runKitsArgs["verbose"]

    run = BenchmarkRun(benchmark=runKitsArgs["benchmark"], zappsParameters=zappsArgs, debugActivate=runKitsArgs["debug"])
    run.runBenchmark()

if __name__ == '__main__':
    main()
