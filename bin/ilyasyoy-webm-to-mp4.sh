#!/bin/bash

echo converting "$"

for FILE in *.webm; do ffmpeg -n -i "$FILE" "$FILE.mp4"; done
