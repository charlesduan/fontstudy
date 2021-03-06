#!/usr/bin/perl -w

#
# widthlibs.pl
#

use mgparams qw(:all);

mkdir $OUTPUT_DIR, 0777 unless -d $OUTPUT_DIR;

open OUTPUT, "> $WIDTH_FILE" or die "open $WIDTH_FILE: $!\n";

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
writeOutput(<<EOF);
% THE FONT
/$FONT_NAME findfont $DESIGN_SIZE scalefont
/reencodefont {
 currentfont 0 dict copy dup /Encoding 4 -1 roll put
 /newfont exch definefont setfont
} def
0 dict copy dup /Encoding StandardEncoding put
/therealfont exch definefont pop
/$ITAL_FONT_NAME findfont $DESIGN_SIZE scalefont
0 dict copy dup /Encoding StandardEncoding put
/therealitalicfont exch definefont pop
/thefont { /therealfont findfont setfont } bind def
/theitalicfont { /therealitalicfont findfont setfont } bind def
/complexMetrics false def
EOF

# Setup file, technically unnecessary
if (-f $SETUP_FILE) {
    writeFile($SETUP_FILE);
} else {
    writeOutput("/resetPage { } def\n");
    writeOutput("gsave nulldevice newpath 0 0 moveto (x) true charpath\n");
    writeOutput("flattenpath pathbbox /XHeight exch def pop pop pop\n");
    writeOutput("grestore\n");
}

# We just stipulate that the width unit is 1/18 of an em. If you want to change
# the values, here are the rules.
#
# WidthUnit specifies the maximum extra width that will be added to the left or
# right of a letter.
writeOutput("/WidthUnit 1000 18 div def\n");

# ForcedWidth specifies an extra width that is forced on the sidebearings, so
# even in the extreme case the sidebearings will be at least this wide.
writeOutput("/ForcedWidth WidthUnit 5 div def\n");

# HeightUnit defines the resolution. Lower values will result in more accurate
# numbers (but the program may run much more slowly). MaxUnits and
# MaxSubscriptUnits are specified in terms of this value, so if you lower it,
# those two should be increased inversely proportional to the change.
writeOutput("/HeightUnit 25 def\n");

# SubscriptFraction defines the fraction of the x-height that subscripts may
# ascend.
writeOutput("/SubscriptFraction 0.65 def\n");

# MaxUnits is the number of HeightUnits that can be within one WidthUnit of the
# sidebearing position. In short, lowering this value will tend to push the
# sidebearings apart; increasing this value will tend to pull the sidebearings
# closer to the letter.
writeOutput("/MaxUnits 7 def\n");

# Same as MaxUnits, but this one applies to the subscript position. Since the
# subscript ascends to a lesser height, this value should generally be smaller
# than MaxUnits.
writeOutput("/MaxSubscriptUnits 5 def\n");

# This is the maximum distance that a subscript may fall inward, with reference
# to the outer sidebearing. The units of this value are DESIGN_SIZE, default
# 1000, to the quad width. It should, technically, adjust based on the font's
# slant, but I don't know what the appropriate formula would be.
writeOutput("/MaxSubscriptIndent 250 def\n");

if ($DESIGN_SIZE == 1000) {
    writeOutput("/AdjustScale { } def\n");
} else {
    writeOutput("/AdjustScale { 1000 mul $DESIGN_SIZE div } def\n");
}

writeDSC("EndSetup");

