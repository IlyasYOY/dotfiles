#!/bin/bash

echo cleaning eclipse java files

find ~/Projects/eclipse-java/ -mindepth 1 -maxdepth 1 -type d | tee /dev/tty | xargs rm -rf
