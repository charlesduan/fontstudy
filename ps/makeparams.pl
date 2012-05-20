#!/usr/bin/perl -w

#
# rungs.pl
#

use fontparams qw(:all);

use Getopt::Long;

GetOptions(
	'l' => \$opt_lowercase,
	'u' => \$opt_uppercase,
);

$uc_or_lc = "";
$uc_or_lc = "[a-z]" if ($opt_lowercase);
$uc_or_lc = "[A-Z]" if ($opt_uppercase);

# Check for the output file's existence.
#if (-e $OUTPUT_FILE) {
#    print STDERR "File $OUTPUT_FILE exists. Do you wish to overwrite? (y/n) ";
#    exit unless <STDIN> =~ /^[yY]/;
#}

# List of parameter names

# The table of parameters, with defaults
%defparam = ();

# A hash table, whose values are hashes mapping letters to arrays of numbers.
%inparam = ();

# The three types of parameters.
@len = ();
@ratio = ();
@bool = ();

# Parse the defaults file
open DEFAULT, $DEFAULT_FILE or die "open $DEFAULT_FILE: $!\n";
while (<DEFAULT>) {
    chop;
    $_ = $` if /\s*#/;
    next unless /^\s*(len|ratio|bool)\s+(\w+)\s*=\s*(.*)\s*$/;
    $type = $1;
    $param_name = $2;
    $type eq 'len' and push @len, $param_name;
    $type eq 'ratio' and push @ratio, $param_name;
    $type eq 'bool' and push @bool, $param_name;
    $defparam{$param_name} = (eval $3) * $DESIGN_SIZE / $OUT_DESIGN_SIZE
	if $3 ne '' and $type eq 'len';
    $defparam{$param_name} = (eval $3) if $3 ne '' and $type ne 'len';
}

# Parse the input file.
open INPUT, $RAW_PARAM_FILE or die "open $RAW_PARAM_FILE: $!\n";
while (<INPUT>) {
    chop;
    $_ = $` if /#/;
    s/\s*$//;
    next unless /^\s*(\S+)\s*=\s*(-?\d*\.?\d*(?:[eE]-?\d+)?)$/;
    ($letter, $par) = split /-/, $1;
    $value = $2;
    push @{$inparam{$par}->{$letter}}, $value;
}

# Coalesce the parameters into single values.
for $par (keys %inparam) {
    my %theseparams = %{$inparam{$par}};
    # Coalesce letters that have multiple values by taking an average.
    foreach $letter (keys %theseparams) {
	$theseparams{$letter} = avgArray("$par:$letter",
					 @{$theseparams{$letter}});
    }
    my @toremove = ();
    my $leftsome = 0;
    # Remove values that match the pattern.
    my $this_pattern;

    # If there is a pattern for this specific parameter, then consider it.
    if (defined $LETTERS_TO_KEEP{$par}) {
	$this_pattern = $LETTERS_TO_KEEP{$par};
	foreach $letter (keys %theseparams) {
	    if ($letter =~ /$this_pattern/) {
		$leftsome = 1;
	    } else {
		push @toremove, $letter;
	    }
	}
	delete @theseparams{@toremove} if $leftsome;
	@toremove = ();
	$leftsome = 0;
    }

    # Consider the default pattern now.
    foreach $letter (keys %theseparams) {
	if ($letter =~ /$uc_or_lc/) {
	    $leftsome = 1;
	} else {
	    push @toremove, $letter;
	}
    }
    delete @theseparams{@toremove} if $leftsome;

    # Average the remaining values in theseparams.
    $inparam{$par} = avgArray($par, values %theseparams);
}

# Coalesce the parameters into one big hash table.
%param = %defparam;
$param{$_} = $inparam{$_} for keys %inparam;

# Use the AFM file to get more params. Read the italic one first.
# But now we get the italic angle directly from the italic font, so never mind
# &read_afm($ITAL_AFM_FILE);

# Calculate new parameters and entertain their values.
&calc_params();

# Now, output the values to the output file.
# No more output file; just write to stdout.
# open OUTPUT, "> $OUTPUT_FILE" or die "open $OUTPUT_FILE: $!\n";

print "font_size $OUT_DESIGN_SIZE pt#;\n";

