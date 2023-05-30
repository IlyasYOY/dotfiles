#!/bin/bash

echo converting "$"

for FILE in *.webm; do ffmpeg -i "$FILE" "$FILE.mp4"; done
