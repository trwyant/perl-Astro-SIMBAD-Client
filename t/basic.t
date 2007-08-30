#!/usr/local/bin/perl

use strict;
use warnings;

use Test;

my $rslt;
BEGIN {
    eval {require Astro::SIMBAD::Client};
    $rslt = $@;
    plan tests => $rslt ? 1 : 4;
    print <<eod;
# Test 1 - Load Astro::SIMBAD::Client
#     Expect: no error
#        Got: @{[$rslt || 'no error']}
eod
    ok (!$rslt);
    $rslt and die "Failed to load Astro::SIMBAD::Client. Can not continue.\n";
}

my $smb = Astro::SIMBAD::Client->new ();
print <<eod;
# Test 2 - Astro::SIMBAD::Client->new ();
#     Expect: new object
#        Got: @{[$smb ? 'new object' : 'nothing']}
eod
ok ($smb);

my $test = 2;
foreach ([get => debug => 0], [set => debug => 1], [get => debug => 1]) {
    my ($method, @args) = @$_;
    if ($method eq 'get') {
	$test++;
	my $want = pop @args;
	$rslt = $smb->$method (@args);
	print <<eod;
# Test $test - \$smb->$method (@{[join ', ', map {"'$_'"} @args]})
#     Expect: $want
#        Got: $rslt
eod
	if ($want =~ m/\d+/) {
	    ok ($want == $rslt);
	} else {
	    ok ($want eq $rslt);
	}
    } else {
	$smb->$method (@args);
    }
}

