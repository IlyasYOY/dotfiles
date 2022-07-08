#!/bin/bash

ln -sf ${PWD}/.vimrc ~/.vimrc
ls ~/.config/nvim || ln -sf ${PWD}/.config/nvim ~/.config/nvim
