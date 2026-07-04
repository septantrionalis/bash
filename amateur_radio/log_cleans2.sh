#!/bin/bash

# Script to cleanse a HAMRS generated ADIF file and save it as a POTA and WWFF ADIF file.
# Author: KC0ZPS
#
# Updated:
# - Prints the callsign/QSO causing required-field count mismatches.
# - Fixes quoted filename handling when output filenames contain spaces.
# - Keeps validation non-fatal for count mismatches unless you uncomment exit 1 in verify_counts.

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

CALL_KEY="<CALL:"
EOR_KEY="<EOR"
COMMENT_KEY="<COMMENT:"
MY_SIG_KEY="<MY_SIG:"
MY_SIG_INFO_KEY="<MY_SIG_INFO:"
RST_RCVD_KEY="<RST_RCVD:"
RST_SENT_KEY="<RST_SENT:"
OPERATOR_KEY="<OPERATOR:"
GRIDSQUARE_KEY="<GRIDSQUARE:"
MYGRIDSQUARE_KEY="<MY_GRIDSQUARE:"
BAND_KEY="<BAND:"
FREQ_KEY="<FREQ:"
TIMEON_KEY="<TIME_ON:"
QSODATE_KEY="<QSO_DATE:"
MODE_KEY="<MODE:"
TXPOWER_KEY="<TX_PWR:"
MYPOTAREF_KEY="<MY_POTA_REF:"
NAME_KEY="<NAME:"
QTH_KEY="<QTH:"
STATE_KEY="<STATE:"
COUNTY_KEY="<CNTY:"
COUNTRY_KEY="<COUNTRY:"
MYSTATE_KEY="<MY_STATE:"

