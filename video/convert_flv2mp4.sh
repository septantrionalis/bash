#!/bin/bash
# find . -type f -name "*.FLV" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -vcodec copy -acodec copy "${FILE%.avi}.mp4";' _ '{}' \;

find . -type f -name "*.FLV" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -c:v libx264 -crf 19 -strict experimental "${FILE%.FLV}.mp4";' _ '{}' \;
