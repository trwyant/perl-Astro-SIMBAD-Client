use Config;
use ExtUtils::MakeMaker;

our $VERSION = '0.001';

my $vers = '';

WriteMakefile (
	NAME => 'Astro::SIMBAD::Client',
	VERSION_FROM => 'lib/Astro/SIMBAD/Client.pm',
	PREREQ_PM => {
	    LWP::UserAgent => 0,
	    SOAP::Lite	=> 0,
	},
	PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
	'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
	$] >= 5.005 ? (
		AUTHOR => 'Tom Wyant (wyant@cpan.org)',
		ABSTRACT => 'Fetch astronomical data from SIMBAD 4.',
		) : (),
	);