initialize_keys() {
    set_key US-0023 KFF-0023  # Dry Tortugas National Park
    set_key US-0033 KFF-0033  # Great Sand Dunes National Park
    set_key US-0059 KFF-0059  # RMNP
    set_key US-0068 KFF-0068  # Wind Cave National Park
    set_key US-0183 NIL-0000  # Penrose Commons National Recreation Area
    set_key US-0184 NIL-0000  # Ramah State Wildlife Area
    set_key US-0185 NIL-0000  # Hugo State Wildlife Area
    set_key US-0188 KFF-0188  # Kinney Lake State Wildlife Area
    set_key US-0191 NIL-0000  # Brush Hollow State Wildlife Area
    set_key US-0192 KFF-0192  # Beaver Creek State Wildlife Area
    set_key US-0225 KFF-0225  # Rocky Flats National Wildlife Refuge
    set_key US-0226 KFF-0226  # Rocky Mountain Arsenal National Wildlife Refuge
    set_key US-0240 KFF-0240  # Great White Heron National Wildlife Refuge
    set_key US-0244 KFF-0244  # Key West National Wildlife Refuge
    set_key US-0250 KFF-0250  # National Key Deer National Wildlife Refuge
    set_key US-0786 KFF-0786  # Mount Rushmore National Memorial
    set_key US-0801 KFF-0801  # Bent's Old Fort National Historic Site
    set_key US-0817 KFF-0817  # Fort Laramie National Historic Site
    set_key US-0861 KFF-0861  # Sand Creek Massacre National Historic Site
    set_key US-0925 KFF-0925  # Florissant Fossil Beds National Monument
    set_key US-1007 KFF-1007  # Lincoln Trail State Park
    set_key US-0190 NIL-0000  # Flagler Reservoir State Wildlife Area
    set_key US-1208 KFF-1208  # Arkansas River Headwaters Recreation Park
    set_key US-1209 KFF-1209  # Barr Lake
    set_key US-1210 KFF-1210  # Boyd Lake State Park
    set_key US-1211 KFF-1211  # Castlewood Canyon State Park
    set_key US-1212 KFF-1212  # Chatfield
    set_key US-1213 KFF-1213  # Cherry Creek State Park
    set_key US-1214 KFF-1214  # Cheyenne Mountain State Park
    set_key US-1221 KFF-1221  # Highline Lake State Park
    set_key US-1222 KFF-1222  # Jackson Lake State Park
    set_key US-1224 KFF-1224  # John Martin Reservoir State Park
    set_key US-1225 KFF-1225  # Lake Pueblo State Park
    set_key US-1226 KFF-1226  # Lathrop State Park
    set_key US-1228 KFF-1228  # Lory State Park
    set_key US-1230 KFF-1230  # Mueller State Park
    set_key US-1232 KFF-1232  # North Sterling State Park
    set_key US-1240 KFF-1240  # Spinney Mountain State Park
    set_key US-1241 KFF-1241  # St. Vrain
    set_key US-1244 KFF-1244  # Staunton State Park
    set_key US-1248 KFF-1248  # Trinidad Lake State Park
    set_key US-2256 KFF-2256  # Fort Harrison State Park
    set_key US-2267 KFF-2267  # Shades State Park
    set_key US-2272 KFF-2272  # Turkey Run State Park
    set_key US-2274 KFF-2274  # White River State Park
    set_key US-2355 KFF-2355  # Wilson State Park
    set_key US-3295 KFF-3295  # Curt Gowdy State Park
    set_key US-3298 KFF-3298  # Guernsey State Park
    set_key US-3373 NIL-0000  # Chimney Rock National Historic Site (no WWFF)
    set_key US-3620 KFF-3620  # Florida Keys Overseas Heritage Trail State Park
    set_key US-3623 KFF-3623  # Fort Zachary Taylor State Park
    set_key US-4404 KFF-4404  # Pike National Forest
    set_key US-4406 KFF-4406  # Roosevelt National Forest
    set_key US-4410 KFF-4410  # White River National Forest
    set_key US-4411 KFF-4411  # Browns Canyon National Monument
    set_key US-4524 KFF-4531  # Black Hills National Forest
    set_key US-5661 NIL-0000  # Bridgeport State Recreation Area (no WWFF)
    set_key US-5749 NIL-0000  # Kokopelli's Trail National Recreation Area
    set_key US-6114 NIL-0000  # Oregon Trail Ruts State Historic Site
    set_key US-6115 NIL-0000  # Historic Governors' Mansion State Historic Site
    set_key US-6303 KFF-5245  # Florida Keys Wildlife Area
    set_key US-6478 KFF-6371  # Maple Leaf Lake State Conservation Area
    set_key US-7491 KFF-4547  # Comanche National Grassland
    set_key US-7845 KFF-6818  # Fisher's Peak
    set_key US-8195 NIL-0000  # Spearfish Canyon Nature Recreation Area
    set_key US-8295 NIL-0000  # Great Sand Dunes National Preserve
    set_key US-8296 NIL-0000  # Karval Reservoir State Wildlife Area
    set_key US-9595 KFF-4959  # McInnis Canyons BLM National Conservation Area
    set_key US-9601 KFF-7203  # 63 Ranch State Wildlife Area
    set_key US-9603 NIL-0000  # Adobe Creek State Wildlife Area
    set_key US-9605 NIL-0000  # Alma State Wildlife Area
    set_key US-9607 KFF-7169  # Apishapa State Wildlife Area
    set_key US-9613 NIL-0000  # Bergen Peak State Wildlife Area
    set_key US-9623 NIL-0000  # Bravo State Wildlife Area
    set_key US-9626 NIL-0000  # Brush State Wildlife Area
    set_key US-9627 NIL-0000  # Burchfield State Wildlife Area
    set_key US-9629 NIL-0000  # Cherokee State Wildlife Area
    set_key US-9636 NIL-0000  # Cottonwood State Wildlife Area
    set_key US-9639 NIL-0000  # Deadman State Wildlife Area
    set_key US-9644 NIL-0000  # Dowdy Lake State Wildlife Area
    set_key US-9646 NIL-0000  # Duck Creek State Wildlife Area
    set_key US-9649 NIL-0000  # Fort Lyon State Wildlife Area
    set_key US-9651 NIL-0000  # Frenchman Creek State Wildlife Area
    set_key US-9652 NIL-0000  # Grenada State Wildlife Area
    set_key US-9655 NIL-0000  # Holbrook Reservoir State Wildlife Area
    set_key US-9656 NIL-0000  # Holyoke State Wildlife Area
    set_key US-9657 NIL-0000  # Horse Creek Reservoir State Wildlife Area
    set_key US-9663 NIL-0000  # Pony Express State Wildlife Area
    set_key US-9664 NIL-0000  # Prewitt Reservoir State Wildlife Area
    set_key US-9665 NIL-0000  # Queens State Wildlife Area
    set_key US-9668 NIL-0000  # Sand Draw State Wildlife Area
    set_key US-9669 NIL-0000  # Sawhill Ponds State Wildlife Area
    set_key US-9670 NIL-0000  # Sedgwick Bar State Wildlife Area
    set_key US-9673 NIL-0000  # Timpas Creek State Wildlife Area
    set_key US-9675 NIL-0000  # Two Buttes State Wildlife Area
    set_key US-9683 NIL-0000  # Amache National Historic Site
    set_key US-10247 NIL-0000 # Lawrence Creek State Nature Preserve
    set_key US-10533 NIL-0000 # Watson Lake State Wildlife Area
    set_key US-10540 NIL-0000 # Bellevue-Watson State Fish Hatchery
    set_key US-11891 NIL-0000 # Tilman Bishop State Wildlife Area
    set_key US-11897 NIL-0000 # Beaver Creek BLM Wilderness Area
    set_key US-11899 NIL-0000 # South Republican State Wildlife Area
    set_key US-11920 NIL-0000 # Mount Evans State Wildlife Area
    set_key US-11923 NIL-0000 # Sharptail Ridge State Wildlife Area
    set_key US-11924 NIL-0000 # Douglas Reservoir State Wildlife Area
    set_key US-11926 NIL-0000 # Lon Hagler State Wildlife Area
    set_key US-11938 NIL-0000 # Parvin Lake State Wildlife Area
    set_key US-11939 NIL-0000 # Poudre River State Wildlife Area
    set_key US-11940 NIL-0000 # Simpsons Pond State Wildlife Area
    set_key US-11941 NIL-0000 # Smith Lake State Wildlife Area
    set_key US-12138 NIL-0000 # Charlie Meyers State Wildlife Area
    set_key US-12139 NIL-0000 # Cline Ranch State Wildlife Area
    set_key US-12140 NIL-0000 # Spinney Mountain State Wildlife Area
    set_key US-12170 NIL-0000 # Teter-Michigan Creek State Wildlife Area
    set_key US-12176 NIL-0000 # Frank State Wildlife Area
    set_key US-12178 NIL-0000 # Atwood State Wildlife Area
    set_key US-12181 KFF-7171 # Banner Lakes State Wildlife Area
    set_key US-12188 NIL-0000 # Brush Prairie Ponds State Wildlife Area
    set_key US-12354 NIL-0000 # Red Lion State Wildlife Area
    set_key US-12355 NIL-0000 # Jumbo Reservoir State Wildlife Area
    set_key US-12455 NIL-0000 # Mt. Shavano State Fish Hatchery
    set_key US-12456 NIL-0000 # Stalker Lake State Wildlife Area
    set_key US-12585 NIL-0000 # Elliot State Wildlife Area
    set_key US-12586 NIL-0000 # Jean K Tool State Wildlife Area
    set_key US-12587 NIL-0000 # Andrick Ponds State Wildlife Area
    set_key US-12755 NIL-0000 # Sandsage State Wildlife Area
    set_key BM-0020 NIL-0000  # Somerset Long Bay Park
    set_key US-0899 KFF-0899  # African Burial Ground National Monument

    set_key US-12171 NIL-0000 # Tomahawk State Wildlife Area
    set_key US-12172 NIL-0000 # James Mark Jones State Wildlife Area 
    set_key US-1217 KFF-1217  # Eleven Mile State Park
    set_key US-9612 NIL-0000  # Bellaire Lake State Wildlife Area 
    set_key US-10828 NIL-0000 # Quebec 01 Missile Alert Facility State Park
    

}

