#!/usr/bin/perl -w

#
# makeparams.pl
#
# Joins the measured parameter values into a single output.
#

use mgparams qw(:all);
use Getopt::Long;

$upperorlower = '.';
GetOptions("l" => \$opt_lower, "u" => \$opt_upper);

$upperorlower = '[a-z]' if defined $opt_lower;
$upperorlower = '[A-Z]' if defined $opt_upper;


# There are three parameter maps.

# The default_params map contains default parameter values, which are to be
# fallbacks if nothing else is there.
%default_params = ();

# The measured_params map contains parameters measured from the PostScript font.
%measured_params = ();


####################
#
# DEFAULT PARAMETERS
#
####################

@lengths = ();
@ratios = ();
@booleans = ();
open DEFAULTS, $DEFAULT_FILE or die "open $DEFAULT_FILE: $!\n";
while (<DEFAULTS>) {
    chop;
    ($lhs, $value) = split /\s*=\s*/;
    next unless defined $lhs;
    ($type, $par) = split ' ', $lhs;
    push @lengths, $par if $type eq 'len';
    push @ratios, $par if $type eq 'ratio';
    push @booleans, $par if $type eq 'bool';
    $default_params{$par} = $value if defined $value and $value ne '';
}
close DEFAULTS;

####################
#
# MEASURED PARAMETERS
#
####################

open RAW, $RAW_PARAM_FILE or die "open $RAW_PARAM_FILE: $!\n";

%duplicates = ();
%ltr_par = ();
while (<RAW>) {
    chop;
    s/#.*//;
    next unless /^\s*(\S+)\s*=\s*([+-]?\d+\.?\d*(?:[eE][+-]?\d+)?)\s*$/;
    ($ltr, $par) = split /-/, $1;
    $val = $2;
    # We don't like it when there are "E"'s in the output
    $val = 0 if abs($val) < 0.0001;
    $val = $DESIGN_SIZE if $val > $DESIGN_SIZE;
    push @{$duplicates{"$ltr-$par"}}, $val;
}
close RAW;

for (keys %duplicates) {
    $ltr_par{$_} = average($_, @{$duplicates{$_}});
}

%duplicates = ();

for (keys %ltr_par) {
    ($ltr, $par) = split /-/, $_;
    $duplicates{$par}{$ltr} = $ltr_par{$_};
}

for $par (keys %duplicates) {
    %values = %{$duplicates{$par}};
    # See if there's a specific rule for this one
    %tokeep = ();
    for $ltr (keys %values) {
	if (defined $LETTERS_TO_KEEP{$par}) {
	    $thisrule = $LETTERS_TO_KEEP{$par};
	    $tokeep{$ltr} = $values{$ltr} if $ltr =~ /^$thisrule/;
	}
    }
    %values = %tokeep if scalar keys %tokeep > 0;
    %tokeep = ();
    $thisrule = $upperorlower;
    for $ltr (keys %values) {
	$tokeep{$ltr} = $values{$ltr} if $ltr =~ /^$thisrule/;
    }
    %values = %tokeep if scalar keys %tokeep > 0;
    $measured_params{$par} = average($par, values %values);
}


####################
#
# CALCULATED PARAMETERS
#
####################

if ($SANS_SERIF) {
    calc_param('slab', 'arm_slab');
    calc_param('dish', 0);
    calc_param('bracket', 0);
    calc_param('jut', 0);
    calc_param('cap_jut', 0);
    calc_param('beak', 0);
    calc_param('beak_jut', 0);
    # Don't know why, but serif_drop is 2, not 0, in CM sans serif
    calc_param('serif_drop', 2);
    calc_param('A_jut', 0);
    calc_param('F_jut', 0);
    calc_param('H_jut', 0);
    calc_param('A_jut_in', 0);
    calc_param('A_outer_bracket', 0);
    calc_param('A_inner_dark', 0);
    calc_param('serifs', 0);
} else {
    calc_param('beak', 'beak_withbar - slab');
    calc_param('serifs', 1);
}

if ($measured_params{'cap_stem'} > $measured_params{'u'} * 2) {
    calc_param('cap_serif_fit', 'cap_serif_space - 2 * u');
} else {
    calc_param('cap_serif_fit', 'cap_serif_space + (cap_stem / 2) - (3 * u)');
}


calc_param('square_ends', $SQUARE_ENDS);
calc_param('stem_corr', 1/36);

calc_param('fine', 'crisp * (hair > vair? vair : hair) / slab');
calc_param('cap_band', 'cap_bar');
calc_param('math_spread', '0');

# Forced parameters
for (keys %FORCED_PARAMS) {
    $measured_params{$_} = $FORCED_PARAMS{$_};
}

