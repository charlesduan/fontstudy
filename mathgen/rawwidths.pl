#!/usr/bin/perl -w

#
# rawwidths.pl
#
# Runs ghostscript to generate the parameters.
#

use mgparams qw(:all);

mkdir $OUTPUT_DIR, 0777 unless -d $OUTPUT_DIR;

open OUTPUT, "> $RAW_WIDTH_FILE" or die "open $RAW_WIDTH_FILE: $!\n";
# For rawwidths.pl, resolution can be ridiculously small
open GS, "gs -dNODISPLAY -dBATCH $WIDTH_FILE |";

while (<GS>) {
    print if /^\s*\S+\s*=\s*[+-]?\d+\s*(?:#.*)?$/;
    print OUTPUT;
}

close GS;
close OUTPUT;

if ($? == 0) {
    print STDERR "Everything looks good; now run ./makewidths.pl\n";
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
