package main;

use strict;
use warnings;

my $ok;
BEGIN {
    eval {
	require Test::More;
	Test::More->import();
    };
    if ($@) {
	print "1..0 # skip Test::More required to test pod coverage.\n";
	exit;
    }
    eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->VERSION(1.00);
	Test::Pod::Coverage->import(tests => 1);
    };
    if ($@) {
	print <<eod;
1..0 # skip Test::Pod::Coverage 1.00 or greater required.
eod
	exit;
    }
}

## all_pod_coverage_ok ({coverage_class => 'Pod::Coverage::CountParents'});
pod_coverage_ok ('Astro::SIMBAD::Client', {
	also_private => [ qr{^[[:upper:]]\d_]+$} ],
    });
# Astro::SIMBAD::Client::WSQueryInterfaceServices explicitly not tested
# for coverage, since it was (mostly) generated from the WSDL anyway.
# The actual service routines are documented in Astro::SIMBAD::Client,
# but there seems to be no way to tell Test::Pod::Coverage this.

1;
