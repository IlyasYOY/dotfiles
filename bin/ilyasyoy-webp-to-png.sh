#!/bin/bash

echo converting "$"

for FILE in *.webp; do ffmpeg -n -i "$FILE" "$FILE.png"; done
