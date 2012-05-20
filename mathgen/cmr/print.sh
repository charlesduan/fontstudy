#!/bin/sh

maketex -D-E testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -D-u+mathzmn.map testfont
maketex -D-u+mathzmn.map testpos
