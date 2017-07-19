#!/usr/bin/env python3

import argparse
import sys

sys.argv = ["./repeat.py", "--sm_bufpoolsize", "1024", "--load", "--sm_shutdown_clean", "1", "--config", "_baseconfig.conf", "--debug"]

parser = argparse.ArgumentParser()
parser.add_argument("-c", "--config", action="store", required=False)
configFileName, sys.argv = parser.parse_known_args()
baseconfig = []
if configFileName.config is not None:
    with open(configFileName.config) as configFile:
        for config in configFile.read().splitlines():
            if config.find("=") != -1:
                baseconfig.extend(["--" + config.partition("=")[::2][0], config.partition("=")[::2][1]])
sys.argv.extend(baseconfig)

parser = argparse.ArgumentParser(prog="runKits.py", description="Runs zapps kits of the Zero Storage Manager.")
parser.add_argument("-d", "--debug", action="store_true", help="Run zapps kits in GDB.")
parser.add_argument("-v", "--verbose", action="store_true",
                    help="Activate verbose mode where much diagnostic information is printed.")
parser.add_argument("-b", "--benchmark", action="store",
                    help="Activate verbose mode where much diagnostic information is printed.", required=True)
parser.add_argument("zapps kits arguments", nargs='?',
                    help="Other arguments used by zapps kits (see zapps kits --help for more information).")
runKitsArgs = parser.parse_known_args(sys.argv)[0]
runKitsArgs = vars(runKitsArgs)
runKitsArgs.pop("zapps kits arguments", None)

# The following is a hack used to show the [zapps kits arguments] is usage/help but not to miss any of the
# arguments for zapps kits:
parser = argparse.ArgumentParser()
parser.add_argument("-d", "--debug", action="store_true")
parser.add_argument("-v", "--verbose", action="store_true")
parser.add_argument("-b", "--benchmark", action="store", required=True)
zappsArgs = parser.parse_known_args(sys.argv)[1]

print(baseconfig, runKitsArgs, zappsArgs)

# parser = argparse.ArgumentParser(prog='PROG')
# parser.add_argument('--foo')
# #parser.add_argument('command')
# parser.add_argument('args', nargs=argparse.REMAINDER)
# print(parser.parse_args('--foo B cmd --arg1 XX ZZ'.split()))
