package main;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

eval {
    require Test::Prereq::Meta;
    1;
} or plan skip_all => 'Test::Prereq::Meta not available';

my $tpm = Test::Prereq::Meta->new(
    accept	=> [ qw{
	Time::HiRes
	XML::DoubleEncodedEntities
	YAML
	} ],
    prune	=> [ qw{
	blib/script
	blib/lib/Astro/SIMBAD/Client/WSQueryInterfaceService.pm
	} ],
);

$tpm->all_prereq_ok();

$tpm->all_prereqs_used();

done_testing;

1;

# ex: set textwidth=72 :
