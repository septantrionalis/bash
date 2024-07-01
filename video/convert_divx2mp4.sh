#!/bin/bash
find . -type f -name "*.divx" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -c:v copy -c:a copy -y "${FILE%.divx}.mp4";' _ '{}' \;
