#!/usr/bin/perl -w

#
# begin.pl
#
# Sets up the font program.
#

use mgparams qw(:all);

# Force autoflush.
$| = 1;

####################
#
# CORRECT SETUP CHECK
#
# Check for the presence of requisite programs and that they function as
# expected.
#
####################

$TESTS_DONE_FLAG = "tests-done.txt";

# If the flag file indicating that the checks have passed exists, skip these
# checks.
unless (-f $TESTS_DONE_FLAG) {

    print "I'm going to run some tests now, to ensure that you've got all\n";
    print "the programs I'm going to need. Please wait...\n";

    # Check for mftrace
    $test = `mftrace --version`;
    missing_program('mftrace') unless $? == 0 and $test =~ /mftrace/;

    # Check for potrace
    $test = `potrace --version`;
    missing_program('potrace') unless $? == 0 and $test =~ /potrace/;

    # Check for GhostScript
    $tmpfile = "mathgen-temp-$$.ps";
    die "Temp file $tmpfile exists; not going to overwrite!\n" if -e $tmpfile;
    open TMPFILE, ">$tmpfile" or die "open $tmpfile: $!\n";
    print TMPFILE "1 1 add ==\n";
    close TMPFILE;
    $test = `gsnd -q -dBATCH $tmpfile`;
    unlink $tmpfile;
    missing_program('gsnd') unless $? == 0 and $test =~ /2/;

    # Check for METAFONT
    $tmpfile = "mathgen-temp-$$.mf";
    die "Temp file $tmpfile exists; not going to overwrite!\n" if -e $tmpfile;
    open TMPFILE, ">$tmpfile" or die "open $tmpfile: $!\n";
    print TMPFILE "end\n";
    close TMPFILE;
    $test = `$METAFONT_PROG $tmpfile`;
    unlink $tmpfile; $tmpfile =~ s/mf$/log/; unlink $tmpfile;
    missing_program($METAFONT_PROG) unless $? == 0 and $test =~ /METAFONT/;

    # Check for various TeX files
    $test = `kpsewhich -n tex fontinst.sty`;
    missing_program('kpsewhich or fontinst.sty')
	unless $? == 0 and $test =~ /fontinst\.sty/;

    $test = `kpsewhich -n mf calu.mf`;
    missing_program('Computer Modern fonts')
	unless $? == 0 and $test =~ /calu\.mf/;

    if (open TESTS, ">$TESTS_DONE_FLAG") {
	print TESTS "This file denotes to begin.pl that the program location\n";
	print TESTS "tests are done. You may remove this file to rerun the\n";
	print TESTS "tests, although this usually is unnecessary.\n";
	close TESTS;
    }

    print "I think all the files are in the right places.\n";
    wait_for_enter();

} else {
    # The flag file indicating to skip the tests was not seen.
    print "It appears that you've run this program before; I will not check\n";
    print "that your programs are set up correctly. If you want me to run\n";
    print "these tests, remove the `$TESTS_DONE_FLAG' file.\n";
}

####################
#
# INTERVIEW QUESTIONS
#
####################

