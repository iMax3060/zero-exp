import os
import sys
import re
import textwrap

from prettytable import PrettyTable

def which(program):
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None

def eprint(*args, **kwargs):
    print(*args, **kwargs, file=sys.stderr)
    sys.stderr.flush()

def extractQuotedSubstring(string, index = 1):
    try:
        return re.search(".*'(.+)'.*", string).group(index)
    except IndexError as e:
        return None

def formatHeading(heading, width):
    splitHeading = textwrap.wrap(heading, width - 4)
    formattedHeading = "#" * width + "\n"
    for headingLine in splitHeading:
        lineHashes = width - 2 - len(headingLine)
        beforeHashes = int(lineHashes / 2) if lineHashes % 2 == 0 else int(lineHashes / 2 + 1)
        afterHashes = int(lineHashes / 2)
        formattedHeading = formattedHeading + "#" * beforeHashes + " " + headingLine + " " + "#" * afterHashes + "\n"
    formattedHeading = formattedHeading + "#" * width
    return formattedHeading

def boxText(text, width):
    boxedText = "#" * width + "\n"
    for line in text.split("\n"):
        if len(line) > width - 4:
            lines = textwrap.wrap(line, width=width-4)
            print(lines)
            for line in lines:
                boxedText += "# " + line + " " * (width - len(line) - 4) + " #\n"
        else:
            boxedText += "# " + line + " " * (width - len(line) - 4) + " #\n"
    boxedText += "#" * width
    return boxedText

def formatFile(fileText, maxWidth):
    maxFileWidth = maxWidth - 4
    formattedFile = []
    for fileLine in fileText.split("\n"):
        if len(fileLine) > maxFileWidth:
            newFileLines = [fileLine[i:i + maxFileWidth] for i in range(0, len(fileLine), maxFileWidth)]
            for newFileLine in newFileLines:
                formattedFile.append(newFileLine + " " * (maxFileWidth - len(newFileLine)))
        else:
            formattedFile.append(fileLine + " " * (maxFileWidth - len(fileLine)))
    return boxText("\n".join(formattedFile), maxWidth)


def formatKeyValueDictionary(dict, maxWidth):
    formattedTable = ""
    table = PrettyTable(border=False, header=False, hrules=False, vrules=False)
    maxKeyWidth = len(max(dict.keys(), key=len)) + 1
    if maxKeyWidth * 2 > maxWidth:
        for key, value in dict.items():
            thisKey = "\b" + "\n\b".join(textwrap.wrap(key, width=int(maxWidth/2)-1))
            thisValue = "\b" + "\n\b".join(textwrap.wrap(value, width=maxWidth-int(maxWidth/2)))
            table.add_row([thisKey, thisValue])
    else:
        for key, value in dict.items():
            thisKey = "\b" + key
            thisValue = "\b" + "\n\b".join(textwrap.wrap(value, width=maxWidth-maxKeyWidth))
            table.add_row([thisKey, thisValue])
    table.align = "l"
    table = table.get_string()
    for tableLine in table.split("\n"):
        formattedTable += tableLine.rstrip() + "\n"
    return formattedTable.replace(" \b", "")