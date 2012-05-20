#!/usr/bin/perl -w

package fontparams;

BEGIN {
    use strict;
    use 5.004;

    use Exporter;
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    @EXPORT_OK = qw($LETTER_DIR $LIB_DIR $SETUP_FILE $PS_FILE $RAW_PARAM_FILE
	    $DEFAULT_FILE $OUTPUT_FILE @FONT_FILES $FONT_NAME
	    $ITAL_FONT_NAME $RESOLUTION $DESIGN_SIZE $OUT_DESIGN_SIZE $SIZE_TOL
	    $PARAM_DENOM $LETTERS_TO_KEEP %LETTERS_TO_KEEP $MF_PREFIX
	    $sortByLetter);

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
# PROGRAM FILES
#
####################


# Directory that contains the PostScript code for each letter.
$LETTER_DIR = 'letters';

# Directory that contains the PostScript libraries for the program.
$LIB_DIR = "libs";

# File containing the setup constants. These setup values only affect the way
# the page appears when printed; the libraries perform the fundamental
# calculations for the parameters.
$SETUP_FILE = "auxiliaries/setup.ps";

# Location for the output PostScript file.
$PS_FILE = "output.ps";

# Location for the file that will contain the raw parameters produced by the
# PostScript file.
$RAW_PARAM_FILE = 'out.txt';

# File that contains the default parameters as well as the list of all
# parameters to be captured.
$DEFAULT_FILE = "auxiliaries/param_defaults.txt";

# The final output METAFONT parameter file.
$OUTPUT_FILE = "params.txt";

# The name of the METAFONT fonts to generate.
$MF_PREFIX = "pad";


####################
#
# FONT FILES
#
####################

# PFA files to be included in the PostScript file for this font.
@FONT_FILES = qw(padr8a.pfa padri8a.pfa);

# The name of the roman font.
$FONT_NAME = 'AGaramond-Regular';

# The name of the italic font.
$ITAL_FONT_NAME = 'AGaramond-Italic';


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
	'stem'		=> 'd',
	'cap_hair'	=> 'A',
);


####################
#
# PRINTOUT GENERATION
#
####################

# Sort the printout by letter rather than parameter type.
$sortByLetter = 0;


####################
#
# FONT GENERATION
#
####################

# Hash table of font encodings to produce.

1;
