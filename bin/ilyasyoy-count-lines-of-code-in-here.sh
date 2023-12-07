#!/bin/bash

FILE_EXTENSION=${1:-java}

echo "Count words for $FILE_EXTENSION files"

find . -type f -name "*.$FILE_EXTENSION" | xargs wc -l 
