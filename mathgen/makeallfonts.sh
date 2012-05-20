#!/bin/sh

for FONTPARAMS in ls psparams/* ; do
export FONTPARAMS
./makefonts.pl -s &
done
