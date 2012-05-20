#!/bin/sh

maketex -t -g -D-E\ -u+poetica.map testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -t -g -D-u+mathzmn.map\ -u+poetica.map testfont
