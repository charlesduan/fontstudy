#!/usr/bin/perl -w

#
# joinlibs.pl
#

use mgparams qw(:all);


# Make the output directory if it does not yet exist.
mkdir $OUTPUT_DIR, 0777 unless -d $OUTPUT_DIR;

open OUTPUT, "> $PS_FILE" or die "open $PS_FILE: $!\n";

# Write the introductory material
writeOutput("\%!PS-Adobe-2.0\n");
writeDSC("Pages: (atend)");
writeDSC("EndComments");
writeDSC("BeginProlog");

# Read in the libraries.
opendir DIR, $LIB_DIR or die "opendir $LIB_DIR: $!\n";
@libs = grep /\.ps$/, readdir DIR;
closedir DIR;

# Determine requirements for the libraries and write them to the file.
%writtenlibs = ();
sub orderAndWriteLibraries {
    my $file = shift;
    return if defined $writtenlibs{$file};
    &orderAndWriteLibraries($_) for &getRequiresLines($file);
    writeLibrary($file);
    $writtenlibs{$file} = 1;
}
&orderAndWriteLibraries($_) for @libs;

# Write the font files
for (@FONT_FILES) {
    if ($_ =~ /\.pfa$/i) {
	writeDSC("BeginResource: $_");
	writeFile($_);
	writeDSC("EndResource");
    } elsif ($_ =~ /\.pfb$/i) {
	writeDSC("BeginResource: $_");
	writeFile("pfb2pfa $_ /dev/stdout |");
	writeDSC("EndResource");
    } else {
	print STDERR "WARNING: $_ may not be a PFA file. Not including it.\n";
    }
}

# End of the prolog
writeDSC("EndProlog");


# Begin the setup
writeDSC("BeginSetup");

# Write the font
writeOutput("\% THE FONT\n");
writeOutput("/$FONT_NAME findfont $DESIGN_SIZE scalefont unitalic setfont\n");
writeOutput("/italfont {\n    /$ITAL_FONT_NAME findfont $DESIGN_SIZE ");
writeOutput("scalefont unitalic setfont\n} def\n");


# Setup file, technically unnecessary
if (-f $SETUP_FILE) {
    writeFile($SETUP_FILE);
} else {
    writeOutput("/resetPage { } def\n");
    writeOutput("gsave nulldevice newpath 0 0 moveto (x) true charpath\n");
    writeOutput("flattenpath pathbbox /XHeight exch def pop pop pop\n");
    writeOutput("grestore\n");
}
writeDSC("EndSetup");


# Read in the letter files.
opendir DIR, $LETTER_DIR or die "opendir $LETTER_DIR: $!\n";
@letters = sort grep /\.ps$/, readdir DIR;
closedir DIR;

$pageno = 0;
for (@letters) {
    (undef, undef, $opt) = split /-/, $_, 3;
    next if $SANS_SERIF and defined $opt and $opt =~ /serif/;
    next if not $SANS_SERIF and defined $opt and $opt =~ /sans/;
    $pageno++;
    writeDSC("Page: $pageno $pageno");
    writeOutput("resetPage\n");
    writeLetter($_);
    writeOutput("showpage\n");
}

writeDSC("Trailer");
writeDSC("Pages: $pageno");
writeDSC("EOF");

print STDERR "Now run ./rawparams.pl to measure the font parameters.\n";


####################
#
# SUBROUTINES
#
####################


# Given a file name, gets the lines that read:
#
# % Requires:
#
# and determines the dependencies of the file.
sub getRequiresLines {
    local *FILE;
    my @files = ();
    my $file = "$LIB_DIR/$_[0]";
    if (open FILE, $file) {
	while (<FILE>) {
	    next unless /^%\s*Requires:\s*/;
	    push @files, split /\s+/, $';
	}
	close FILE;
    } else {
	print STDERR "open $file: $!\n";
    }
    return @files;
}

sub writeLibrary {
    local *FILE;
    my $file = shift;
    if (open FILE, "$LIB_DIR/$file") {
	writeOutput("\%\%BeginResource: $file\n");
	writeOutput($_) while <FILE>;
	close FILE;
	writeOutput("\%\%EndResource\n");
    } else {
	print STDERR "open $LIB_DIR/$file: $!\n";
    }
}

sub writeLetter {
    my $file = shift;
    my $filenops = substr $file, 0, -3;
    my ($letter, $param, $var) = split /-/, $filenops, 3;
    unless (defined $letter and $letter =~ /^([lup])(.)$/) {
	print STDERR "Warning: could not determine letter for $file\n";
	return;
    }
    $letter = $1 eq 'l'? lc $2 : ($1 eq 'u'? uc $2 : $2);
    local *FILE;
    if (open FILE, "$LETTER_DIR/$file") {
	writeOutput("gsave 20 dict begin\n");
	writeOutput("/CurrentFile ($filenops) def\n");
	writeOutput("/CurrentLetter ($letter) def\n");
	writeOutput("italfont\n") if defined $var and $var =~ /ital/;
	writeOutput("($letter) letterPath\n");
	writeOutput($_) while <FILE>;
	writeOutput("count 0 gt { (There's stuff on the stack!) == } if\n");
	writeOutput("end grestore\n");
	close FILE;
    } else {
	print STDERR "open $LETTER_DIR/$file: $!\n";
    }
}

sub writeDSC {
    writeOutput('%%'.$_[0]."\n");
}
sub writeOutput {
    print OUTPUT @_;
}
sub writeFile {
    local *FILE;
    if (open FILE, "$_[0]") {
	writeOutput($_) while <FILE>;
	close FILE;
    } else {
	print STDERR "open $_[0]: $!\n";
    }
}
