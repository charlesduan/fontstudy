#!/usr/bin/perl -w

#
# makefonts.pl
#

use mgparams qw(:all);
use Cwd;

%really_make = (
	'r' => 1,
	'mi' => 1,
	'sy' => 1,
	'ex' => 1,
);

use Getopt::Long;
GetOptions("f" => \$opt_filesonly, 'b' => \$opt_bitmaponly,
	"t" => \$opt_traceonly, "k" => \$opt_keepall,
	"s" => \$opt_setuponly, "m" => \$opt_nosetup);

# Make the output directory if it's not there
mkdir $OUTPUT_DIR, 0777 unless -d $OUTPUT_DIR;

unless ($opt_setuponly) {

    # Link over the needed auxiliary files
    for (@FONT_AUXFILES) {
	link "$AUX_DIR/$_", "$OUTPUT_DIR/$_" or die "link $AUX_DIR/$_: $!\n"
	    unless -e "$OUTPUT_DIR/$_";
    }
    unlink "$OUTPUT_DIR/$MATHGEN_BASE.mem"
	if -f "$OUTPUT_DIR/$MATHGEN_BASE.mem";

    # Make the fonts! Note that the make_font function will just quit if it's
    # not in %really_make.
    make_font("r", "mgroman", "-u", "romangreek");
    make_font("mi", "mgmathit", "-l", "mathital");
    make_font("sy", "mgmathsy", "-l", "texmsym");
    make_font("ex", "mgmathex", "-l", "texmext");

    # Make the DVIPS map file. Hopefully this works fine for other DVI drivers.
    unless ($opt_filesonly or $opt_bitmaponly) {
	open MAP, "> $OUTPUT_DIR/math$MF_PREFIX.map"
	    or die "open $OUTPUT_DIR/math$MF_PREFIX.map: $!\n";
	map_font($_) for keys %really_make;
	close MAP;
    }

    # Clean up the unwanted auxiliary files
    unless ($opt_keepall) {
	unlink "$OUTPUT_DIR/$_" for @FONT_AUXFILES;
    }
    unlink "$OUTPUT_DIR/$MATHGEN_BASE.mem"
	if -f "$OUTPUT_DIR/$MATHGEN_BASE.mem";

}

if ($opt_nosetup) {
    print STDERR "Done making fonts, but fonts were not set up.\n";
    exit;
}

####################
#
# Prepare the fontinst file
#
####################

open FONTINST, "> $OUTPUT_DIR/$MF_PREFIX-fontinst.tex"
or die "open $OUTPUT_DIR/$MF_PREFIX-fontinst.tex: $!\n";

print FONTINST <<EOF;
\\def\\mathfont{$MF_PREFIX}
\\def\\optical{$OPTICAL_SIZE}
\\def\\rorb{r}
\\def\\weightletter{m}
\\def\\romanfont{$ROMAN_TFM}
\\def\\italicfont{$ITALIC_TFM}
\\newif\\ifr\\newif\\ifmi\\newif\\ifsy\\newif\\ifex\\newif\\ifwidths

EOF

# Print whether to make the fonts or not
for (qw(r mi sy ex)) {
    print FONTINST "\\$_".($really_make{$_}? "true" : "false")."\n";
}

# If there's a widths.mtx file, then use it; otherwise don't use any width file.
print FONTINST "\\widths".(-f $WIDTH_MTX? "true" : "false")."\n";

open BASE, $FONTINST_FILE or die "open $FONTINST_FILE: $!\n";
print FONTINST $_ while <BASE>;
close BASE;

close FONTINST;


####################
#
# Installation of the Fonts
#
####################

# All work will now take place in the output directory
chdir $OUTPUT_DIR;

@ones_to_make = map "$MF_PREFIX$_", grep $really_make{$_}, keys %really_make;

# Prepare the PL files.
for (($ROMAN_TFM, $ITALIC_TFM, @ones_to_make)) {
    system "tftopl", $_, "$_.pl";
    die "$_.pl not generated\n" unless -f "$_.pl";
}

# Run TeX on the Fontinst file.
system "tex $MF_PREFIX-fontinst.tex";


####################
#
# Check the output files, to see that they are present
#
####################

@virtual_check = ();
push @virtual_check, "r7t" if $really_make{'r'};
push @virtual_check, "r7m" if $really_make{'mi'};

for (@virtual_check) {
    $font = $MF_PREFIX.$_.$OPTICAL_SIZE;
    die "$font.vpl not created\n" unless -f "$font.vpl";
    system "vptovf $font.vpl $font.vf $font.tfm";
    unlink "$font.vpl" unless $opt_keepall;
    unlink "$font.mtx" unless $opt_keepall;
}

####################
#
# CLEANUP EXTRA FILES
#
####################

unlink "$MF_PREFIX-fontinst.tex" unless $opt_keepall;
unlink "$MF_PREFIX-fontinst.log" unless $opt_keepall;

unlink "$ROMAN_TFM.pl" unless $opt_keepall;
unlink "$ROMAN_TFM.mtx" unless $opt_keepall;
unlink "$ITALIC_TFM.pl" unless $opt_keepall;
unlink "$ITALIC_TFM.mtx" unless $opt_keepall;

for (qw(r mi sy ex)) {
    $font = $MF_PREFIX.$_.$OPTICAL_SIZE;
    unlink "$font.mtx" unless $opt_keepall;
    unlink "$font.pl" unless $opt_keepall;
    unlink "$font.mf" unless $opt_keepall;
}


####################
#
# Write the style file
#
####################

open STY, "> math$MF_PREFIX.sty" or die "open math$MF_PREFIX.sty: $!\n";

print STY <<EOF;
\\ProvidesPackage{math$MF_PREFIX}

