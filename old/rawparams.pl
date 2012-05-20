#!/usr/bin/perl -w

#
# rawparams.pl
#
# Runs ghostscript to generate the parameters.
#

use fontparams qw(:all);

open OUTPUT, "> $RAW_PARAM_FILE" or die "open $RAW_PARAM_FILE: $!\n";
open GS, "gs -dNODISPLAY -dBATCH -r$RESOLUTION $PS_FILE |";

while (<GS>) {
    print unless /^\s*\S+\s*=\s*[+-]?\d+\.?\d*(?:[eE][+-]?\d+)?\s*(?:#.*)?$/;
    print OUTPUT;
}

close GS;
close OUTPUT;
