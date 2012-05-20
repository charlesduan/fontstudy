#!/usr/bin/perl -w

#
# joinlibs.pl
#

use fontparams qw(:all);

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
    writeDSC("BeginResource: $_");
    writeFile($_);
    writeDSC("EndResource");
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
@letters = grep /\.ps$/, readdir DIR;
closedir DIR;

$pageno = 1;
for (@letters) {
    writeDSC("Page: $pageno $pageno");
    writeOutput("resetPage\n");
    writeLetter($_);
    writeOutput("showpage\n");
    $pageno++;
}

writeDSC("Trailer");
writeDSC("Pages: $pageno");
writeDSC("EOF");




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
    my ($letter, $param, $var) = split /-/, $filenops;
    unless (defined $letter) {
	print STDERR "Warning: could not determine letter for $file\n";
	return;
    }
    local *FILE;
    if (open FILE, "$LETTER_DIR/$file") {
	writeOutput("gsave 20 dict begin\n");
	writeOutput("/CurrentFile ($filenops) def\n");
	writeOutput("italfont\n") if defined $var and $var eq 'ital';
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