# If monospaced, the unit width parameter is forced
if ($measured_params{'monowidth'} != 0) {
    calc_param('monospace', 1);
    $measured_params{'u'} = $measured_params{'monowidth'} / 9;
} else {
    calc_param('monospace', 0);
}

# Hack for flare problems
if ($measured_params{'no_flare'}) {
    check_param('flare == curve', 'flare = curve');
}
# Force hair to be less than stem
check_param('hair <= stem', 'hair = stem');
check_param('vair <= stem', 'vair = stem');
# Now force rule_thickness to be between hair and stem
check_param('rule_thickness >= hair', 'rule_thickness = hair');
check_param('rule_thickness <= stem', 'rule_thickness = stem');

# These checks are based on Computers & Typesetting Vol. E
check_param('curve >= stem', "curve = stem");
check_param('cap_stem >= stem', "cap_stem = stem");
check_param('cap_curve >= curve', "cap_curve = curve");
$min_stem = $measured_params{'thin_join'};
for (qw(hair vair stem curve flare dot_size bar slab cap_hair
	    cap_stem cap_curve cap_bar cap_band arm_slab)) {
    $min_stem = $measured_params{$_}
	if defined $measured_params{$_} and $measured_params{$_} < $min_stem;
}
check_param("crisp <= $min_stem * 0.95", "crisp = $min_stem * 0.95");
check_param("tiny <= $min_stem * 0.95", "tiny = $min_stem * 0.95");
check_param("fine <= $min_stem * 0.95", "fine = $min_stem * 0.95");
check_param('stem_corr <= cap_hair / 5', "stem_corr = cap_hair / 5");
check_param('stem_corr <= stem / 6', "stem_corr = stem / 6");
check_param('stem_corr <= curve / 12', "stem_corr = curve / 12");
check_param("bar_height >= 0.50 * x_height", "bar_height = 0.50 * x_height");
check_param("bar_height <= 0.55 * x_height", "bar_height = 0.55 * x_height");

# This check was introduced to allow for negative apex_corr
check_param("apex_corr >= tiny - cap_hair", "apex_corr = tiny - cap_hair + 1");




####################
#
# FINALIZATION AND OUTPUT
#
####################

# Normalize the measured_params values.
for $par (keys %measured_params) {
    $measured_params{$par} *= $OUT_DESIGN_SIZE / $DESIGN_SIZE
	if (scalar grep /^\Q$par\E/, @lengths) > 0;
}

%params = %default_params;
$params{$_} = $measured_params{$_} for keys %measured_params;

print "font_size $OUT_DESIGN_SIZE pt#;\n";

for (@lengths) {
    if (defined $params{$_}) {
	printf "$_# := % 10.5f pt#;\n", eval $params{$_};
    } else {
	print STDERR "WARNING: $_ is undefined.\n";
    }
}

for (@ratios) {
    if (defined $params{$_}) {
	print "$_ := $params{$_};\n";
    } else {
	print STDERR "WARNING: $_ is undefined.\n";
    }
}

for (@booleans) {
    if (defined $params{$_}) {
	print "$_ := true;\n" if $params{$_};
	print "$_ := false;\n" unless $params{$_};
    } else {
	print STDERR "WARNING: $_ is undefined.\n";
    }
}




####################
#
# SUBROUTINES
#
####################

sub calc_param {
    $measured_params{$_[0]} = parse_params($_[1])
	unless defined $measured_params{$_[0]};
}

sub check_param {
    my ($cond, $fix) = @_;

    return if parse_params($cond);
    print STDERR "Warning: $cond not true.\n";
    parse_params($fix);
    if (parse_params($cond)) {
    } else {
	die "Failed to repair the invalid condition; exiting.\n";
    }
}

sub average {
    my $name = shift;
    my $sum = 0;
    return $_[0] if scalar @_ == 1;
    my $max = $_[0];
    my $min = $_[0];
    for (@_) {
	$sum += $_;
	$max = $_ if $_ > $max;
	$min = $_ if $_ < $min;
    }
    print STDERR "Warning: $name differs by "
	.(($max - $min) / $DESIGN_SIZE * 100)
	."\% of design size: "
	.(join ", ", @_)
	."\n"
	if ($max - $min) / $DESIGN_SIZE * 100 > $SIZE_TOL;
    $sum / scalar @_;
}

# Takes a string, and replaces every alphabetic segment with
# $measured_params{xxx}.
sub parse_params {
    my @parts = split /([a-zA-Z_]+)/, shift;
    for (@parts) {
	next unless /[a-zA-Z_]/;
	unless (defined $measured_params{$_}) {
	    die "ERROR: parameter $_ was not defined.\n";
	}
	$_ = "\$measured_params{'$_'}";
    }
    return eval join "", @parts;
}
