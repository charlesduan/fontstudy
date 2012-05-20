#!/bin/sh

maketex -g -D-E testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -g -D-u+mathzmn.map testfont
