#! /bin/bash

git clone git@github.com:alpinetortoise/Brain_2.git
cd Brain_2
git submodule init '07 Cyber/07.01 Work'
git submodule init '05 General/05.04 Dotfiles'
git pull --recurse-submodules
