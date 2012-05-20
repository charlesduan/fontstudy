#!/usr/bin/perl -w

#
# joinlibs.pl
#
# Joins PostScript library files into one big library file, preserving
# requirement dependencies.
#

use fontparams qw(:all);

# Table of files that have actually been placed into the output file.
%writtenFiles = ();

$thisdir = `pwd`;
chop $thisdir;


#####
#
# Begin the Program!
#
#####

close STDOUT;
open STDOUT, "> $PS_FILE";

# Get the letter files.
chdir $LETTER_DIR;

@letters = ();
%letterfiles = ();

if ($#ARGV == -1) {
    opendir LTRDIR, "." or die "open $LETTER_DIR: $!\n";
    while (defined($file = readdir LTRDIR)) {
	next unless -f $file and $file =~ /\.ps$/;
	$letterName = &considerLetter($file);
	push @letters, $letterName;
	$letterfiles{$letterName} = $file;
    }
} else {
    for $file (@ARGV) {
	next unless -f $file and $file =~ /\.ps$/;
	$letterName = &considerLetter($file);
	push @letters, $letterName;
	$letterfiles{$letterName} = $file;
    }
}

chdir $thisdir;

print "\%!PS-Adobe-2.0\n";
print "\%\%Pages: ".(scalar @thisdir)."\n";
print "\%\%EndComments\n";

print "\%\%BeginProlog\n";

chdir $LIB_DIR;

opendir LIBDIR, "." or die "open $LIB_DIR: $!\n";

while (defined($file = readdir LIBDIR)) {
    &considerLib($file, 1) if -f $file;
}

closedir LIBDIR;

chdir $thisdir;

for $fontfile (@FONT_FILES) {
    if ($fontfile =~ /\.pfa$/i) {
	if (open FONT, $fontfile) {
	    print "\%\%BeginResource: $fontfile\n";
	    print $_ while <FONT>;
	    close FONT;
	    print "\%\%EndResource\n";
	} else {
	    print STDERR "open $fontfile: $!\n";
	}
    }
}

print "\%\%EndProlog\n";

print "\%\%BeginSetup\n";

print <<EOF;

\% THE FONT
/$FONT_NAME findfont 1000 scalefont unitalic setfont
/italfont { /$ITAL_FONT_NAME findfont 1000 scalefont unitalic setfont } def


EOF

if (-f $SETUP_FILE) {
    open SETUP, $SETUP_FILE;
    print $_ while <SETUP>;
    close SETUP;
}
print "\%\%EndSetup\n";


@letters = sort @letters;

chdir $LETTER_DIR;

$pageno = 1;
$lastsortingunit = "";
for (@letters) {
    ($thissortingunit) = split /-/;
    if ($thissortingunit eq $lastsortingunit) {
	&writeLetter($letterfiles{$_}, $pageno, 0);
    } else {
	&writeLetter($letterfiles{$_}, $pageno, 1);
	$pageno++;
    }
    $lastsortingunit = $thissortingunit;
}

chdir $thisdir;

print "showpage\n" if $pageno > 1;
print "\%\%EOF\n";

# Parses a file and appends it to the new file.
sub considerLib {
    my ($file, $recurseLevel) = @_;
    if ($recurseLevel > 20) {
	print STDERR "Recursion limit reached, for file $file\n";
	return;
    }
    local *FH;
    my @requirements = ();
    unless (open FH, $file) {
	print STDERR "  Error opening $file: $!\n";
    }
#    print STDERR "$file\n";
    while (<FH>) {
	chop;
	if ($. == 1 and not /^%!PS-Adobe-\d\.\d/) {
#	    print STDERR "  Not a PS file; skipping...\n";
	    # But add it to the file list anyway, so this isn't called again
	    $writtenFiles{$file} = 1;
	    return;
	}
	next unless s/^%\s*Requires:\s*//;
	for (split /\s+/) {
	    push @requirements, $_ unless (defined $writtenFiles{$_});
#	    print STDERR "  Requires: $_\n";
	}
    }
    # Now for each required file, recursively call this function.
    &considerLib($_, $recurseLevel + 1) for @requirements;

    # Now, write this file
    unless (seek FH, 0, 0) {
	print STDERR "  Error seeking: $!\n";
	return;
    }
#    print STDERR "Writing file $file\n";
    print "\%\%BeginResource: $file\n";
    scalar <FH>; # Chop the first line
    while (<FH>) {
	print;
    }
    close FH;
    print "\%\%EndResource\n";
    $writtenFiles{$file} = 1;
#    print STDERR "Done with file $file.\n";
}

sub considerLetter {
    my $file = shift;
    $file =~ s/\.ps$//;
    my ($firstletter, $parameter, $alt) = split /-/, $file;
    $alt = "" unless defined $alt;
    $sortByLetter? "$firstletter-$parameter-$alt"
	: "$parameter-$firstletter-$alt";
}

sub writeLetter {
    my ($file, $pageno, $donewpage) = @_;
    $filenops = $file; $filenops =~ s/\.ps$//;
    my ($firstletter, $par, $alt) = split /-/, $filenops;
    local *LETTER;
    if ($donewpage) {
	print "showpage\n" if $pageno > 1;
	print "\%\%Page: $pageno $pageno\n";
	print "resetPage\n";
    }
    print "/CurrentFile ($filenops) def\n";
    print "gsave 20 dict begin\n";
    print "italfont\n" if defined $alt and $alt eq 'ital';
    print "($firstletter) letterPath\n";
    unless (open LETTER, $file) {
	print STDERR "Open $file: $!\n";
	return;
    }
    print $_ while <LETTER>;
    close LETTER;
    print "end grestore \% $file\n";
    print "count 0 gt { (There's stuff on the stack!) == } if\n";
}
