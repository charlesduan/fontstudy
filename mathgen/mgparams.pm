#!/usr/bin/perl -w

package mgparams;

BEGIN {
    use strict;
    use 5.004;

    use Exporter;
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    @EXPORT_OK = qw($LETTER_DIR $LIB_DIR $SETUP_FILE $PS_FILE $RAW_PARAM_FILE
	    $DEFAULT_FILE @FONT_FILES $FONT_NAME $OUTPUT_DIR $ITAL_FONT_NAME
	    $RESOLUTION $DESIGN_SIZE $OUT_DESIGN_SIZE $SIZE_TOL $PARAM_DENOM
	    $LETTERS_TO_KEEP %LETTERS_TO_KEEP $MF_PREFIX $AUX_DIR $ROMAN_TFM
	    $ITALIC_TFM $FONTINST_FILE $OPTICAL_SIZE $SANS_SERIF $MATHGEN_BASE
	    $METAFONT_PROG $SQUARE_ENDS %FORCED_PARAMS $WIDTH_FILE
	    @FONT_AUXFILES $RAW_WIDTH_FILE $WIDTH_MTX $sortByLetter);

    %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

    $VERSION = 1.00;
    @ISA = qw(Exporter);
}

use vars @EXPORT_OK;

#
# constants.pl
#
# Contains constants common to all of the scripts.
#


####################
#
# FONT FILES
#
####################

# The name of the METAFONT fonts to generate. Should be about three letters
# long.
$MF_PREFIX = "";

# PFA files to be included in the PostScript file for this font.
@FONT_FILES = ();

# The optical size suffix for the font names.
$OPTICAL_SIZE = "";

# The name of the roman font.
$FONT_NAME = "";

# The name of the italic font.
$ITAL_FONT_NAME = "";

# The name of the TFM file containing the Roman font.
$ROMAN_TFM = "";

# The name of the TFM file containing the Roman font.
$ITALIC_TFM = "";

# Is the font sans serif? 1 if yes, 0 if no.
$SANS_SERIF = 0;

# Should we square or round off the ends of terminals? 1 if yes, 0 if no. 
$SQUARE_ENDS = 0;

# Parameters whose values will be forced.
%FORCED_PARAMS = ();

# Read in parameters from the fontparams.txt file.
my $fontparams;
if (defined $ENV{'FONTPARAMS'} and -f $ENV{'FONTPARAMS'}) {
    $fontparams = $ENV{'FONTPARAMS'};
} else {
    $fontparams = 'fontparams.txt';
}

open PAR, $fontparams or die "open $fontparams: $!\n";
while (<PAR>) {
    chop;
    s/\s*#.*//;
    next unless /^(\w+):\s*(.*)\s*$/;
    my ($p, $v);
    my $key = $1;
    my $val = $2;
    $key eq 'output_prefix'	and $MF_PREFIX = $val;
    $key eq 'font_file'		and push @FONT_FILES, $val;
    $key eq 'optical_size'	and $OPTICAL_SIZE = $val;
    $key eq 'roman_name'	and $FONT_NAME = $val;
    $key eq 'italic_name'	and $ITAL_FONT_NAME = $val;
    $key eq 'roman_tfm'		and $ROMAN_TFM = $val;
    $key eq 'italic_tfm'	and $ITALIC_TFM = $val;
    $key eq 'output_dir'	and $OUTPUT_DIR = $val;
    $key eq 'sans_serif'	and $SANS_SERIF = ($val =~ /yes/i? 1 : 0);
    $key eq 'square_ends'	and $SQUARE_ENDS = ($val =~ /yes/i? 1 : 0);
    if ($key eq 'set_param') {
	($p, $v) = split /\s*=\s*/, $val;
	$FORCED_PARAMS{$p} = $v;
    }
}
close PAR;

die "No output prefix name\n" if $MF_PREFIX eq '';
die "No roman font name\n" if $FONT_NAME eq '';
die "No italic font name\n" if $ITAL_FONT_NAME eq '';
die "No roman font TFM file\n" if $ROMAN_TFM eq '';
die "No italic font TFM file\n" if $ITALIC_TFM eq '';


####################
#
# PROGRAM FILES
#
####################


# Directory that contains the PostScript code for each letter.
$LETTER_DIR = 'letters';

# Directory that contains the PostScript libraries for the program.
$LIB_DIR = "libs";

# Directory that contains auxiliary files.
$AUX_DIR = "auxiliaries";

