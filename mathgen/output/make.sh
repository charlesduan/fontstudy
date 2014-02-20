#!/bin/sh
mf cenexp && gftodvi cenexp.2602gf && dvipdf cenexp
mf2pt1 --encoding=cdlatin1.enc cenexp
mf cenexpi && gftodvi cenexpi.2602gf && dvipdf cenexpi
mf2pt1 --encoding=cdlatin1.enc cenexpi

./fixfont.pe cenexp.pfb
./fixfont.pe cenexpi.pfb

fontforge -script fixfont.py cenexp.otf cenexp.otf
fontforge -script fixfont.py cenexpi.otf cenexpi.otf