%interview = (
    'output_prefix' => {
	'type' => 'string',
	'desc' => 'This value specifies a prefix for the math font names.',
	'longdesc' => "The output_prefix should be a short (3-letter)\n"
		     ."alphabetic name that is unique to this new font.\n"
		     ."For example, for Times Roman, a good prefix is\n"
		     ."\"ztm\"; for Palatino, \"zpl\".\n",
	'validator' => \&alphabetic_validator,
    },
    'optical_size' => {
	'optional' => 1,
	'type' => 'string',
	'desc' => "This specifies a suffix for the math font names.",
	'longdesc' => "The optical_size parameter specifies an optional\n"
		     ."suffix for the math font names. This suffix is\n"
		     ."most often used to denote different optical sizes\n"
		     ."of the same font.\n",
	'validator' => \&alphabetic_validator,
    },
    'output_dir' => {
	'optional' => 1,
	'type' => 'string',
	'desc' => 'This is the name of the directory for the font files.',
	'longdesc' => "The output_dir specifies the name of the directory\n"
		     ."in which the font files will be placed. By default\n"
		     ."they are placed in the \"output\" directory. In\n"
		     ."general this value need not be set unless you are\n"
		     ."generating multiple math fonts simultaneously.\n",
	'validator' => \&alphabetic_validator,
    },
    'font_file' => {
	'optional' => 1,
	'type' => 'file',
	'suffix' => '',
	'multiple' => 1,
	'desc' => "This specifies PFA or PFB necessary font files.",
	'longdesc' => "You must provide the location of the PFA or PFB\n"
		     ."font files of your PostScript Type 1 font. The file\n"
		     ."name should end in .pfa or .pfb. If you have a\n"
		     ."TrueType or OpenType font, there are free programs\n"
		     ."to convert to Type 1 format.\n",
	'validator' => \&file_validator,
    },
    'roman_name' => {
	'type' => 'string',
	'desc' => 'This is the PostScript font name for the roman font.',
	'longdesc' => "Each PostScript font contains an internal name.\n"
		     ."Usually that name can be extracted from the font\n"
		     ."files, under a line that reads:\n"
		     ."  /FontName /______ def\n"
		     ."For example, the font name for Times Roman is\n"
		     ."Times-Roman.\n",
    },
    'italic_name' => {
	'type' => 'string',
	'desc' => 'This is the PostScript font name for the italic font.',
	'longdesc' => "Each PostScript font contains an internal name.\n"
		     ."Usually that name can be extracted from the font\n"
		     ."files, under a line that reads:\n"
		     ."  /FontName /______ def\n"
		     ."For example, the font name for Times Roman is\n"
		     ."Times-Italic.\n",
    },
    'roman_tfm' => {
	'type' => 'file',
	'suffix' => '.tfm',
	'desc' => 'This is the name of the TFM file for the roman font.',
	'longdesc' => "You must provide the name of the TeX font metric\n"
		     ."(TFM) file for the roman (non-slanted) font here.\n"
		     ."This file is most often generated by FontInst, and\n"
		     ."it usually has a name of the form \"___r8t\". The\n"
		     .".tfm suffix need not be present. For example, the\n"
		     ."file for Times Roman is \"ptmr8t\".\n",
	'validator' => \&tfm_validator,
    },
    'italic_tfm' => {
	'type' => 'file',
	'suffix' => '.tfm',
	'locator' => 'kpsewhich',
	'desc' => 'This is the name of the TFM file for the italic font.',
	'longdesc' => "You must provide the name of the TeX font metric\n"
		     ."(TFM) file for the italic (slanted) font here.\n"
		     ."This file is most often generated by FontInst, and\n"
		     ."it usually has a name of the form \"___ri8t\". The\n"
		     .".tfm suffix need not be present. For example, the\n"
		     ."file for Times Roman is \"ptmri8t\".\n",
	'validator' => \&tfm_validator,
    },
    'sans_serif' => {
	'type' => 'bool',
	'desc' => 'This parameter chooses between a serif and sans-serif font.',
	'longdesc' => "Two types of fonts can be generated, serif math\n"
		     ."fonts and sans-serif math fonts. Serif fonts have\n"
		     ."thin protrusions at the ends of many strokes, such\n"
		     ."as the ends of the capital I. Examples of serif\n"
		     ."fonts include Times Roman and Palatino; examples\n"
		     ."of sans serif fonts include Helvetica and Arial.\n",
    },
    'square_ends' => {
	'type' => 'bool',
	'desc' => 'This parameter chooses a square-end or round-end font.',
	'longdesc' => "Two styles of fonts can be generated, fonts where\n"
		     ."many of the stroke ends are rounded, and fonts\n"
		     ."where those ends are cut off sharply. If this\n"
		     ."parameter is turned on, then ends will be cut off\n"
		     ."sharply. In general, serif fonts should have round\n"
		     ."ends, and most sans serif fonts should have square\n"
		     ."ends.\n",
    },
);



