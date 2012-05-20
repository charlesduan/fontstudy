#!/bin/sh

maketex -t -g -D-E\ -u+tekton.map testbad
pdftops -eps testbad.pdf
/bin/rm testbad.ps
maketex -t -g -D-u+mathzmn.map\ -u+tekton.map testfont
maketex -t -g -D-u+mathzmn.map\ -u+tekton.map testpos