# Function to set or update a key-value pair
set_key() {
    local key="$1"
    local value="$2"
    local found=0

    for i in "${!kv_store[@]}"; do
        if [[ "${kv_store[$i]}" == "$key="* ]]; then
            kv_store[$i]="$key=$value"
            found=1
            break
        fi
    done

    if [[ $found -eq 0 ]]; then
        kv_store+=("$key=$value")
    fi
}

# Function to get the value for a given key
get_key() {
    local key="$1"
    for pair in "${kv_store[@]}"; do
        if [[ "$pair" == "$key="* ]]; then
            echo "${pair#*=}"
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
            kv_store=("${kv_store[@]}")
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
    echo "     If text other than the below is passed in, then the script will process the WWFF file"
    echo "     using this text as the WWFF identifier. KFF-1212, for example."
    echo ""
    echo -e "     ${ORANGE}skip${NOCOLOR}                     Do not process a WWFF file."
    echo -e "     ${ORANGE}help${NOCOLOR}                     Display the help message."
}

# Function to check and delete existing files
function checkAndDeleteFile() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "${RED}$file exists. Deleting...${NOCOLOR}"
        rm "$file"
    fi
}

# Function to extract callsign from a QSO record
extract_call_from_record() {
    local record="$1"
    local call="UNKNOWN"

    if [[ "$record" =~ \<CALL:[0-9]+\>([^[:space:]<]+) ]]; then
        call="${BASH_REMATCH[1]}"
    fi

    echo "$call"
}

