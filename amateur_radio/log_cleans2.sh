#!/bin/bash

# Script to cleanse POTA and WWFF ADIF files
# Author: KC0ZPS

BASH_SCRIPT_FILENAME=$(basename "$0")
INPUT="input.adi"
DATE=$(date +"%Y%m%d")
WWFF_PARK=$1

# Function to display help
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
    echo "     This script cleanses POTA and WWFF files by adding specific metadata."
    echo "     - Adds MY_POTA_REF:<POTA_PARK> to POTA comments."
    echo "     - Adds MY_WWFF_REF:<WWFF_PARK>, my_sig, and my_sig_info to WWFF comments."
    echo "     Input file: $INPUT"
}

# Function to check and delete existing files
function checkAndDeleteFile() {
    local file=$1
    if [ -f "$file" ]; then
        echo -e "\033[31m$file exists. Deleting...\033[0m"
        rm "$file"
    fi
}

# Main function to process input and create output files
function run() {
    if [ ! -f "$INPUT" ]; then
        echo "$INPUT not found!"
        exit 1
    fi

    # Extract the first POTA park reference
    POTA_PARK=$(grep -o '<my_sig_info:7>[^ ]*' "$INPUT" | head -n 1 | cut -d '>' -f 2)

    if [ -z "$POTA_PARK" ]; then
        echo "No park reference found. Exiting..."
        exit 1
    fi

    echo "POTA Park: $POTA_PARK"
    echo "WWFF Park: $WWFF_PARK"

    POTA_OUTPUT="KC0ZPS@${POTA_PARK}-${DATE}.adi"
    WWFF_OUTPUT="KC0ZPS @ ${WWFF_PARK} ${DATE}.adi"

    echo "POTA Output File: $POTA_OUTPUT"
    echo "WWFF Output File: $WWFF_OUTPUT"

    checkAndDeleteFile "$POTA_OUTPUT"
    checkAndDeleteFile "$WWFF_OUTPUT"

    # Process POTA
    while read -r line; do 
        if [[ $line == *"comment"* ]]; then
            comment="MY_POTA_REF:$POTA_PARK"
            echo "<comment:${#comment}>$comment" >> "$POTA_OUTPUT"
        else
            echo "$line" >> "$POTA_OUTPUT"
        fi
    done < "$INPUT"
    echo "Done processing POTA."

    # Process WWFF
    while read -r line; do
        case $line in
            *"<my_sig:"*)
                echo "<my_sig:4>WWFF" >> "$WWFF_OUTPUT";;
            *"<my_sig_info:"*)
                echo "<my_sig_info:${#WWFF_PARK}>$WWFF_PARK" >> "$WWFF_OUTPUT";;
            *"comment"*)
                comment="MY_WWFF_REF:$WWFF_PARK"
                echo "<comment:${#comment}>$comment" >> "$WWFF_OUTPUT";;
            *)
                echo "$line" >> "$WWFF_OUTPUT";;
        esac
    done < "$INPUT"
    echo "Done processing WWFF."

    # Display counts
    INPUT_COUNT=$(grep -c "call" "$INPUT")
    POTA_OUTPUT_COUNT=$(grep -c "call" "$POTA_OUTPUT")
    WWFF_OUTPUT_COUNT=$(grep -c "call" "$WWFF_OUTPUT")

    echo "Input file count: $INPUT_COUNT"
    echo "POTA Output file count: $POTA_OUTPUT_COUNT"
    echo "WWFF Output file count: $WWFF_OUTPUT_COUNT"

    # Verify counts
    if [ "$INPUT_COUNT" -ne "$POTA_OUTPUT_COUNT" ]; then
        echo -e "\033[31mError: Count mismatch in POTA file.\033[0m"
    fi
    if [ "$INPUT_COUNT" -ne "$WWFF_OUTPUT_COUNT" ]; then
        echo -e "\033[31mError: Count mismatch in WWFF file.\033[0m"
    fi
}

if [ -z "$1" ]; then
    displayHelp
    exit 1
fi

echo "Start"
run

