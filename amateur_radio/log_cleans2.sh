#!/bin/bash

# KC0ZPS@US-1212-20241212.adi
# KC0ZPS@PARK-YYYYMMDD.adi

# M0YMA-P @ GFF-0354 20191209.ADI
# KC0ZPS @ PARK 20191209.adi
BASH_SCRIPT_FILENAME=$(basename "$0")
INPUT='input.adi'
DATE=$(date +"%Y%m%d")
WWFF_PARK=$1

function displayHelp() {
    CYAN='\033[0;36m'
    NOCOLOR='\033[0m'

    clear
    echo "$BASH_SCRIPT_FILENAME"
    echo ""
    echo -e "${CYAN}NAME${NOCOLOR}"
    echo "     ./$BASH_SCRIPT_FILENAME – Creates a cleansed POTA and WWFF file from a hamrs adif file."
    echo ""
    echo -e "${CYAN}SYNOPSIS${NOCOLOR}"
    echo "     ./$BASH_SCRIPT_FILENAME <WWFF Park Reference>"
    echo ""
    echo -e "${CYAN}DESCRIPTION${NOCOLOR}"
    echo "     This script will create a cleansed POTA and WWFF file from a hamrs adif file. It will currently:"
    echo "     - Add MY_POTA_REF:<POTA_PARK> in the comments section of the POTA adif file."
    echo "     - Add MY_WWFF_REF:<WWFF_PARK> in the comments section of the WWFF adif file."
    echo "     - Add <my_sig:4>WWFF to the WWFF adif file"
    echo "     - Add <my_sig_info:xx>PARK_REFERENCE to the WWFF adif file"
    echo ""
    echo "     Input file is $INPUT"
}

function run() {
    if [ ! -f $INPUT ]; then
        echo "$INPUT not found!"
        exit 1
    fi

    # Extract the first instance of the park reference.
    POTA_PARK=$(grep -o '<my_sig_info:7>[^ ]*' "$INPUT" | head -n 1 | cut -d '>' -f 2)
       
    # Check if found
    if [ -z "$POTA_PARK" ]; then
        echo "No park reference found. Exiting..."
        exit 1
    fi
    echo "POTA Park: $POTA_PARK"
    echo "WWFF Park: $WWFF_PARK"

    POTA_OUTPUT="KC0ZPS@${POTA_PARK}-${DATE}.adi"
    echo "POTA Output File: $POTA_OUTPUT"

    WWFF_OUTPUT="KC0ZPS @ ${WWFF_PARK} ${DATE}.adi"
    echo "WWFF Output File: $WWFF_OUTPUT"

    # Check if the POTA output file exists. Delete if it does.
    if test -f $POTA_OUTPUT; then
        echo -e "\033[31m$POTA_OUTPUT exists. Deleting...\033[0m"
        rm "$POTA_OUTPUT"
    fi

    # Check if the WWFF output file exists. Delete if it does.
    if test -f "$WWFF_OUTPUT"; then
        echo -e "\033[31m$WWFF_OUTPUT exists. Deleting...\033[0m"
        rm -f "$WWFF_OUTPUT"
    fi

    # Process POTA
    while read p; do 
        if [[ $p == *"comment"* ]]; then
            temp_str="MY_POTA_REF:$POTA_PARK"
            temp_length=${#temp_str}
            echo "<comment:$temp_length>$temp_str" >> "$POTA_OUTPUT"
            continue
        fi

        echo "$p" >> "$POTA_OUTPUT"
    done < "$INPUT"
    echo Done processing POTA

    # Process WWFF
    wwff_var_length=${#WWFF_PARK}
    while read p; do
        if [[ $p == *"<my_sig:"* ]]; then            
            echo "<my_sig:4>WWFF" >> "$WWFF_OUTPUT"
            continue
        fi 

        if [[ $p == *"<my_sig_info:"* ]]; then
            echo "<my_sig_info:$wwff_var_length>$WWFF_PARK" >> "$WWFF_OUTPUT"
            continue
        fi 

        if [[ $p == *"comment"* ]]; then
            temp_str="MY_WWFF_REF:$WWFF_PARK"
            temp_length=${#temp_str}
            echo "<comment:$temp_length>$temp_str" >> "$WWFF_OUTPUT"
            continue
        fi

        echo "$p" >> "$WWFF_OUTPUT"
    done < "$INPUT"
    echo Done processing WWFF

    # Display the counts
    INPUT_COUNT=`more input.adi | grep call | wc -l`
    POTA_OUTPUT_COUNT=`more "$POTA_OUTPUT" | grep call | wc -l`
    WWFF_OUTPUT_COUNT=`more "$WWFF_OUTPUT" | grep call | wc -l`

    echo "Input file count: $INPUT_COUNT" | xargs
    echo "POTA Output file count: $POTA_OUTPUT_COUNT" | xargs
    echo "WWFF Output file count: $WWFF_OUTPUT_COUNT" | xargs

    # Compare the counts
    if [ "$INPUT_COUNT" -ne "$POTA_OUTPUT_COUNT" ]; then
        echo -e "\033[31mError: count does not match in the POTA file.\033[0m"
    fi
    if [ "$INPUT_COUNT" -ne "$WWFF_OUTPUT_COUNT" ]; then
        echo -e "\033[31mError: count does not match in the WWFF file.\033[0m"
    fi

}

if [ -z "$1" ]; then
    displayHelp 
    exit 1
fi

echo Start

run


