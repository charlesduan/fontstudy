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
        [ 'f_f', 'f_f_i', 'f_f_l', 'f_i', 'f_l' ]
uc_left_list = [
        'A', 'C', 'D', 'G', 'O', 'Q', 'R', 'S', 'U',
        'V', 'W', 'Y' ]
uc_less_left_list = [ 'L', 'P', 'T' ]
uc_right_list = [ 'A', 'C', 'G', 'J', 'O', 'Q', 'T', 'U', 'V', 'W', 'Y' ]

sc_left_list = [ x.lower() + ".sc" for x in uc_left_list ]
sc_less_left_list = [ x.lower() + ".sc" for x in uc_less_left_list ]
sc_right_list = [ x.lower() + ".sc" for x in uc_right_list ]

lc_left_list = [
        'a', 'b', 'c', 'e', 'f', 'f_f', 'o', 'p', 'r', 'v', 'w', 'y' ]
lc_left_punct_list = [ 'g', 'h', 'k', 'm', 'n', 's', 't', 'u', 'x', 'z' ]
lc_right_list = [
        'a', 'c', 'd', 'e', 'j', 'o', 'q', 't', 'u', 'v', 'w', 'y' ]

uc_top_list = [ 'F', 'P', 'V', 'W', 'Y' ]
uc_top_more_list = [ 'U', 'J', 'T' ]
uc_top_more_left_list = [ 'J', 'N' ]
sc_top_list = [ x.lower() + ".sc" for x in (uc_top_list + uc_top_more_list) ]
lc_short_list = [ 'a', 'c', 'd', 'e', 'g', 'i', 'j', 'm', 'n', 'o', 'q', 'r',
        's', 'u', 'v', 'w', 'x', 'y', 'z' ]

sc_list = [ string.ascii_lowercase[x:x+1] + ".sc" for x in range(26) ]

lpunct_list = [ 'quoteleft', 'quotedblleft' ]
rpunct_list = [ 'quoteright', 'quotedblright' ]
lowpunct_list = [ 'period', 'comma' ]

font.autoKern("Kern lookup 0", 325, uc_left_list + uc_less_left_list,
        uc_right_list, 50, onlyCloser=True)
font.autoKern("Kern lookup 0", 250, sc_left_list + sc_less_left_list,
        sc_right_list, 50, onlyCloser=True)
font.autoKern("Kern lookup 0", 250, uc_top_list, lc_short_list + sc_list, 50,
        onlyCloser=True)
font.autoKern("Kern lookup 0", 250, uc_left_list + uc_less_left_list,
        lc_right_list + sc_right_list, 50, onlyCloser=True)

font.autoKern("Kern lookup 0", 300, lpunct_list, uc_right_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 200, lpunct_list,
        sc_right_list + lc_short_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 350, uc_less_left_list, rpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 250, uc_left_list + uc_top_list, rpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 300, sc_less_left_list, rpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 200, lc_left_list +
        lc_left_punct_list + sc_left_list, rpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 100, [ 'f', 'f_f' ], rpunct_list,
        50, onlyCloser=False)

font.autoKern("Kern lookup 0", 200, lowpunct_list, lc_right_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 200, lc_left_list,
        lowpunct_list, 50, onlyCloser=True)
font.autoKern("Kern lookup 0", 300, [ 'F', 'V', 'P' ], lowpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 250, [ 'W' ], lowpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 220, [ 'T', 'Y' ], lowpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 170, [ 'J', 'N', 'U' ], lowpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 150, lowpunct_list, uc_top_more_list,
        50, onlyCloser=True)

font.autoKern("Kern lookup 0", 170, lowpunct_list, [ 'C', 'G', 'O', 'Q' ],
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 170, [ 'C', 'D', 'O', 'Q', 'R' ], lowpunct_list,
        50, onlyCloser=True)

font.autoKern("Kern lookup 0", 300, lowpunct_list, [ 'V' ],
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 250, lowpunct_list, [ 'W' ],
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 220, lowpunct_list, [ 'T', 'Y' ],
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 170, lowpunct_list, [ 'U' ],
        50, onlyCloser=True)

font.autoKern("Kern lookup 0", 250, [ 'f.sc', 'p.sc', 'v.sc' ], lowpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 200, [ 'w.sc' ], lowpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 150,
        [ 't.sc', 'y.sc', 'j.sc', 'u.sc' ], lowpunct_list,
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 120, [ 'n.sc' ], lowpunct_list,
        50, onlyCloser=True)

font.autoKern("Kern lookup 0", 250, lowpunct_list, [ 'v.sc' ],
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 200, lowpunct_list, [ 'w.sc' ],
        50, onlyCloser=True)
font.autoKern("Kern lookup 0", 150, lowpunct_list, [ 't.sc', 'y.sc', 'u.sc' ],
        50, onlyCloser=True)

font.autoKern("Kern lookup 0", 120, lowpunct_list, [ 'J', 'j.sc' ],
        50, onlyCloser=False)

font.autoKern("Kern lookup 0", 250,
        [ 'A', 'T', 'V', 'W', 'X', 'Y', 'v', 'w', 'x', 'y', 'a.sc', 'v.sc',
            'w.sc', 'x.sc', 'y.sc' ],
        [ 'hyphen' ], 50, onlyCloser=True)

font.autoKern("Kern lookup 0", 250,
        [ 'hyphen' ],
        [ 'A', 'T', 'V', 'W', 'X', 'Y', 'v', 'w', 'x', 'y', 'a.sc', 'v.sc',
            'w.sc', 'x.sc', 'y.sc' ],
        50, onlyCloser=True)

font.autoKern("Kern lookup 0", 120, [ 'hyphen' ], [ 'C', 'G', 'O', 'Q', 'S' ],
        50, onlyCloser=False)
font.autoKern("Kern lookup 0", 120, [ 'C', 'D', 'O', 'Q', 'S' ], [ 'hyphen' ],
        50, onlyCloser=False)

font.autoKern("Kern lookup 0", 200, [ 'hyphen' ], [ 'J' ],
        50, onlyCloser=False)

font.generate(outfile)