# Function to list callsigns/QSOs that are missing a required field.
# This checks per QSO record, not just raw line counts.
list_calls_missing_field() {
    local FILE="$1"
    local FIELD="$2"

    local record=""
    local qso_number=0
    local missing_count=0
    local call="UNKNOWN"

    while IFS= read -r line || [[ -n "$line" ]]; do
        record+="$line"$'\n'

        if [[ "$line" == *"$EOR_KEY"* ]]; then
            ((qso_number++))

            if [[ "$record" != *"$FIELD"* ]]; then
                call=$(extract_call_from_record "$record")
                echo -e "   ${RED}QSO #$qso_number, callsign: $call is missing $FIELD${NOCOLOR}"
                ((missing_count++))
            fi

            record=""
        fi
    done < "$FILE"

    # Handles a final record if the file does not end with <EOR>
    if [[ -n "$record" ]]; then
        ((qso_number++))
        if [[ "$record" != *"$FIELD"* ]]; then
            call=$(extract_call_from_record "$record")
            echo -e "   ${RED}QSO #$qso_number, callsign: $call is missing $FIELD${NOCOLOR}"
            ((missing_count++))
        fi
    fi

    if [[ "$missing_count" -eq 0 ]]; then
        echo "   No specific QSO found missing $FIELD. This may be caused by duplicate fields, malformed records, or field text split unexpectedly."
    fi
}

# Extract and list unique states from an ADIF log
list_adif_states() {
    local adif_file="$1"

    if [[ ! -f "$adif_file" ]]; then
        echo "Error: File '$adif_file' not found."
        return 1
    fi

    local all_states=(
        AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN
        MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA
        WA WV WI WY
    )

    local contacted_states=($(grep -oi '<state:[0-9]*>[^<]*' "$adif_file" | \
                              sed -E 's/<state:[0-9]+>//I' | \
                              sort | uniq))

    local output=""
    local state_count=0

    output+="  "
    for state in "${all_states[@]}"; do
        if [[ "$state" == "MO" ]]; then
            output+=$(echo -e "${WHITE}MO${NOCOLOR}\n\r  ")
        elif [[ " ${contacted_states[@]} " =~ " ${state} " ]]; then
            output+=$(echo -e "${WHITE}$state${NOCOLOR} ")
            state_count=$((state_count + 1))
        else
            output+=$(echo -e "${DARKGREY}$state${NOCOLOR} ")
        fi
    done

    echo -e "$state_count U.S. States"
    echo -e "$output"

    for state in "${contacted_states[@]}"; do
        echo -n "$state:"
        state_count=$(grep -i "<state:2>$state" "$adif_file" | wc -l)
        trimmed="${state_count#"${state_count%%[![:space:]]*}"}"
        echo "$trimmed"
    done

    return 0
}

# Calculate run time
calculate_time_diff() {
    local adif_file="$1"

    if [[ ! -f "$adif_file" ]]; then
        echo "File not found: $adif_file"
        return 1
    fi

    local first_time last_time first_timestamp last_timestamp time_diff hours minutes seconds total_contacts total_minutes cpm

    total_contacts=$(grep -iEo '<TIME_ON:[0-9]+>[0-9]+' "$adif_file" | wc -l)

    if [[ $total_contacts -lt 1 ]]; then
        echo "No contacts found in the file."
        return 1
    fi

    first_time=$(grep -iEo '<TIME_ON:[0-9]+>[0-9]+' "$adif_file" | head -n 1 | sed 's/.*>//')
    last_time=$(grep -iEo '<TIME_ON:[0-9]+>[0-9]+' "$adif_file" | tail -n 1 | sed 's/.*>//')

    if [[ -z "$first_time" || -z "$last_time" ]]; then
        echo "No TIME_ON entries found in the file."
        return 1
    fi

    first_timestamp=$(date -j -f "%T" "${first_time:0:2}:${first_time:2:2}:${first_time:4:2}" +%s)
    last_timestamp=$(date -j -f "%T" "${last_time:0:2}:${last_time:2:2}:${last_time:4:2}" +%s)

    time_diff=$((last_timestamp - first_timestamp))

    hours=$((time_diff / 3600))
    minutes=$(((time_diff % 3600) / 60))
    seconds=$((time_diff % 60))

    total_minutes=$((time_diff / 60))
    if [[ "$total_minutes" -gt 0 ]]; then
        cpm=$(echo "scale=2; $total_contacts / $total_minutes" | bc)
    else
        cpm="N/A"
    fi

    total_contacts=$(trim_leading_spaces "$total_contacts")
    echo "Operating Time: ${hours} hours, ${minutes} minutes, ${seconds} seconds"
    echo "Total contacts: $total_contacts"
    echo "Contacts per minute: $cpm"
}