####################
#
# CREATING THE fontparams.txt FILE
#
####################

@interview_results = ();

ask_interview('output_prefix');
ask_interview('optical_size');
@font_files = ask_interview('font_file');

# Read the font files for font names.
for $file (@font_files) {
    # For PFB files, convert them to PFA first
    $file = "pfbtopfa $file |" if $file =~ /pfb$/i;
    open FONT, $file or die "open $file: $!\n";
    my ($this_fontname, $this_italic);
    # In the font file, search for the ItalicAngle and FontName parameters.
    while (<FONT>) {
	$this_fontname = $1 if m#/FontName\s+/(\S+)\s+def#;
	$this_italic = $1 if m#/ItalicAngle\s+(\S+)\s+def#;
    }
    # This file is useless unless a FontName value was found.
    next unless defined $this_fontname;
    # If no italic angle is defined, guess that it is zero.
    $this_italic = 0 unless defined $this_italic;
    # If the italic angle is zero, then this font is the roman one. Otherwise
    # it's the italic one.
    if ($this_italic == 0) {
	$roman_fontname = $this_fontname;
    } else {
	$italic_fontname = $this_fontname;
    }
}

# If there's a roman but no italic, guess that the italic is the roman, and vice
# versa.
$italic_fontname = $roman_fontname unless defined $italic_fontname;
$roman_fontname = $italic_fontname unless defined $roman_fontname;

ask_interview('roman_name', $roman_fontname) if defined $roman_fontname;
ask_interview('roman_name') unless defined $roman_fontname;
ask_interview('italic_name', $italic_fontname) if defined $italic_fontname;
ask_interview('italic_name') unless defined $italic_fontname;

ask_interview('roman_tfm');
ask_interview('italic_tfm');
ask_interview('sans_serif');
ask_interview('square_ends');

print "\n\n-----------------------\n";
print "Here are the parameters you have chosen:\n\n";
print "$_\n" for @interview_results;
print "\nShould these be written to file?\n";
$ans = read_bool("Enter yes to write the fontparams.txt file.\n");
if ($ans eq 'yes') {
    # Because sometimes we might be hard-linking fontparams.txt from someone
    # else, delete and recreate the file so we don't clobber it.
    unlink "fontparams.txt" if -f "fontparams.txt";
    open PARAM, "> fontparams.txt" or die "open fontparams.txt: $!\n";
    print PARAM "$_\n" for @interview_results;
    close PARAM;
    print "\nDone. Now run ./joinlibs.pl.\n\n";
}



####################
#
# SUBROUTINES
#
####################

sub missing_program {
    my $prog = shift;
    print <<EOF;
The program or file(s):
    $prog
could not be located or run. Please ensure that this program is
available, in the current path, and properly executable. For TeX
files, please ensure that the files are locatable by kpsewhich.

Could not find $prog; exiting.
EOF
    exit 1;
}

sub wait_for_enter {
    print "Press <ENTER> to continue...";
    die "\n" unless defined scalar <STDIN>;
}

sub read_bool {
    my $longdesc = shift;
    print "Enter \"Y\" for yes, \"N\" for no, \"?\" for help: ";
    my $ans;
    while (defined($ans = <STDIN>)) {
	if ($ans =~ /^\?/) {
	    print "\n$longdesc\n";
	} else {
	    return "yes" if $ans =~ /^y/i;
	    return "no" if $ans =~ /^n/i;
	}
	print "Enter Y or N: ";
    }
    die "\n"; # if user hit Ctrl-D
}

sub read_string {
    my ($prompt, $longdesc) = @_;
    print "$prompt, enter \"?\" for help: ";
    my $ans;
    while (defined($ans = <STDIN>)) {
	chop $ans;
	if ($ans =~ /^\?/) {
	    print "\n$longdesc\n";
	    print "$prompt, enter \"?\" for help: ";
	} else {
	    return $ans if $ans ne '';
	    print "You must enter a value: ";
	}
    }
    die "\n"; # if user hit Ctrl-D
}