for $par (@len) {
    if (defined $param{$par}) {
	printf "% 20s# := % 10.3f/$PARAM_DENOM pt#;\n",
	    $par,
	    $param{$par} * $OUT_DESIGN_SIZE * $PARAM_DENOM / $DESIGN_SIZE;
    } else {
	print STDERR "WARNING: No value for $par\n";
    }
}

for $par (@ratio) {
    if (defined $param{$par}) {
	$val = $param{$par};
	printf "% 20s  := ".($val==int $val? "% 10d" : "% 10.5f").";\n",
	    $par,
	    $val;
    } else {
	print STDERR "WARNING: No value for $par\n";
    }
}

for $par (@bool) {
    if (defined $param{$par}) {
	printf "% 20s  := % 10s;\n",
	    $par,
	    $param{$par} >= 0.5? "true" : "false";
    } else {
	print STDERR "WARNING: No value for $par\n";
    }
}



sub avgArray {
    my $label = shift;
    my $sum = 0;
    my $min = 100000; # No value produced by this program should be this big
    my $max = 0;
    for (@_) {
	$sum += $_;
	$min = (($_ < $min)? $_ : $min);
	$max = (($_ > $max)? $_ : $max);
    }
    if ($min != $max) {
	if ($min == 0) {
	    print STDERR "Warning: $label ranges from $min to $max\n";
	} elsif ((($max - $min) / $DESIGN_SIZE) * 100 > $SIZE_TOL) {
	    print STDERR "Warning: $label ranges by "
		.(int(($max - $min) / $DESIGN_SIZE * 1000)/10)
		."\% of font size: "
		.(join ", ", @_)."\n";
	}
    }
    return $sum / (scalar @_);
}


# Sets a parameter to a calculated value, but only if that parameter has no
# current value.
sub set_param {
    my ($par, $val) = @_;
    $param{$par} = $val unless defined $param{$par};
}


#
# Calculate parameters based on other values.
#
sub calc_params {
    set_param('cap_band', $param{'cap_bar'});
    set_param('fine', $param{'crisp'} * $param{'hair'} / $param{'slab'});
    set_param('thin_join', 0.8 * $param{'hair'});
    my $math_spread = 0.2 * (10 - $OUT_DESIGN_SIZE);
    set_param('math_spread', $math_spread < -0.2? -0.2 : $math_spread);
    set_param('cap_serif_fit', 0.135 * $param{'cap_jut'});
    # body_height is 8% larger than asc_height in CMR
    set_param('body_height', $param{'asc_height'} * 1.08);
    set_param('beak', $param{'beak_withbar'} - $param{'slab'});
}

#
# Reads in an AFM file and sets parameters.
#
sub read_afm {
    open AFM, $_[0] or return;
    my $cmd;
    my @args;
    my %charmtx;
    my $body_height;
    while (<AFM>) {
	chop;
	($cmd, $arg) = split /\s+/, $_, 2;
	if ($cmd eq 'StartCharMetrics' .. $cmd eq 'EndCharMetrics') {
	    next if $cmd eq 'StartCharMetrics' or $cmd eq 'EndCharMetrics';

	    # For the character metrics, reparse the line, treating each
	    # semicolon entity as a new thing.
	    %charmtx = ();
	    for my $mtx (split /\s*;\s*/) {
		$charmtx{$`} = $' if $mtx =~ /\s+/;
	    }

	    # Body height
	    if ($charmtx{'N'} eq 'parenleft') {
		(undef, undef, undef, $body_height)
		    = split /\s+/, $charmtx{'B'};
		if ($body_height > $param{'asc_height'}
			and $body_height > $param{'cap_height'}) {
		    set_param('body_height', $body_height);
		}
	    }

	} elsif ($cmd eq 'StartKernData' .. $cmd eq 'EndKernData') {
	    next if $cmd eq 'StartKernData' or $cmd eq 'EndKernData';
	    # Ignore kern data
	} else {

	    # We're in the header section of the file, where global parameters
	    # are specified.
	    next if $cmd eq 'Comment';
	    set_param('slant', sin($arg) / cos($arg)) if $cmd eq 'ItalicAngle';
	}
    }
    close AFM;
}
