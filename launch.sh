#!/bin/bash

./load.py
echo 'Load done'
echo '================================'
cd firmware
make clean
make all
echo 'make done'
echo '================================'
cd .. 
litex_term /dev/ttyUSB2 --kernel firmware/firmware.bin
