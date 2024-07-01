#!/bin/bash
find . -type f -name "*.m4v" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -vcodec copy -acodec copy "${FILE%.m4v}.mp4";' _ '{}' \;
