#!/bin/bash

# Script to cleanse a HAMRS generated ADIF file and save it as a POTA and WWFF ADIF file.
# Author: KC0ZPS

CALLSIGN='KC0ZPS'

RED='\033[31m'
GREEN='\033[32m'
ORANGE='\033[38;5;208m'
CYAN='\033[0;36m'
BLUE='\033[34m'
DARKGREY='\033[90m'
WHITE='\033[97m'
NOCOLOR='\033[0m'

PROCESSWWFF=1

declare -a kv_store=()

initialize_keys() {
    set_key US-0023 KFF-0023  # Dry Tortugas National Park
    set_key US-0059 KFF-0059  # RMNP
    set_key US-0244 KFF-0244  # Key West National Wildlife Refuge
    set_key US-1209 KFF-1209  # Barr Lake
    set_key US-1211 KFF-1211  # Castlewood Canyon State Park
    set_key US-1212 KFF-1212  # Chatfield
    set_key US-1213 KFF-1213  # Cherry Creek State Park
    set_key US-1214 KFF-1214  # Cheyenne Mountain State Park
    set_key US-1225 KFF-1225  # Lake Pueblo State Park
    set_key US-1226 KFF-1226  # Lathrop State Park
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

# Calculate run time
calculate_time_diff() {
    local adif_file="$1"

    # Check if the file exists
    if [[ ! -f "$adif_file" ]]; then
        echo "File not found: $adif_file"
        return 1
    fi

    # Extract TIME_ON fields, sort them, and find the first and last times (case-insensitive)
    local first_time last_time first_timestamp last_timestamp time_diff hours minutes seconds total_contacts cpm

    # Count the total number of contacts (lines with TIME_ON)
    total_contacts=$(grep -iEo '<TIME_ON:[0-9]+>[0-9]+' "$adif_file" | wc -l)

    # Ensure there are contacts
    if [[ $total_contacts -lt 1 ]]; then
        echo "No contacts found in the file."
        return 1
    fi

    first_time=$(grep -iEo '<TIME_ON:[0-9]+>[0-9]+' "$adif_file" | head -n 1 | sed 's/.*>//')
    last_time=$(grep -iEo '<TIME_ON:[0-9]+>[0-9]+' "$adif_file" | tail -n 1 | sed 's/.*>//')

    # Ensure times were found
    if [[ -z "$first_time" || -z "$last_time" ]]; then
        echo "No TIME_ON entries found in the file."
        return 1
    fi

    # Convert the times (HHMMSS) into Unix timestamps (using 1970-01-01 as the date)
    first_timestamp=$(date -j -f "%T" "${first_time:0:2}:${first_time:2:2}:${first_time:4:2}" +%s)
    last_timestamp=$(date -j -f "%T" "${last_time:0:2}:${last_time:2:2}:${last_time:4:2}" +%s)

    # Calculate the time difference in seconds
    time_diff=$((last_timestamp - first_timestamp))

    # Convert seconds into hours, minutes, and seconds
    hours=$((time_diff / 3600))
    minutes=$(( (time_diff % 3600) / 60 ))
    seconds=$((time_diff % 60))

    # Calculate Contacts Per Minute (CPM)
    total_minutes=$((time_diff / 60))
    cpm=$(echo "scale=2; $total_contacts / $total_minutes" | bc)

    # Display the result
    total_contacts=$(trim_leading_spaces "$total_contacts")
    echo "Operating Time: ${hours} hours, ${minutes} minutes, ${seconds} seconds"
    echo "Total contacts: $total_contacts"
    echo "Contacts per minute: $cpm"
}

# Function to trim leading spaces
trim_leading_spaces() {
    echo "$1" | sed 's/^[[:space:]]*//'
}

# Function to count and list unique bands in an ADIF file
count_and_list_unique_bands() {
    local adif_file="$1"

    # Ensure the ADIF file exists
    if [[ ! -f "$adif_file" ]]; then
        echo "Error: ADIF file not found."
        return 1
    fi

    # Extract the bands using grep (case-insensitive) and sed to handle the <BAND> field format
    unique_bands=$(grep -i '\<BAND\>' "$adif_file" | sed -E 's/.*<BAND>([^<]+)<\/BAND>.*/\1/' | sort | uniq)

    # Cleans the <band> from the output
    unique_bands=$(echo "$unique_bands" | sed 's/<band:[234]>//g')

    # Sort the array numerically by removing the 'm' suffix for sorting    
    array=($unique_bands)
    unique_bands=$(printf "%s\n" "${array[@]}" | sort -n -t 'm' -k 1,1)

    # Check if any unique bands were found and print them on a single line
    if [[ -n "$unique_bands" ]]; then
        # Print the total number of unique bands
        total_bands=$(echo "$unique_bands" | wc -l)
        printf "Total Bands: %d\n" "$total_bands"

        printf "Bands: "
        echo "$unique_bands" | tr '\n' ' '  # Replace newlines with spaces
        echo  # Print a newline after the bands
    else
        echo "No bands found in the ADIF file."
    fi
}


# Main function to process input and create output files
function run() {
    if [ -z "$POTA_PARK" ]; then
        echo "No park reference found. Exiting..."
        exit 1
    fi

    # Output files
    POTA_OUTPUT="${CALLSIGN}@${POTA_PARK}-${DATE}.adi"
    WWFF_OUTPUT="${CALLSIGN}@${WWFF_PARK} ${DATE}.adi"

    echo "POTA Output File: $POTA_OUTPUT"

    if [ $PROCESSWWFF -eq 1 ]; then
        echo "WWFF Output File: $WWFF_OUTPUT"
    fi

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
    if [ $PROCESSWWFF -eq 1 ]; then
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
    fi

    # Display counts
    INPUT_COUNT=$(grep -c "call" "$INPUT")
    POTA_OUTPUT_COUNT=$(grep -c "call" "$POTA_OUTPUT")
    if [ $PROCESSWWFF -eq 1 ]; then
        WWFF_OUTPUT_COUNT=$(grep -c "call" "$WWFF_OUTPUT")
    fi

    echo "Input file count: $INPUT_COUNT"
    echo "POTA Output file count: $POTA_OUTPUT_COUNT"
    if [ $PROCESSWWFF -eq 1 ]; then
        echo "WWFF Output file count: $WWFF_OUTPUT_COUNT"
    fi

    echo -= STATS =-
    calculate_time_diff "$POTA_OUTPUT"
    list_adif_states "$POTA_OUTPUT"
    count_and_list_unique_bands "$POTA_OUTPUT"

    # Verify counts
    if [ "$INPUT_COUNT" -ne "$POTA_OUTPUT_COUNT" ]; then
        echo -e "${RED}Error: Count mismatch in POTA file.${NOCOLOR}"
    fi
    if [ $PROCESSWWFF -eq 1 ]; then
        if [ "$INPUT_COUNT" -ne "$WWFF_OUTPUT_COUNT" ]; then
            echo -e "${RED}Error: Count mismatch in WWFF file.${NOCOLOR}"
        fi
    fi
}

if [[ "$1" == "help" ]]; then
    displayHelp
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "$INPUT not found!"
    exit 1
fi

initialize_keys

# Extract the first POTA park reference
POTA_PARK=$(grep -o '<my_sig_info:[78]>[^ ]*' "$INPUT" | head -n 1 | cut -d '>' -f 2)

# No parameter passed in
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

if [ "$1" == "skip" ]; then
    # Skip the processing of a WWFF log
    PROCESSWWFF=0
    echo "Skipping WWFF Processing"
else
    echo -e "POTA:$POTA_PARK = WWFF:$WWFF_PARK"
fi

run