# Function to trim leading spaces
trim_leading_spaces() {
    echo "$1" | sed 's/^[[:space:]]*//'
}

# Count and list unique bands in an ADIF file
count_and_list_unique_bands() {
    local adif_file="$1"
    local unique_bands total_bands BAND_LIST array

    if [[ ! -f "$adif_file" ]]; then
        echo "Error: ADIF file not found."
        return 1
    fi

    unique_bands=$(grep -i '\<BAND\>' "$adif_file" | sed -E 's/.*<BAND>([^<]+)<\/BAND>.*/\1/' | sort | uniq)
    unique_bands=$(echo "$unique_bands" | sed 's/<band:[234]>//g')

    array=($unique_bands)
    unique_bands=$(printf "%s\n" "${array[@]}" | sort -n -t 'm' -k 1,1)

    if [[ -n "$unique_bands" ]]; then
        total_bands=$(echo "$unique_bands" | wc -l)
        printf "Total Bands: %d\n" "$total_bands"

        BAND_LIST=$(echo "$unique_bands" | tr '\n' ' ')
        BAND_LIST=$(echo "$BAND_LIST" | sed "s/${BAND_KEY}3>//g")
        printf "Bands: "
        echo "$BAND_LIST"
    else
        echo "No bands found in the ADIF file."
    fi
}

