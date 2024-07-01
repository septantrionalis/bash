#!/bin/bash
# find . -type f -name "*.FLV" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -vcodec copy -acodec copy "${FILE%.avi}.mp4";' _ '{}' \;

find . -type f -name "*.mkv" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -codec copy "${FILE%.mkv}.mp4";' _ '{}' \;
