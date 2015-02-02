#!/bin/sh

$FAMILY="Century Expanded CD"
$NAME="CenturyExpandedCD"

#mf cenexpbi && gftodvi cenexpbi.2602gf && dvipdf cenexpbi
#mf2pt1 --encoding=cdlatin1.enc \
#    cenexpbi
#./fixfont.pe cenexpbi.pfb Bold Italic
#fontforge -script fixfont.py cenexpbi.otf cenexpbi.otf

mf cenexpb && gftodvi cenexpb.2602gf && dvipdf cenexpb
mf2pt1 --encoding=cdlatin1.enc \
    cenexpb
./fixfont.pe cenexpb.pfb Bold ''
fontforge -script fixfont.py cenexpb.otf cenexpb.otf

#mf cenexp && gftodvi cenexp.2602gf && dvipdf cenexp
#mf2pt1 --encoding=cdlatin1.enc \
#    cenexp
#./fixfont.pe cenexp.pfb Regular ''
#fontforge -script fixfont.py cenexp.otf cenexp.otf

#mf cenexpi && gftodvi cenexpi.2602gf && dvipdf cenexpi
#mf2pt1 --encoding=cdlatin1.enc \
#    cenexpi
#./fixfont.pe cenexpi.pfb Regular Italic
#fontforge -script fixfont.py cenexpi.otf cenexpi.otf
