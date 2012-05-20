#!/bin/sh

maketex -t -g -D-E\ -u+optima.map testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -t -g -D-u+mathzmn.map\ -u+optima.map testfont
maketex -t -g -D-u+mathzmn.map\ -u+optima.map testpos
maketex -t -g -D-u+mathzmn.map\ -u+optima.map random
