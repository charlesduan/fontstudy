#!/usr/bin/perl -w

#
# rawparams.pl
#
# Runs ghostscript to generate the parameters.
#

use mgparams qw(:all);

mkdir $OUTPUT_DIR, 0777 unless -d $OUTPUT_DIR;

open OUTPUT, "> $RAW_PARAM_FILE" or die "open $RAW_PARAM_FILE: $!\n";
open GS, "gs -dNODISPLAY -dBATCH -r$RESOLUTION $PS_FILE |";

while (<GS>) {
    print unless /^\s*\S+\s*=\s*[+-]?\d+\.?\d*(?:[eE][+-]?\d+)?\s*(?:#.*)?$/;
    print OUTPUT;
}

close GS;
close OUTPUT;

if ($? == 0) {
    print STDERR "Everything looks good; now run ./makefonts.pl.\n";
    print STDERR "Or run ./widthlibs.pl to measure letter widths.\n";
} else {
    print STDERR <<EOF;

GhostScript failed. The error messages should have been printed above.

Please ensure that you have specified the proper settings for the font. In
particular, make sure that the "serif" option in fontparams.txt is correct.

Also, errors may have occurred if the font contains unusual shapes. View the
PostScript file output.ps to see which letters generate errors and why.

Finally, you may have identified a bug or numerical error in GhostScript or the
measurement routines. In that case, please send the author of this program a
copy of the font you are using.

EOF
    exit 1;
}