@letters = ();
push @letters, '#', ',';
push @letters, qw(! " $ % & < >);
push @letters, qw<\( \) * + . / : ; = ? @ [ \\\\ ] ^ _ { | } ~>;
push @letters, ('a' .. 'z', 'A' .. 'Z', '0'..'9');

%named_letters = (
    "040" => "\\040",
    "`" => "\\140",
    "'" => "\\047",
    "055" => "\\055 StandardEncoding",
    "230" => "\\272 StandardEncoding", # quotedblright
    "225" => "\\252 StandardEncoding", # quotedblleft
    "222" => "\\261 StandardEncoding", # endash
    "233" => "\\320 StandardEncoding", # emdash
    "247" => "\\247", # section symbol
    "266" => "\\266", # paragraph symbol
    "231" => "\\256 StandardEncoding", # fi
    "234" => "\\257 StandardEncoding", # fl
    "200" => "\\000 [ /ff ]",
    "201" => "\\000 [ /ffi ]",
    "202" => "\\000 [ /ffl ]",
    "203" => "\\251 StandardEncoding",
    "177" => "\\267 StandardEncoding",
    "221" => "\\221 ISOLatin1Encoding",
    "264" => "\\264 ISOLatin1Encoding",
    "237" => "\\237 ISOLatin1Encoding",
    "226" => "\\226 ISOLatin1Encoding",
    "257" => "\\257 ISOLatin1Encoding",
    "232" => "\\232 ISOLatin1Encoding",
    "270" => "\\270 ISOLatin1Encoding",
    "223" => "\\223 ISOLatin1Encoding",
    "227" => "\\227 ISOLatin1Encoding",
    "235" => "\\235 ISOLatin1Encoding",
    "224" => "\\224 ISOLatin1Encoding",
    "250" => "\\250 ISOLatin1Encoding",
);

for (@letters) {
    $pageno++;
    writeDSC("Page: $pageno $pageno");
    writeOutput("resetPage\n");
    writeRomanLetter($_);
    writeOutput("showpage\n");
    $pageno++;
    writeDSC("Page: $pageno $pageno");
    writeOutput("resetPage\n");
    writeItalicLetter($_);
    writeOutput("showpage\n");
}
@sc_letters = ('a' .. 'z');
for (@sc_letters) {
    $pageno++;
    writeDSC("Page: $pageno $pageno");
    writeOutput("resetPage\n");
    writeScLetter($_, "\\000", "[ /$_.sc ]");
    writeOutput("showpage\n");
}

$pageno = 0;
for (sort keys %named_letters) {
    $pageno++;
    writeDSC("Page: $pageno $pageno");
    writeOutput("resetPage\n");
    writeRomanLetter($_, split / /, $named_letters{$_}, 2);
    writeOutput("showpage\n");
    $pageno++;
    writeDSC("Page: $pageno $pageno");
    writeOutput("resetPage\n");
    writeItalicLetter($_, split / /, $named_letters{$_}, 2);
    writeOutput("showpage\n");
}

writeDSC("Trailer");
writeDSC("Pages: $pageno");
writeDSC("EOF");

print STDERR "Now run ./rawwidths.pl to do the measurements.\n";




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

sub writeScLetter {
    my ($letter, $charcode, $encoding) = @_;
    my $encline = $encoding ? "$encoding reencodefont" : "";
    $charcode ||= $letter;
    writeOutput(<<EOF);
/CurrentLetter ($charcode) def
/CurrentDesc (sc-$letter) def
/ItalicSlant 0 def
thefont
$encline
CurrentLetter letterPath
LeftRightWidth

EOF
}

sub writeRomanLetter {
    my ($letter, $charcode, $encoding) = @_;
    my $encline = $encoding ? "$encoding reencodefont" : "";
    $charcode ||= $letter;
    writeOutput(<<EOF);
/CurrentLetter ($charcode) def
/CurrentDesc (roman-$letter) def
/ItalicSlant 0 def
thefont
$encline
CurrentLetter letterPath
LeftRightWidth

EOF
}

sub writeItalicLetter {
    my ($letter, $charcode, $encoding) = @_;
    $charcode ||= $letter;
    my $encline = $encoding ? "$encoding reencodefont" : "";
    writeOutput(<<EOF);
/CurrentLetter ($charcode) def
/CurrentDesc (italic-$letter) def
/ItalicSlant 0.27 def
theitalicfont
$encline
CurrentLetter letterPath
LeftRightWidth

EOF
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
