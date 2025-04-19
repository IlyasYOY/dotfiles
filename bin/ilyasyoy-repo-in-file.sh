#!/bin/bash

output_file="repo-file.md"

# Start with the header
echo "# Content" > "$output_file"

# Process each Git-tracked file
git ls-files | while read -r file; do
    # Skip the output file itself
    if [[ "$file" == "$output_file" ]]; then
        continue
    fi

    # Check if the file is a text file
    mimetype=$(file -b --mime-type -- "$file")
    if [[ "$mimetype" != text/* ]]; then
        continue
    fi

    # Determine the filetype from the extension
    filename="$file"
    extension="${filename##*.}"
    if [[ "$filename" == "$extension" ]]; then
        filetype="text"
    else
        filetype="$extension"
    fi

    # Append to the markdown file
    {
        echo ""
        echo "## $filename"
        echo "\`\`\`$filetype"
        cat "$file"
        echo "\`\`\`"
    } >> "$output_file"
done
