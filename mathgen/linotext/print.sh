#!/bin/sh

maketex -t -g -D-E\ -u+linotext.map testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -t -g -D-u+mathzmn.map\ -u+linotext.map testfont

maketex -t -g -D-u+mathzmn.map\ -u+linotext.map testpos
