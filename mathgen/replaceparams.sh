#!/bin/sh

FONTPARAMS="$1"
export FONTPARAMS
./joinlibs.pl && ./rawparams.pl && ./widthlibs.pl && ./rawwidths.pl \
    && ./makewidths.pl && ./makefonts.pl
