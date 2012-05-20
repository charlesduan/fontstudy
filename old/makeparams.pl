#!/usr/bin/perl -w

#
# makeparams.pl
#
# Joins the measured parameter values into a single output.
#

use fontparams qw(:all);
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

# The calc_params map contains parameters calculated by measured_params.
%calc_params = ();


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
    if (defined $ltr_par{"$ltr-$par"}) {
	push @{$duplicates{"$ltr-$par"}}, $val;
	delete $ltr_par{"$ltr-$par"};
    } else {
	$ltr_par{"$ltr-$par"} = $val;
    }
}
close RAW;

for (keys %duplicates) {
    $ltr_par{$_} = average($_, @{$duplicates{$_}});
}

%duplicates = ();

for (keys %ltr_par) {
    ($ltr, $par) = split /-/, $_;
    if (defined $measured_params{$par}) {
	$duplicates{$par}{$ltr} = $ltr_par{$_};
	delete $measured_params{$par};
    } else {
	$measured_params{$par} = $ltr_par{$_};
    }
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

# Normalize the measured_params values.
for $par (keys %measured_params) {
    $measured_params{$par} *= $OUT_DESIGN_SIZE / $DESIGN_SIZE
	if (scalar grep /^\Q$par\E/, @lengths) > 0;
}


####################
#
# CALCULATED PARAMETERS
#
####################

calc_param('beak', 'beak_withbar - slab');
calc_param('fine', 'crisp * (hair > vair? vair : hair) / slab');
calc_param('cap_band', 'cap_bar');
calc_param('math_spread', '0');





####################
#
# FINALIZATION AND OUTPUT
#
####################

%params = %default_params;
$params{$_} = $calc_params{$_} for keys %calc_params;
$params{$_} = $measured_params{$_} for keys %measured_params;


for (@lengths) {
    if (defined $params{$_}) {
	print "$_# := $params{$_} pt#;\n";
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
    my $func = $_[1];
    my ($match, $val);
    while ($func =~ /[a-zA-Z_]+/) {
	$match = $&;
	$val = $measured_params{$match};
	$func =~ s/$match/$val/g;
    }
    $calc_params{$_[0]} = eval $func;
}

sub average {
    my $name = shift;
    my $sum = 0;
    my $max = $_[0];
    my $min = $_[0];
    for (@_) {
	$sum += $_;
	$max = $_ if $_ > $max;
	$min = $_ if $_ < $min;
    }
    print STDERR "WARNING: $name differs by "
	.(($max - $min) / $DESIGN_SIZE * 100)
	."\% of design size\n"
	if ($max - $min) / $DESIGN_SIZE * 100 > $SIZE_TOL;
    $sum / scalar @_;
}
