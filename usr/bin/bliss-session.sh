#!/bin/bash
startx &

# export DISPLAY=:1
sleep 6 && \
sakura -h -e "/usr/bin/bliss_startup.sh"

pkill qemu


