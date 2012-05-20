#!/bin/sh

maketex -t -g -D-E\ -u+didot.map testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -t -g -D-u+mathzmn.map\ -u+didot.map testfont
maketex -t -g -D-u+mathzmn.map\ -u+didot.map testpos
