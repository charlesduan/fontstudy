#!/usr/bin/python

import os
import sys
import fontforge
import string

infile = sys.argv[1]
outfile = sys.argv[2]

font = fontforge.open(infile)

font.addLookup(
        "Kern lookup", "gpos_pair", (),
        (("kern",(("latn",("dflt")),)),))
font.addLookupSubtable("Kern lookup", "Kern lookup 0")

lc_list = [ string.ascii_lowercase[x:x+1] for x in range(26) ] + \
        [ 'ff', 'ffi', 'ffl', 'fi', 'fl' ]
uc_left_list = [
        'A', 'C', 'D', 'G', 'L', 'O', 'P', 'Q', 'R', 'S', 'T', 'U',
        'V', 'W', 'Y' ]
uc_right_list = [ 'A', 'C', 'G', 'J', 'O', 'Q', 'T', 'U', 'V', 'W', 'Y' ]

sc_left_list = [ x.lower() + ".sc" for x in uc_left_list ]
sc_right_list = [ x.lower() + ".sc" for x in uc_right_list ]

lc_left_list = [
        'a', 'b', 'c', 'e', 'f', 'ff', 'o', 'p', 'r', 'v', 'w', 'y' ]
lc_left_punct_list = [ 'g', 'h', 'k', 'm', 'n', 's', 't', 'u', 'x', 'z' ]
lc_right_list = [
        'a', 'c', 'd', 'e', 'j', 'o', 'q', 't', 'u', 'v', 'w', 'y' ]

uc_top_list = [ 'F', 'P', 'T', 'V', 'W', 'Y' ]
lc_short_list = [ 'a', 'c', 'd', 'e', 'g', 'i', 'j', 'm', 'n', 'o', 'q', 'r',
        's', 'u', 'v', 'w', 'x', 'y', 'z' ]

sc_list = [ string.ascii_lowercase[x:x+1] + ".sc" for x in range(26) ]

lpunct_list = [ 'quoteleft', 'quotedblleft' ]
rpunct_list = [ 'quoteright', 'quotedblright', 'period', 'comma' ]

font.autoKern("Kern lookup 0", 325, uc_left_list, uc_right_list, 50,
        onlyCloser=True)
font.autoKern("Kern lookup 0", 250, sc_left_list, sc_right_list, 50,
        onlyCloser=True)
font.autoKern("Kern lookup 0", 250, uc_top_list, lc_short_list + sc_list, 50,
        onlyCloser=True)

font.autoKern("Kern lookup 0", 300, lpunct_list, uc_right_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 200, lpunct_list,
        sc_right_list + lc_short_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 250, uc_left_list, rpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 200, lc_left_list +
        lc_left_punct_list + sc_left_list, rpunct_list,
        50, onlyCloser=True)

font.generate(outfile)
