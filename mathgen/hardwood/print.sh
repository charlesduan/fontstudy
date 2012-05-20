#!/bin/sh

maketex -t -g -D-E\ -u+hardwood.map testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -t -g -D-u+mathzmn.map\ -u+hardwood.map testfont

maketex -t -g -D-u+mathzmn.map\ -u+hardwood.map testpos
