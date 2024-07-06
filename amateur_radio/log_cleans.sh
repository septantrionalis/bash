#!/bin/bash

INPUT='input.adi'

# Generates help text if parameters are missing.
# Date is auto generated from current day, but may not match the file.
# Park is generated from the my_sig_info segment of the input.adi file if it exists.
function displayHelp() {
    CYAN='\033[0;36m'
    NOCOLOR='\033[0m'

    INPUT='input.adi'

    if test -f $INPUT; then
        PARK=`more input.adi | grep my_sig_info | head -n 1 | cut -d ">" -f2`
    else
        PARK="US-1209"
    fi
    dt=$(date '+%Y%m%d');
    clear
    echo "replace.sh"
    echo ""
    echo -e "${CYAN}NAME${NOCOLOR}"
    echo "     ./replace.sh – Cleanse an adif file produced from hamrs."
    echo ""
    echo -e "${CYAN}SYNOPSIS${NOCOLOR}"
    echo "     ./replace.sh $PARK KC0ZPS@$PARK-$dt.adi"
    echo ""
    echo -e "${CYAN}DESCRIPTION${NOCOLOR}"
    echo "     This script will cleanse an ADI file produced from hamrs. It will currently:"
    echo "     - Add MY_POTA_REF:<PARK> in the comments section of the adif file."
    echo ""
    echo "     Input file is input.adi"
}

if [ -z "$1" ]; then
    displayHelp
    exit 1
fi

if [ -z "$2" ]; then
    displayHelp
    exit 1
fi

if [ ! -f $INPUT ]; then
    echo "$INPUT not found!"
    exit 1
fi

echo "Park: $1"
echo "Output: $2"

PARK=$1
OUTPUT=$2

echo Start

if test -f $OUTPUT; then
  echo "$OUTPUT exists. Aborting."
  exit 1
fi

while read p; do 
    if [[ $p == *"comment"* ]]; then
        echo "<comment:19>MY_POTA_REF:$PARK " >> "$OUTPUT"
    else
        echo "$p" >> "$OUTPUT"
    fi
done < "$INPUT"
echo Done

INPUT_COUNT=`more input.adi | grep call | wc -l`
OUTPUT_COUNT=`more "$OUTPUT" | grep call | wc -l`

echo "Input file count: $INPUT_COUNT" | xargs
echo "Output file count: $OUTPUT_COUNT" | xargs

