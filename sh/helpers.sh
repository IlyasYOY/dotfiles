#!/usr/bin/env bash

# tms runs fzf for me to search through tmux sessions and choose one I want to
# use. works in and out of the tmux.
tms() {
    selected_session=$(tmux list-sessions -F "#{session_name}" | fzf --prompt="Select tmux session: "); 
    if [ -n "$selected_session" ]; then 
        tmux attach -t "$selected_session" || tmux switch-client -t "$selected_session"; 
    fi
}

### aider ###

aider-ollama() {
    local selected_model=$(ollama list | awk 'NR>1 {print $1}' | fzf --prompt="Select a model: ")

    [[ -n "$selected_model" ]] && \
        aider-base \
            --model "ollama_chat/$selected_model" \
            "$@"
}

aider-yandex() {
    local  selected_model=$(
        curl https://llm.api.cloud.yandex.net/v1/models \
            | jq ".data[].id" -r \
            | grep ^gpt \
            | sed "s@gpt://<folder_id>/@@g" \
            | fzf --prompt="Select a model: "
    )

    [[ -n "$selected_model" ]] && \
        aider-base \
            --openai-api-key $(pass cloud/yandex/ilyasyoy-ai-api-key) \
            --openai-api-base 'https://llm.api.cloud.yandex.net/v1' \
            --model "openai/gpt://$(pass cloud/yandex/ilyasyoy-catalog-id)/$selected_model" \
            --weak-model "openai/gpt://$(pass cloud/yandex/ilyasyoy-catalog-id)/yandexgpt-lite" \
            "$@"
}

aider-base() {
    aider \
        --watch-files \
        --pretty \
        --stream \
        --notifications \
        --dark-mode \
        --no-show-model-warnings \
        --edit-format diff \
        "$@"
}

### git utilities ###

# repo-to-file dumps full repository into one file. sometimes it might be
# useful.
repo-to-file() {
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
            echo "## $filename\n"
            echo "\`\`\`$filetype"
            cat "$file"
            echo "\`\`\`"
            echo "\n"
        } >> "$output_file"
    done
}


# list-git-repos-urls lists all repos' urls in the directory.
list-git-repo-get-urls() {
    find . \( -type d -o -type f \) -name .git | while read -r git_entry; do
        repo_dir=$(dirname "$git_entry")
        (cd "$repo_dir" && git config --get remote.origin.url 2>/dev/null)
    done
}

# list-git-repo-clone-all clones all provided repos considering it's nested
# structure. might be used with list-git-repos-urls.
list-git-repo-clone-urls() {
    while read -r url; do
        # Convert URL to directory path
        dir=$(echo "$url" | sed -e 's/^git@[^:]*://' \
                               -e 's/^https:\/\/[^\/]*\///' \
                               -e 's/\.git$//')

        # Create parent directories if needed
        mkdir -p "$dir"

        # Check if directory exists and is empty
        if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
            if [ -d "$dir/.git" ]; then
                echo "Skipping existing repository: $dir"
            else
                echo "Warning: Directory $dir exists but is not a git repository"
            fi
            continue
        fi

        echo "Cloning $url => $dir"
        git clone "$url" "$dir"
    done
}

### multimedia conversion ###

convert-webm-to-mp4() {
    for webmfile in *.webm; do 
        ffmpeg -n -i "$webmfile" "$webmfile.mp4";
    done
}

convert-webp-to-png() {
    for webpfile in *.webp; do 
        ffmpeg -n -i "$webpfile" "$webpfile.png";
    done
}

### aichat ###

# aichat can generate shell command by text.
# this is not correct: https://github.com/sigoden/aichat/blob/main/scripts/shell-integration/integration.zsh.
# fix is here: https://github.com/sigoden/aichat/issues/1231.
_aichat_zsh() {
    if [[ -n "$BUFFER" ]]; then
        local _old=$BUFFER
        BUFFER+="⌛"
        zle -I && zle redisplay
        BUFFER=$(command aichat -r '%shell%' "$_old")
        zle end-of-line
    fi
}
zle -N _aichat_zsh
bindkey '\ee' _aichat_zsh

aichat-today-tasks() {
    aichat --role %tasks-assistent% --session $(date +%F)
}

# aichat-review-diff review the diff and puts it in STDOUT. It can be used
# later to be posted somewhere.
aichat-review-diff() {
    local diff_command="${1:-"git diff"}"
    local diff_output=$(bash -c "$diff_command")
    echo "Generated diff output." >&2
    local overview_output=$(echo "$diff_output" | aichat --role %diff-overview% "${@:2}")
    echo "Generated overview output." >&2
    local comments_output=$(echo "$diff_output" | aichat --role %diff-comments% "${@:2}")
    echo "Generated comments output." >&2

    echo "## Overview\n"
    local main_output_overview=$(echo "$overview_output" | perl -0777 -pe 's/<think>.*?<\/think>//sg')
    echo "$main_output_overview"
    echo "\n## Comments\n"
    echo "<details><summary>Click to expand comments</summary>\n"
    local main_output_comments=$(echo "$comments_output" | perl -0777 -pe 's/<think>.*?<\/think>//sg')
    echo "$main_output_comments"
    echo "\n</details>"

    if [[ "$overview_output" == *"<think>"* ]]; then
        local think_output_overview=$(echo "$overview_output" | perl -0777 -ne 'print "$1\n" while /<think>(.*?)<\/think>/gs')
    else
        local think_output_overview=""
    fi
    if [[ "$comments_output" == *"<think>"* ]]; then
        local think_output_comments=$(echo "$comments_output" | perl -0777 -ne 'print "$1\n" while /<think>(.*?)<\/think>/gs')
    else
        local think_output_comments=""
    fi
    # Display thinking output if it exists
    if [[ -n "$think_output_overview" || -n "$think_output_comments" ]]; then
        echo "\n## Thinking Output\n"
        if [[ -n "$think_output_overview" ]]; then
            echo "<details><summary>Overview thinking</summary>\n"
            echo "$think_output_overview"
            echo "\n</details>"
        fi
        if [[ -n "$think_output_comments" ]]; then
            echo "<details><summary>Comments thinking</summary>\n"
            echo "$think_output_comments"
            echo "\n</details>"
        fi
    fi
}

