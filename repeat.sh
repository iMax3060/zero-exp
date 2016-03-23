#!/bin/bash

RUN_CMD=./run_kits.sh

function die() { echo >&2 "$@"; exit 1; }

# $1 = directory prefix
function findFirstFree() {
    local LATEST=1
    while [ -e "$1""$LATEST" ]; do
        let LATEST=$LATEST+1
    done
    echo "$1""$LATEST"
}

function functionExists() {
    declare -f -F $1 > /dev/null
    return $?
}

function usage()
{
cat << EOF
usage: $0 [options] <experiment-file>

Available options are:
  --iterations <n>
    Run n iterations of the experiment
  --outdir <dir>
    Directory in which the results will be saved
  --run-missing
    Iterate over output directory and re-run experiment for any missing
    or failed configuration
  --versioning
    Saves mercurial revisions and diff
  --help
    Shows this message
  
  'experiment-file' is a file that will be passed to each benchmark run
  as the experiment properties file. The intended values for the experiment
  variable will be appended to it.
  
EOF
}

################
# GETOPT CONFIG
################

OPTSPEC=`getopt -o i:,o:,m --long iterations:,outdir:,help,run-missing \
    -n 'repeat.sh' -- "$@"`

if [ $? != 0 ] ; then usage ; fi

# Note the quotes around `$OPTSPEC': they are essential!
eval set -- "$OPTSPEC"

# Default values
ITERATIONS=1
RUN_MISSING=0
OUTDIR=""

while true; do
    case "$1" in
        -i | --iterations )
            echo "Iterations = $2"
            ITERATIONS=$2
            shift 2 ;;
        -o | --outdir )
            OUTDIR=$2
            shift 2 ;;
        -m | --run-missing )
            RUN_MISSING=1
            shift ;;
        --help )
            usage
            exit 1 ;;
        -- ) shift; break ;;
        * ) break ;;
    esac
done

[ $# -eq 1 ] || die "Required argument: source file"
EXP_SOURCE=$1
EXP_NAME=$(basename ${EXP_SOURCE%.*})
[ -f $EXP_SOURCE ] || die "File not found: $EXP_SOURCE"
shift

[ -n "$OUTDIR" ] || OUTDIR=$HOME/zero-results/$EXP_NAME

source $EXP_SOURCE

[[ -v CFG[@] ]] || die "Global variable CFG must be defined"

function runOnce()
{
    local config=$1

    echo -n "Running config $config ... "

    # execute before hook
    if functionExists beforeHook; then
        beforeHook 1> out1_before.txt 2> out2_before.txt
        RC=$?
        if [ $RC -ne 0 ]; then
            echo "ERROR on before hook!"
            return $RC
        fi
    fi

    # execute actual experiment
    ARGS=${CFG[$config]}
    if [ -f $BASE_CFG ]; then
        ARGS="--config $BASE_CFG $ARGS"
    fi

    $RUN_CMD $ARGS
    RC=$?
    if [[ $RC != 0 ]]; then
        touch $DEST/_FAILED
        echo "ERROR on experiment run!"
        return $RC
    fi

    # execute after hook
    if functionExists afterHook; then
        afterHook 1> out1_after.txt 2> out2_after.txt
        RC=$?
        if [ $RC -ne 0 ]; then
            echo "ERROR on after hook!"
            return $RC
        fi
    fi

    # Finally, if everything worked fine, produce sucessful result
    echo "OK"
    return 0
}

if (($RUN_MISSING)); then
    for r in $OUTDIR/rep*; do
        for v in ${!CFG[@]}; do
            if [ -f $r/$v/_SUCCESS ]; then
                continue
            fi

            runOnce $v
            RC=$?
            mkdir -p $r/$v
            mv *.txt $r/$v/

            # one single run failure causes repeat script to fail too
            if [[ $RC != 0 ]]; then
                exit $RC
            fi
        done
    done
else
    for j in `seq 1 $ITERATIONS`; do
        echo "==== Iteration $j of $ITERATIONS ===="
        REPDIR=$(findFirstFree $OUTDIR/rep)
        for v in ${!CFG[@]}; do
            runOnce $v
            RC=$?

            mkdir -p $REPDIR/$v
            mv *.txt $REPDIR/$v/
            if [[ $RC == 0 ]]; then
                touch $REPDIR/$v/_SUCCESS
            fi
        done
    done
fi
