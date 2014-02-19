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
    s/# .*//;
    # Only allow integer values, so lines must look like:
    # Parameter-name = [+-]1234567890
    next unless (/^\s*(\S+)\s*=\s*([+-]?[\d.]+(?:e[+-]?\d+)?+)\s*$/);
    $widths{$1} = 0+$2;
    ($font, $ltr) = split /-/, $1;
    $ltr = "$font-$ltr";
    $letters{$ltr} = 1;
        #if defined $widths{"$ltr-left"}
        #and defined $widths{"$ltr-right"}
        #and defined $widths{"$ltr-subscript"}
        #and defined $widths{"$ltr-accent"};
}
close RAW;

die "Found no widths to output; exiting.\n" unless scalar keys %letters > 0;

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
if (defined $widths{"italic-j-left"}
	and defined $widths{"italic-dotlessi-right"}
	and defined $widths{"italic-dotlessi-subscript"}
	#and defined $widths{"j-width"}
	#and defined $widths{"i-width"}
	) {
    $widths{"italic-dotlessj-left"} = $widths{"italic-j-left"};
    $widths{"italic-dotlessj-right"} = $widths{"italic-dotlessi-right"};
    $widths{"italic-dotlessj-subscript"} = $widths{"italic-dotlessi-subscript"};
    $widths{"italic-dotlessj-accent"} = $widths{"italic-dotlessi-accent"}
	+ int(($widths{"italic-j-width"} - $widths{"italic-i-width"}) / 2);
    $letters{"dotlessj"} = 1;

}

mkdir $OUTPUT_DIR, 0777 unless -d $OUTPUT_DIR;

open my $mf_fh, "> $WIDTH_MF" or die "open $WIDTH_MF: $!\n";
print $mf_fh <<EOF;
%
% $WIDTH_MF
%
% Width metrics for characters
%
EOF

print $mf_fh "if slant > 0:\n";
print_chars('italic', $mf_fh);

print $mf_fh "elseif small_caps:\n";
print_chars('sc', $mf_fh);

print $mf_fh "else:\n";
print_chars('roman', $mf_fh);

print $mf_fh "fi\n";

close $mf_fh;

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
    next unless /^italic-(.*)$/;
    my $ltr = $1;
    $left = $widths{"$_-left"};
    $right = $widths{"$_-right"};
    $subsc = $widths{"$_-subscript"};
    $accent = $widths{"$_-accent"};
    next unless defined $widths{"$ltr-left"}
        and defined $widths{"$ltr-right"}
        and defined $widths{"$ltr-subscript"}
        and defined $widths{"$ltr-accent"};
    print OUTPUT "\\setglyphwidths{$ltr}{$left}{$right}{$subsc}{$accent}\n";
}

print OUTPUT "\\endmetrics\n";

close OUTPUT;

print STDERR "Everything is ready; run ./makefonts.pl\n";


########################################################################
#
# SUBROUTINES
#
########################################################################

sub print_chars {
    my ($font, $fh) = @_;
    for my $char (sort keys %letters) {
        next unless $char =~ /^\Q$font-\E/;
        my $letter = $';
        my $num = $letter =~ /^\d\d\d$/ ? oct $letter : ord $letter;
        $num -= 32 if $font eq 'sc';
        for my $param (qw(glyph-width left-sidebearing right-sidebearing)) {
            my $mf_param = $param; $mf_param =~ s/-/_/g;
            if (exists $widths{"$char-$param"}) {
                printf $fh "% 20s%d#:=% 10.5f pt#; %% %s\n",
                    $mf_param, $num,
                    $widths{"$char-$param"} * $OUT_DESIGN_SIZE / $DESIGN_SIZE,
                    $char;
            }
        }
    }
}