# Basic file validation
validate_file() {
    FILE="$1"

    if [[ -z "$FILE" || ! -f "$FILE" ]]; then
        echo "Usage: $0 <filename>"
        exit 1
    fi

    invalid_lines=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -n "$line" && "$line" != \<* ]]; then
            echo "❌ Invalid line: $line"
            ((invalid_lines++))
        fi
    done < "$FILE"

    if [[ "$invalid_lines" -ne 0 ]]; then
        echo "❌ Found $invalid_lines invalid line(s) in $FILE."
        exit 1
    fi

    call_count=$(grep -i "$CALL_KEY" "$FILE" | wc -l)

    count=$(get_field_count "${COMMENT_KEY}19>MY_POTA_REF:" "$FILE")
    if [[ "$count" -eq 0 ]]; then
        count=$(get_field_count "${COMMENT_KEY}20>MY_POTA_REF:" "$FILE")
    fi
    if [[ "$count" -eq 0 ]]; then
        count=$(get_field_count "${COMMENT_KEY}19>MY_WWFF_REF:" "$FILE")
    fi
    if [[ "$count" -eq 0 ]]; then
        count=$(get_field_count "${COMMENT_KEY}20>MY_WWFF_REF:" "$FILE")
    fi
    verify_counts "$CALL_KEY" "$call_count" "$COMMENT_KEY" "$count"

    count=$(get_field_count "$RST_SENT_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$RST_SENT_KEY" "$count"

    count=$(get_field_count "$RST_RCVD_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$RST_RCVD_KEY" "$count"

    count=$(get_field_count "$OPERATOR_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$OPERATOR_KEY" "$count"

    count=$(get_field_count "$GRIDSQUARE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$GRIDSQUARE_KEY" "$count"

    count=$(get_field_count "$MYGRIDSQUARE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MYGRIDSQUARE_KEY" "$count"

    count=$(get_field_count "$MY_SIG_INFO_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MY_SIG_INFO_KEY" "$count"

    count=$(get_field_count "$BAND_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$BAND_KEY" "$count"

    count=$(get_field_count "$FREQ_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$FREQ_KEY" "$count"

    count=$(get_field_count "$TIMEON_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$TIMEON_KEY" "$count"

    count=$(get_field_count "$QSODATE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$QSODATE_KEY" "$count"

    count=$(get_field_count "$MODE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MODE_KEY" "$count"

    count=$(get_field_count "$TXPOWER_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$TXPOWER_KEY" "$count"

    count=$(get_field_count "$MYPOTAREF_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MYPOTAREF_KEY" "$count"

    count=$(get_field_count "$NAME_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$NAME_KEY" "$count"

    # Not all callsigns will have states or counties.
    # count=$(get_field_count "$QTH_KEY" "$FILE")
    # verify_counts "$CALL_KEY" "$call_count" "$QTH_KEY" "$count"

    # count=$(get_field_count "$STATE_KEY" "$FILE")
    # verify_counts "$CALL_KEY" "$call_count" "$STATE_KEY" "$count"

    # count=$(get_field_count "$COUNTY_KEY" "$FILE")
    # verify_counts "$CALL_KEY" "$call_count" "$COUNTY_KEY" "$count"

    count=$(get_field_count "$COUNTRY_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$COUNTRY_KEY" "$count"

    count=$(get_field_count "$MYSTATE_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$MYSTATE_KEY" "$count"

    count=$(get_field_count "$EOR_KEY" "$FILE")
    verify_counts "$CALL_KEY" "$call_count" "$EOR_KEY" "$count"

    verify_brackets "$FILE"

    echo "✅ $FILE seems valid."
}

count_mismatch_error() {
    local FILE="$1"
    local FIELD1="$2"
    local FIELD1COUNT="$3"
    local FIELD2="$4"
    local FIELD2COUNT="$5"

    echo "❌ Mismatch detected in $FILE!"
    echo "\"$FIELD1\" count: $FIELD1COUNT"
    echo "\"$FIELD2\" count: $FIELD2COUNT"
}

get_field_count() {
    local FIELD="$1"
    local FILE="$2"

    grep -i "$FIELD" "$FILE" | wc -l
}

verify_counts() {
    local KEY1="$1"
    local COUNT1="$2"
    local KEY2="$3"
    local COUNT2="$4"

    if [[ "$COUNT1" -ne "$COUNT2" ]]; then
        count_mismatch_error "$FILE" "$KEY1" "$COUNT1" "$KEY2" "$COUNT2"

        echo "Missing field details:"
        list_calls_missing_field "$FILE" "$KEY2"

        # Uncomment this if you want validation to stop immediately on first mismatch:
        # exit 1
    fi
}

verify_brackets() {
    FILE="$1"

    echo "Verifying brackets for $FILE"

    invalid_lines=0
    linenum=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((linenum++))
        opens=$(grep -o '<' <<< "$line" | wc -l)
        closes=$(grep -o '>' <<< "$line" | wc -l)

        if [[ "$opens" -ne "$closes" ]]; then
            echo "❌ Line $linenum: unmatched < and >"
            echo "    $line"
            ((invalid_lines++))
        fi
    done < "$FILE"

    if [[ "$invalid_lines" -ne 0 ]]; then
        echo "❌ Found $invalid_lines line(s) with unmatched < and >"
        exit 1
    fi
}

# Main function to process input and create output files
run() {
    shopt -s nocasematch

    if [ -z "$POTA_PARK" ]; then
        echo "No park reference found. Exiting..."
        exit 1
    fi

    POTA_OUTPUT="${CALLSIGN}@${POTA_PARK}-${DATE}.adi"
    WWFF_OUTPUT="${CALLSIGN}@${WWFF_PARK} ${DATE}.adi"

    echo "POTA Output File: $POTA_OUTPUT"

    if [ "$PROCESSWWFF" -eq 1 ]; then
        echo "WWFF Output File: $WWFF_OUTPUT"
    fi

    checkAndDeleteFile "$POTA_OUTPUT"
    checkAndDeleteFile "$WWFF_OUTPUT"

    # Process POTA
    found_comment="false"
    callsign="false"
    comment="MY_POTA_REF:$POTA_PARK"
    while IFS= read -r line || [[ -n $line ]]; do
        if [[ $line == *"$CALL_KEY"* ]]; then
            callsign="${line#*>}"
        fi

        if [[ $line == *"$EOR_KEY"* ]]; then
            if [ "$found_comment" == "false" ]; then
                echo -e "${RED}Did not find a comment for $callsign! Generating one.${NOCOLOR}"
                echo "$COMMENT_KEY${#comment}>$comment" >> "$POTA_OUTPUT"
            fi
            found_comment="false"
            callsign="false"
        fi

        if [[ $line == *"$COMMENT_KEY"* ]]; then
            found_comment="true"
            echo "$COMMENT_KEY${#comment}>$comment " >> "$POTA_OUTPUT"
        else
            echo "$line" >> "$POTA_OUTPUT"
        fi
    done < "$INPUT"
    echo "Done processing POTA."

    # Process WWFF
    found_comment="false"
    callsign="false"
    comment="MY_WWFF_REF:$WWFF_PARK"
    if [ "$PROCESSWWFF" -eq 1 ]; then
        while IFS= read -r line || [[ -n $line ]]; do
            if [[ $line == *"$CALL_KEY"* ]]; then
                callsign="${line#*>}"
            fi

            if [[ $line == *"$EOR_KEY"* ]]; then
                if [ "$found_comment" == "false" ]; then
                    echo "$COMMENT_KEY${#comment}>$comment" >> "$WWFF_OUTPUT"
                fi
                found_comment="false"
                callsign="false"
            fi

            case $line in
                *"$MY_SIG_KEY"*)
                    echo "${MY_SIG_KEY}4>WWFF" >> "$WWFF_OUTPUT";;
                *"$MY_SIG_INFO_KEY"*)
                    echo "$MY_SIG_INFO_KEY${#WWFF_PARK}>$WWFF_PARK" >> "$WWFF_OUTPUT";;
                *"$COMMENT_KEY"*)
                    comment="MY_WWFF_REF:$WWFF_PARK"
                    found_comment="true"
                    echo "$COMMENT_KEY${#comment}>$comment" >> "$WWFF_OUTPUT";;
                *)
                    echo "$line" >> "$WWFF_OUTPUT";;
            esac
        done < "$INPUT"
        echo "Done processing WWFF."
    fi

    INPUT_COUNT=$(grep -ci "$CALL_KEY" "$INPUT")
    POTA_OUTPUT_COUNT=$(grep -ci "$CALL_KEY" "$POTA_OUTPUT")
    if [ "$PROCESSWWFF" -eq 1 ]; then
        WWFF_OUTPUT_COUNT=$(grep -ci "$CALL_KEY" "$WWFF_OUTPUT")
    fi

    echo "Input file count: $INPUT_COUNT"
    echo "POTA Output file count: $POTA_OUTPUT_COUNT"
    if [ "$PROCESSWWFF" -eq 1 ]; then
        echo "WWFF Output file count: $WWFF_OUTPUT_COUNT"
    fi

    validate_file "$POTA_OUTPUT"

    if [ "$PROCESSWWFF" -eq 1 ]; then
        validate_file "$WWFF_OUTPUT"
    fi

    echo -= STATS =-
    calculate_time_diff "$POTA_OUTPUT"
    list_adif_states "$POTA_OUTPUT"
    count_and_list_unique_bands "$POTA_OUTPUT"

    if [ "$INPUT_COUNT" -ne "$POTA_OUTPUT_COUNT" ]; then
        echo -e "${RED}Error: Count mismatch in POTA file.${NOCOLOR}"
    fi

    if [ "$PROCESSWWFF" -eq 1 ]; then
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
POTA_PARK=$(grep -oi "${MYPOTAREF_KEY}[78]>[^ ]*" "$INPUT" | head -n 1 | cut -d '>' -f 2)

# No parameter passed in
if [ -z "$1" ]; then
    if [ -z "$POTA_PARK" ]; then
        echo "No park reference found. Exiting..."
        exit 1
    fi

    WWFF_PARK=$(get_key "$POTA_PARK")
    if [[ "$WWFF_PARK" == "null" ]]; then
        echo -e "${RED}The POTA lookup found no WWFF reference.${NOCOLOR}"
        exit 1
    fi
fi

if [ "$1" == "skip" ] || [ "$WWFF_PARK" == "NIL-0000" ]; then
    PROCESSWWFF=0
    echo "Skipping WWFF Processing"
else
    echo -e "POTA:$POTA_PARK = WWFF:$WWFF_PARK"
fi

rename() {
    epoch_time=$(date +%s)

    new_input="${INPUT%.adi}_${epoch_time}.adi"

    mv "$INPUT" "$new_input"
}


run
rename