sub read_opt_string {
    my ($prompt, $longdesc) = @_;
    {
	  print "$prompt, enter \"?\" for help: ";
	  my $ans = <STDIN>;
	  die "\n" unless defined $ans;
	  chop $ans;
	  print("\n$longdesc\n"), redo if $ans =~ /^\?/;
	  return $ans;
    }
}


#
# This function is the workhorse of the program: it asks an interview question.
# It is given a parameter name, which should be a value in %interview. It
# returns the response to the question.
#
sub ask_interview {
    my $param_name = shift;
    my $default_value = shift;
    unless (defined $interview{$param_name}) {
	print STDERR "There is no information about parameter $param_name.\n";
	print STDERR "It appears that you have an erroneous version of this\n";
	print STDERR "script. Please acquire a newer or corrected version.\n";
	return undef;
    }
    my %param_info = %{$interview{$param_name}};
    my $param_type = $param_info{'type'};
    my $param_help = $param_info{'longdesc'};
    print "\n-----------------------\n";
    print "Please enter a value for $param_name.\n";
    print $param_info{'desc'}."\n";
    my $ans;
    my @result = ();
    $optional_round = defined $param_info{'optional'};
    if ($optional_round) {
	print "\nThis parameter is OPTIONAL; enter a blank "
	    ."line to omit.\n";
    }
    if ($param_info{'multiple'}) {
	print "\nThis parameter takes MULTIPLE VALUES. To enter more\n";
	print "than one value, enter one per line; you will be\n";
	print "prompted for additional values. Enter a blank line\n";
	print "after the final value.\n";
    }

    # The outer loop permits multiple-value entries.
    my $h = "Enter yes to use the default value, no to enter your own value.\n";
    while (1) {
	# The inner loop is for error checking and help file entries.
	while (1) {
	    # If we were given a default value, ask if we should use it.
	    if (defined $default_value) {
		print "\nI have deduced that the value:\n";
		print "    $default_value\n";
		print "is possibly what you want. Is this correct?\n";
		$ans = read_bool($h);
		# If so, select the default_value and quit this inner loop. If,
		# for some inexplicable reason, this parameter takes multiple
		# values, we continue; $default_value is undefined so we don't
		# use it twice.
		if ($ans eq 'yes') {
		    $ans = $default_value;
		    undef $default_value;
		    last;
		}
	    }
	    if ($param_type eq 'bool') {
		$ans = read_bool($param_help);
	    } elsif ($optional_round) {
		$ans = read_opt_string($param_name, $param_help);
	    } else {
		$ans = read_string($param_name, $param_help);
	    }
	    # Empty values always terminate this loop.
	    last if $ans eq '';

	    # Now, check the answer.
	    last unless defined $param_info{'validator'};
	    last if &{$param_info{'validator'}}($ans);
	}
	# Empty result gets killed.
	last if $ans eq '';
	# Answer is good; save it.
	push @interview_results, "$param_name: $ans";
	push @result, $ans;
	# Now repeat if we can have multiple entries.
	last unless defined $param_info{'multiple'};
	# Next time around, putting in a value is optional.
	$optional_round = 1;
    }
    # Return a useful result.
    if (wantarray) {
	return @result;
    } else {
	return $#result < 0? undef : $result[0];
    }
}


sub alphabetic_validator {
    my $res = $_[0] =~ /^[a-zA-Z]+$/;
    print "Value is not composed of alphabetic characters.\n" unless $res;
    return $res;
}

sub file_validator {
    my $res = -f $_[0];
    print "File does not exist.\n" unless $res;
    return $res;
}

sub tfm_validator {
    my $res = `kpsewhich $_[0].tfm`;
    $res =~ s/\.tfm$//i;
    $res = ($res ne '');
    print "TFM file cannot be located.\n" unless $res;
    return $res;
}