\\SetSymbolFont{operators}{normal}{OT1}{$MF_PREFIX}{m}{n}
\\SetSymbolFont{letters}{normal}{OML}{$MF_PREFIX}{m}{it}
\\SetSymbolFont{symbols}{normal}{OMS}{$MF_PREFIX}{m}{n}
\\SetSymbolFont{largesymbols}{normal}{OMX}{$MF_PREFIX}{m}{n}

\\newcommand{\\caldefault}{$MF_PREFIX}
\\SetMathAlphabet{\\mathcal}{normal}{OMS}{\\caldefault}{m}{n}

\\DeclareMathSymbol{.}{\\mathord}{operators}{"2E}
\\DeclareMathSymbol{,}{\\mathpunct}{operators}{"2C}



\\endinput

EOF


# Done!

####################
#
# SUBROUTINES
#
####################


sub make_font {
    return unless defined $really_make{$_[0]} and $really_make{$_[0]};
    &make_metafonts(@_) unless $opt_traceonly or $opt_bitmaponly;
    &run_mf2pt1(@_) unless $opt_filesonly;
    #&generate_bitmaps(@_) unless $opt_filesonly or $opt_traceonly;
    #&trace_fonts(@_) unless $opt_filesonly or $opt_bitmaponly;
}

sub make_metafonts {
    my ($name, $basefile, $makeparopt) = @_;
    $name = $MF_PREFIX.$name.$OPTICAL_SIZE;
    local *FILE;
    local *BASE;
    local *PARAMS;
    open FILE, "> $OUTPUT_DIR/$name.mf" or die "open $OUTPUT_DIR/$name.mf: $!";
    print FILE "if unknown $MATHGEN_BASE: input $MATHGEN_BASE fi\n\n";
    print FILE "font_identifier := \"$name\";\n";

    open PARAMS, "./makeparams.pl $makeparopt |" or die "./makeparams.pl: $!\n";
    print FILE $_ while <PARAMS>;
    close PARAMS;
    die "Failed to make parameters; exiting.\n" unless $? == 0;

    open BASE, "$AUX_DIR/$basefile.mf" or die "open $AUX_DIR/$basefile.mf: $!";
    print FILE $_ while <BASE>;
    close BASE;
    close FILE;

}

sub run_mf2pt1 {
    my ($name, $basefile, $makeparopt, $encoding) = @_;
    $name = $MF_PREFIX.$name.$OPTICAL_SIZE;
    my $current_dir = getcwd;
    unless (defined $current_dir) {
	print STDERR "Could not get current directory! Tracing aborted.\n";
	return;
    }
    unless (chdir $OUTPUT_DIR) {
	print STDERR "chdir $OUTPUT_DIR: $!. Tracing aborted.\n";
	return;
    }
    unlink "$name.pfb" if -f "$name.pfb";
    system "mf2pt1", $name;
    die "$name.pfb not produced" unless -f "$name.pfb";
    # Just for fun, let's make the PL file here too.
    system "tftopl", "$name", "$name.pl";

    chdir $current_dir or die "chdir $current_dir: $!\n";
}

sub generate_bitmaps {
    my ($name, $basefile, $makeparopt, $encoding) = @_;
    $name = $MF_PREFIX.$name.$OPTICAL_SIZE;

    # Change directory
    my $current_dir = getcwd;
    unless (defined $current_dir) {
	print STDERR "Could not get current directory! Tracing aborted.\n";
	return;
    }

    link "$AUX_DIR/$encoding.enc", "$OUTPUT_DIR/$encoding.enc"
	or die "link $AUX_DIR/$encoding.enc: $!\n"
	unless -f "$OUTPUT_DIR/$encoding.enc";

    unless (chdir $OUTPUT_DIR) {
	print STDERR "chdir $OUTPUT_DIR: $!. Tracing aborted.\n";
	return;
    }

    # Time to run METAFONT!
    system $METAFONT_PROG,
	    "\\mode:=ljfour; mag:=12.045; nonstopmode; input $name.mf"
	and die "mf $name.mf failed\n";
    die "File $name.7227gf not produced\n" unless -f "$name.7227gf";

    chdir $current_dir or die "chdir $current_dir: $!\n";
}

sub trace_fonts {
    my ($name, $basefile, $makeparopt, $encoding) = @_;
    $name = $MF_PREFIX.$name.$OPTICAL_SIZE;
    my $current_dir = getcwd;
    unless (defined $current_dir) {
	print STDERR "Could not get current directory! Tracing aborted.\n";
	return;
    }

    link "$AUX_DIR/$encoding.enc", "$OUTPUT_DIR/$encoding.enc"
	or die "link $AUX_DIR/$encoding.enc: $!\n"
	unless -f "$OUTPUT_DIR/$encoding.enc";

    unless (chdir $OUTPUT_DIR) {
	print STDERR "chdir $OUTPUT_DIR: $!. Tracing aborted.\n";
	return;
    }

    # Tracing the font
    system("mftrace", '-e', "$encoding.enc", "--gffile=$name.7227gf",
	    "--tfmfile=$name.tfm", "$name")
	and die "mftrace $name failed\n";
    unlink "$encoding.enc";

    # Get rid of the extraneous METAFONT outputs
    unlink "$name.7227gf" unless $opt_keepall;
    unlink "$name.log" unless $opt_keepall;

    # Just for fun, let's make the PL file here too.
    system "tftopl", "$name", "$name.pl";

    chdir $current_dir or die "chdir $current_dir: $!\n";
}

sub map_font {
    my $name = $MF_PREFIX.$_[0].$OPTICAL_SIZE;
    print MAP "$name $name-Medium <$name.pfa\n";
}
