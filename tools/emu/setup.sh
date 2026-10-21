#!/bin/sh
# Prepares the emulator workspace these scripts use: the built ROM and
# symbols, the scripts, and a new-game save state (st_g9). Run from the repo
# root after `make`:
#   tools/emu/setup.sh            # Red, in /tmp/pk30emu
#   tools/emu/setup.sh pokeblue   # another build, in /tmp/pk30emu_pokeblue
set -e
B=${1:-pokered}
if [ "$B" = pokered ]; then W=/tmp/pk30emu; else W=/tmp/pk30emu_$B; fi
mkdir -p $W/rs $W/out
cp $B.gbc $W/rom.gbc
cp $B.sym $W/rom.sym
for f in tools/emu/*.py; do sed "s#/tmp/pk30emu/#$W/#g" $f > $W/rs/$(basename $f); done
cd $W && python3 rs/newgame.py
