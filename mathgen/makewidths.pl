#!/usr/bin/perl -w

#
# makewidths.txt
#
# Processes the widths file.
#

use mgparams qw(:all);

mkdir $OUTPUT_DIR, 0777 unless -d $OUTPUT_DIR;

open RAW, $RAW_WIDTH_FILE or die "open $RAW_WIDTH_FILE: $!\n";

%letters = ();
%widths = ();
while (<RAW>) {
    chop;
    s/#.*//;
    # Only allow integer values, so lines must look like:
    # Parameter-name = [+-]1234567890
    next unless /^\s*(\S+)\s*=\s*([+-]?\d+)\s*$/;
    $widths{$1} = $2;
    ($ltr) = split /-/, $1;
    $letters{$ltr} = 1 if defined $widths{"$ltr-left"}
	and defined $widths{"$ltr-right"}
	and defined $widths{"$ltr-subscript"}
	and defined $widths{"$ltr-accent"};
}
close RAW;

die "Found no widths to ouput; exiting.\n" unless scalar keys %letters > 0;

# Calculate the values for dotless j, using the values for dotless i, regular i,
# and regular j. Here are the calculations:
#
# The left edge of the dotless j looks just like the left edge of a regular j.
#
# The right edge and subscript edge of the dotless j look like a dotless i.
#
# The accent position is the same as that of dotless i, but we must take into
# account that the width of the dotless i and the dotless j are different.
# Technically, we should move the accent position rightward by:
#   width(dotlessj) - width(dotlessi)
#   ---------------------------------
#                   2
# but we obviously can't measure the width of the dotless j, so we settle for
# the next best thing: width(j) - width(i). That should be practically the same.
#
if (defined $widths{"j-left"}
	and defined $widths{"dotlessi-right"}
	and defined $widths{"dotlessi-subscript"}
	#and defined $widths{"j-width"}
	#and defined $widths{"i-width"}
	) {
    $widths{"dotlessj-left"} = $widths{"j-left"};
    $widths{"dotlessj-right"} = $widths{"dotlessi-right"};
    $widths{"dotlessj-subscript"} = $widths{"dotlessi-subscript"};
    $widths{"dotlessj-accent"} = $widths{"dotlessi-accent"}
	+ int(($widths{"j-width"} - $widths{"i-width"}) / 2);
    $letters{"dotlessj"} = 1;

}

mkdir $OUTPUT_DIR, 0777 unless -d $OUTPUT_DIR;
open OUTPUT, "> $WIDTH_MTX" or die "open $WIDTH_MTX: $!\n";

print OUTPUT <<EOF;
%
% $WIDTH_MTX
%
% Metrics files for measured letter widths for mathematics typesetting. Idea
% based on MathKit.
%
\\relax

\\metrics

\\needsfontinstversion{1.315}

\\setcommand\\setglyphwidths#1#2#3#4#5{
    \\ifisglyph{#1}\\then
	\\resetglyph{#1}
	    \\movert{#2}
	    \\glyph{#1}{1000}
	    \\movert{#4}
	    \\resetitalic{\\sub{#3}{#4}}
	\\endresetglyph
	\\setkern{#1}{tie}{#5}
    \\fi
}

EOF

for (sort keys %letters) {
    $left = $widths{"$_-left"};
    $right = $widths{"$_-right"};
    $subsc = $widths{"$_-subscript"};
    $accent = $widths{"$_-accent"};
    print OUTPUT "\\setglyphwidths{$_}{$left}{$right}{$subsc}{$accent}\n";
}

print OUTPUT "\\endmetrics\n";

close OUTPUT;

print STDERR "Everything is ready; run ./makefonts.pl\n";
