#!/bin/sh
# Prepares the emulator workspace these scripts use (/tmp/pk30emu): the built
# Red ROM and symbols, the scripts, and a new-game save state (st_g9).
# Run from the repo root after `make`: tools/emu/setup.sh
set -e
W=/tmp/pk30emu
mkdir -p $W/rs $W/out
cp pokered.gbc $W/rom.gbc
cp pokered.sym $W/rom.sym
cp tools/emu/*.py $W/rs/
cd $W && python3 rs/newgame.py
