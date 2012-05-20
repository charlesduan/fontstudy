#!/usr/bin/perl -w

#
# rawparams.pl
#
# Runs ghostscript to generate the raw parameters.
#

use fontparams qw(:all);

#if (-e $RAW_PARAM_FILE) {
#    print STDERR "File $RAW_PARAM_FILE exists. Overwrite? (y/n) ";
#    exit unless <STDIN> =~ /^[yY]/;
#}

$command = "gs -dNODISPLAY -r$RESOLUTION -dBATCH $PS_FILE";

$| = 1;
open OUT, ">$RAW_PARAM_FILE" or die "open $RAW_PARAM_FILE: $!\n";
open GS, "$command |";
while (<GS>) {
    unless (/^\s*\S+\s*=\s*-?\d*\.?\d*(?:[eE]-?\d+)?\s*(#.*)?$/) {
	print STDERR "$_";
    }
    print OUT $_;
}
close GS;
close OUT;
print "\nDone.\n";