# Directory for output files that may actually be of interest.
$OUTPUT_DIR = "output" unless defined $OUTPUT_DIR;

# File where the letter widths metrics file (mtx) will be placed (in the output
# directory).
$WIDTH_MTX = "$OUTPUT_DIR/widths.mtx";

# File containing the setup constants. These setup values only affect the way
# the page appears when printed; the libraries perform the fundamental
# calculations for the parameters.
$SETUP_FILE = "$AUX_DIR/setup.ps";

# Location for the output PostScript file.
$PS_FILE = "$OUTPUT_DIR/output.ps";

# Location for the output PostScript file that calculates widths.
$WIDTH_FILE = "$OUTPUT_DIR/widths.ps";

# Location for the file that will contain the raw parameters produced by the
# PostScript file.
$RAW_PARAM_FILE = "$OUTPUT_DIR/params.txt";

# Location for the file that will contain the raw letter widths produced by the
# PostScript file for widths.
$RAW_WIDTH_FILE = "$OUTPUT_DIR/widths.txt";

# File that contains the default parameters as well as the list of all
# parameters to be captured.
$DEFAULT_FILE = "$AUX_DIR/param_defaults.txt";

# File that contains the basic Fontinst instructions.
$FONTINST_FILE = "$AUX_DIR/fontinst.tex";

# The METAFONT base file that has been customized for Mathgen.
$MATHGEN_BASE = "mgbase";

# The METAFONT executable.
$METAFONT_PROG = "mf";

# The various files that must be temporarily brought over to the output
# directory during the font-making process.
@FONT_AUXFILES = ("mgsymbol.mf", "mgsym.mf", "mggreeku.mf", "$MATHGEN_BASE.mf",
	"mgbigdel.mf", "mgbigop.mf", "mggreekl.mf");


####################
#
# NUMERICAL CONSTANTS
#
####################

# The resolution, in pixels per inch, at which GhostScript should be run. This
# should be at least 600, since most printers are at a resolution of 600 dpi.
$RESOLUTION = 1000;

# Design size for the PostScript file. The font will be scaled to this size when
# measurements are taken. Larger is better, but too large will go off the page
# if you want to print out the PostScript file.
$DESIGN_SIZE = 1000;

# Design size for the output file. This affects a few of the calculated
# parameters, such as the math_spread to determine the distance between the bars
# of the equal sign. The default of 10 is good.
$OUT_DESIGN_SIZE = 10;

# Tolerance, in percentage of design size, that a range of values may have. We
# set this to 0.3%; the tolerance of the Computer Modern values, which have a
# granularity of 1/360, is about 0.28%.
$SIZE_TOL = 0.3;

# Denominator to make parameters a bit easier to read. Length parameters are
# multiplied by this value before output to the file.
$PARAM_DENOM = 100;


####################
#
# DETERMINATION OF WHICH LETTER TO USE TO MEASURE A PARAMETER
#
####################

# Regular expression that will determine, when there is a choice of measurable
# letters, which ones to use. Letters that pass this regular expression will be
# kept and others discarded, but if all the letters for a parameter are to be
# discarded, then the discarding is ignored.
#
# For example, both the capital I and lowercase l are used to measure the
# "crisp" parameter. Setting this variable to match lowercase letters will use
# "l"; setting it to match uppercase letters will use "I". For a parameter like
# "cap_height" though a capital letter will be used regardless.
# Now we no longer use this; instead we use capitals and lowercase.
#$LETTERS_TO_KEEP = "[A-Z]";


# Hash table mapping parameter names to regular expressions. If the expression
# for that parameter is met by one or more of the letters that produces this
# pattern, then other letters will be discarded.
#
# This is like LETTERS_TO_KEEP, except it is per-parameter.
%LETTERS_TO_KEEP = (
	'cap_curve'	=> "O",
	# We use the hairline of the "v" rather than the tip. True, most of the
	# use of hair goes to the hooks on letters, but that size can be just
	# about anything at it will still look right. However, the "pi" looks
	# weird if the hair doesn't match, and it should match with the thin
	# stroke of the "v".
	'hair'		=> '[vE]',
	'cap_bar'	=> 'T',
	'stem'		=> 'l',
	'cap_hair'	=> 'A',
);


####################
#
# PRINTOUT GENERATION
#
####################

# Sort the printout by letter rather than parameter type.
$sortByLetter = 0;


1;
