#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;
use Config;
use FileHandle;

our $VERSION = '0.001';

my $bldr = Module::Build->new (
	dist_author => 'Tom Wyant (wyant at cpan dot org)',
	dist_abstract => 'Fetch astronomical data from SIMBAD 4.',
	module_name => 'Astro::SIMBAD::Client',
	requires => {
	    'LWP::UserAgent' => 0,
	    'SOAP::Lite' => 0,
	},
#	dist_version_from => 'ECI.pm',
#	dynamic_config => 1,
	license => 'perl',
	);

$bldr->create_build_script ();

