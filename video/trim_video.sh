#!/bin/bash
# Trim the first 25 seconds of a video and the last 5 seconds

find . -type f -name "*.mkv" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -ss 00:00:25 -t 01:00:00 -async 1 -strict -2 "${FILE%.mkv}.mp4";' _ '{}' \;

#!/bin/bash
SUBTRACT=5

for f in *.mp4; do
# Get the length of the video in h:m:s.ms format.
echo **Processing $f
RAW_OUTPUT=$(ffmpeg -i $f 2>&1 | grep "Duration"| cut -d ' ' -f 4 | sed s/,//;)
echo " " Raw output: $RAW_OUTPUT

# Split out the h, m, and s.ms
IFS=":"
declare -a elements=( $RAW_OUTPUT )
HOUR=${elements[0]}
MINUTE=${elements[1]}
TEMP=${elements[2]}
unset IFS

# Split out the s and ms from above.
IFS="."
declare -a elements2=( $TEMP )
SECOND=${elements2[0]}
MILLISECOND=${elements2[1]}
unset IFS

# Create a string in the format of h:m:s
FINAL=$HOUR:$MINUTE:$SECOND

# Create a date object to correctly subtract the seconds.
dat1=$(date '+%d%b%Y.%T' --date="2012-06-13 $FINAL MDT - $SUBTRACT seconds")
IFS="."
declare -a elements2=( $dat1 )
DATE=${elements2[0]}
TIME=${elements2[1]}
unset IFS

echo " " Subtracted time: $TIME

# Do it. Trim off that last 5 seconds.
ffmpeg -i "$f" -ss 00:00:00 -t $TIME -async 1 -strict -2 "${f%.mp4}_trim.mp4"

break;
done
