#!/bin/sh

maketex -t -g -D-E\ -u+khaki.map testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -t -g -D-u+mathzmn.map\ -u+khaki.map testfont

maketex -t -g -D-u+mathzmn.map\ -u+khaki.map testpos
