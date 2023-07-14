#!/bin/bash

for dir in $(find . -name .git -type d -prune); do (cd "$dir/.." && git pull); done

