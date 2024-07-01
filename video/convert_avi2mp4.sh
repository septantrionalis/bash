#!/bin/bash
find . -type f -name "*.avi" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -vcodec copy -acodec copy "${FILE%.avi}.mp4";' _ '{}' \;
