#!/bin/bash

# Script to cleanse a HAMRS generated ADIF file and save it as a POTA and WWFF ADIF file.
# Author: KC0ZPS

RED='\033[31m'
GREEN='\033[32m'
ORANGE='\033[38;5;208m'
CYAN='\033[0;36m'
BLUE='\033[34m'
DARKGREY='\033[90m'
WHITE='\033[97m'
NOCOLOR='\033[0m'

declare -a kv_store=()

initialize_keys() {
    set_key US-0059 KFF-0059  # RMNP
    set_key US-1209 KFF-1209  # Barr Lake
    set_key US-1212 KFF-1212  # Chatfield
    set_key US-1213 KFF-1213  # Cherry Creek State Park
    set_key US-1214 KFF-1214  # Cheyenne Mountain State Park
    set_key US-1241 KFF-1241  # St. Vrain
    set_key US-2355 KFF-2355  # Wilson State Park
    set_key US-3373 NIL-0000  # Chimney Rock National Historic Site (no WWFF)
    set_key US-5661 NIL-0000  # Bridgeport State Recreation Area (no WWFF)

}

# Function to set or update a key-value pair
set_key() {
    local key="$1"
    local value="$2"
    local found=0

    # Update the value if the key already exists
    for i in "${!kv_store[@]}"; do
        if [[ "${kv_store[$i]}" == "$key="* ]]; then
            kv_store[$i]="$key=$value"
            found=1
            break
        fi
    done

    # If the key doesn't exist, add a new entry
    if [[ $found -eq 0 ]]; then
        kv_store+=("$key=$value")
    fi
}

# Function to get the value for a given key
get_key() {
    local key="$1"
    for pair in "${kv_store[@]}"; do
        if [[ "$pair" == "$key="* ]]; then
            echo "${pair#*=}" # Extract and print the value
            return
        fi
    done
    echo "null"
}

# Function to delete a key-value pair
delete_key() {
    local key="$1"
    for i in "${!kv_store[@]}"; do
        if [[ "${kv_store[$i]}" == "$key="* ]]; then
            unset kv_store[$i]
            kv_store=("${kv_store[@]}") # Rebuild array to remove gaps
            echo "Key deleted."
            return
        fi
    done
    echo "Key not found."
}

# Function to list all key-value pairs
list_keys() {
    for pair in "${kv_store[@]}"; do
        echo "$pair"
    done
}

BASH_SCRIPT_FILENAME=$(basename "$0")
INPUT="input.adi"
DATE=$(date +"%Y%m%d")
WWFF_PARK=$1

# Function to display help
function displayHelp() {

    clear
    echo "$BASH_SCRIPT_FILENAME"
    echo ""
    echo -e "${ORANGE}NAME${NOCOLOR}"
    echo "     ./$BASH_SCRIPT_FILENAME – Creates a cleansed POTA and WWFF file from a hamrs adif file."
    echo ""
    echo -e "${ORANGE}SYNOPSIS${NOCOLOR}"
    echo "     ./$BASH_SCRIPT_FILENAME"
    echo "     ./$BASH_SCRIPT_FILENAME <WWFF Park Reference>"
    echo "     ./$BASH_SCRIPT_FILENAME skip"
    echo "     ./$BASH_SCRIPT_FILENAME help"
    echo ""
    echo -e "${ORANGE}DESCRIPTION${NOCOLOR}"
    echo "     Input file: $INPUT"
    echo ""
    echo "     This script cleanses POTA and WWFF files by adding specific metadata."
    echo "     - Adds MY_POTA_REF:<POTA_PARK> to POTA comments."
    echo "     - Adds MY_WWFF_REF:<WWFF_PARK>, my_sig, and my_sig_info to WWFF comments."
    echo ""
    echo "     If no parameter is passed in, then the script will attempt to process the WWFF file"
    echo "     by an internal lookup."
    echo ""
    echo "     If a text other than the below is passed in, then the script will process the WWFF file"
    echo "     using this text as the WWFF identifier.  KFF-1212, for example"
    echo ""
    echo -e "     ${ORANGE}skip${NOCOLOR}                     Do not process a WWFF file."
    echo -e "     ${ORANGE}help${NOCOLOR}                     Display the help message."
}

