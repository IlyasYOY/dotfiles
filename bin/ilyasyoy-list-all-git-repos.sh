#!/bin/bash

for dir in $(find . -name .git -type d -prune); do (cd "$dir/.." && git remote get-url origin); done
