#!/bin/bash

echo converting "$"

for FILE in *.webp; do ffmpeg -i "$FILE" "$FILE.png"; done
