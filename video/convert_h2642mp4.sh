#!/bin/bash
find . -type f -name "*.h264" -exec bash -c 'FILE="$1"; ffmpeg 24 -i "${FILE}"-c copy "${FILE%.avi}.mp4";' _ '{}' \;
