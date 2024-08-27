#!/bin/bash

USAGE=$(cat <<EOF

Usage: $0 [-l] [-m <model def file>] [-h]

Options:
  -m    Model definition file
  -l    Perform liveness check
  -f    Enable fairness
  -a    acceptance check
  -h    Help
  -v    Verbose

Examples:
  $0 -m sample.pml
  $0 -l -m sample.pml
  $0 -h

EOF
)


usage() {
    echo "$USAGE"
}

mf=""
checkLiveness=0
verbose=0
fairness=0
acceptance=0

while getopts ":m:lfavh" opt; do
    case $opt in
        m)
            mf="$OPTARG"
            ;;
        l)
            checkLiveness=1
            ;;
        f)
            fairness=1
            ;;
        a)
            acceptance=1
            ;;
        h)
            usage
            exit 0
            ;;
        v)
            verbose=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

compileOptions=""
panOptions=""

if [[ $checkLiveness -eq 1 ]]; then
    compileOptions="-DNP"
    panOptions="-l"
fi

if [[ $fairness -eq 1 ]]; then
    panOptions="$panOptions -f"
fi

if [[ $acceptance -eq 1 ]]; then
    panOptions="$panOptions -a"
fi

if grep -qE "never|accept" "$mf"; then
    # never claim + accept labels requires -a flag to fully verify
    panOptions="$panOptions -a"
fi


if [[ $verbose -eq 1 ]]; then
    set -x
fi

spin -a "$mf"
cc $compileOptions -o pan pan.c
./pan $panOptions
spin -p -t "$mf"