# Function to check and delete existing files
function checkAndDeleteFile() {
    local file=$1
    if [ -f "$file" ]; then
        echo -e "${RED}$file exists. Deleting...${NOCOLOR}"
        rm "$file"
    fi
}

# Function to extract and list unique states from an ADIF log
list_adif_states() {
    local adif_file="$1"

    if [[ ! -f "$adif_file" ]]; then
        echo "Error: File '$adif_file' not found."
        return 1
    fi

    # List of all U.S. states (abbreviations)
    local all_states=(
        AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN
        MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA
        WA WV WI WY
    )

    # Extract unique contacted states from the ADIF file
    local contacted_states=($(grep -oi '<state:[0-9]*>[^<]*' "$adif_file" | \
                              sed -E 's/<state:[0-9]+>//I' | \
                              sort | uniq))

    # Prepare the output for all states
    local output=""
    local state_count=0

    output+="  "
    for state in "${all_states[@]}"; do
        if [[ "$state" == "MO" ]]; then
            output+=$(echo -e "${WHITE}MO${NOCOLOR}\n\r  ")
        elif [[ " ${contacted_states[@]} " =~ " ${state} " ]]; then
            # State contacted: display in blue
            output+=$(echo -e "${WHITE}$state${NOCOLOR} ")
            state_count=$((state_count + 1))
        else
            # State not contacted: display in dark gray
            output+=$(echo -e "${DARKGREY}$state${NOCOLOR} ")
        fi

    done

    # Print the output on a single line
    echo -e "$state_count U.S. States"
    echo -e "$output"

    return 0
}

# Main function to process input and create output files
function run() {
    if [ ! -f "$INPUT" ]; then
        echo "$INPUT not found!"
        exit 1
    fi

    if [ -z "$POTA_PARK" ]; then
        echo "No park reference found. Exiting..."
        exit 1
    fi

    # Output files
    POTA_OUTPUT="KC0ZPS@${POTA_PARK}-${DATE}.adi"
    WWFF_OUTPUT="KC0ZPS@${WWFF_PARK} ${DATE}.adi"

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

    list_adif_states "$POTA_OUTPUT"

    echo "Input file count: $INPUT_COUNT"
    echo "POTA Output file count: $POTA_OUTPUT_COUNT"
    echo "WWFF Output file count: $WWFF_OUTPUT_COUNT"

    # Verify counts
    if [ "$INPUT_COUNT" -ne "$POTA_OUTPUT_COUNT" ]; then
        echo -e "${RED}Error: Count mismatch in POTA file.${NOCOLOR}"
    fi
    if [ "$INPUT_COUNT" -ne "$WWFF_OUTPUT_COUNT" ]; then
        echo -e "${RED}Error: Count mismatch in WWFF file.${NOCOLOR}"
    fi
}

if [[ "$1" == "help" ]]; then
    displayHelp
    exit 1
fi

initialize_keys

# Extract the first POTA park reference
POTA_PARK=$(grep -o '<my_sig_info:7>[^ ]*' "$INPUT" | head -n 1 | cut -d '>' -f 2)

if [ -z "$1" ]; then
    if [ -z "$POTA_PARK" ]; then
        echo "No park reference found. Exiting..."
        exit 1
    fi

    WWFF_PARK=$(get_key $POTA_PARK)
    if [[ "$WWFF_PARK" == "null" ]]; then
        echo -e "${RED}The POTA lookup found no WWFF reference.${NOCOLOR}"
        exit 1
    fi
fi

echo -e "${GREEN}POTA:$POTA_PARK = WWFF:$WWFF_PARK${NOCOLOR}"

run

