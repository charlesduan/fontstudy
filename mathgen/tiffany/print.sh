#!/bin/sh

maketex -t -g -D-E\ -u+optima.map\ -u+tiffany.map testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -t -g -D-u+mathzmn.map\ -u+optima.map\ -u+tiffany.map testfont
maketex -t -g -D-u+mathzmn.map\ -u+optima.map\ -u+tiffany.map testpos
