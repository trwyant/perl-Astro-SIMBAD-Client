BEGIN {
    require 5.006  # for 'our'. Incantation from http://cpantest.grango.org/
}

use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker qw{WriteMakefile prompt};

our $VERSION = '0.008';

my $vers = '';

my (@exe_files, @clean_files);

print <<eod;

The simbadc script is a simple wrapper for Astro::SIMBAD::Client, which
may be used interactively or as a Unix filter.

eod

foreach my $exe (qw{simbadc}) {
    prompt ("Do you want to install $exe?", 'n') =~ m/^y/i
	and push @exe_files, $exe;
}

if ($^O eq 'MSWin32') {
    @exe_files = map {"bin/$_"} @exe_files;
    foreach (@exe_files) {`pl2bat $_`}
    @clean_files = @exe_files = grep {-e $_} map {"$_.bat"} @exe_files;
} elsif ($^O eq 'VMS') {
    foreach my $fni (map {"[.bin]$_"} @exe_files) {
	my $fno = "$fni.com";
	open (my $fhi, '<', $fni) or die <<eod;
Error - Unable to open $fni
        $!
eod
	open (my $fho, '>', $fno) or die <<eod;
Error - Unable to open $fno
        $!
eod
	print $fho "$Config{startperl}\n";
	while (<$fhi>) {print $fho $_}
    }
    @clean_files = @exe_files = map {"[.bin]$_.com"} @exe_files;
} else {
    @exe_files = map {"bin/$_"} @exe_files;
}

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;
WriteMakefile (
	NAME => 'Astro::SIMBAD::Client',
	VERSION_FROM => 'lib/Astro/SIMBAD/Client.pm',
	PREREQ_PM => {
	    'HTML::Entities'	=> 0,
	    'LWP::UserAgent'	=> 0,
	    'Scalar::Util'	=> 1.01,	# Not in Perl 5.6.
	    'SOAP::Lite'	=> 0,
	    'URI::Escape'	=> 0,
	    'XML::DoubleEncodedEntities' => 1.0,
	},
	PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
	EXE_FILES => \@exe_files,
	realclean => {FILES => join ' ', @clean_files},
	'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
	$] >= 5.005 ? (
		AUTHOR => 'Tom Wyant (wyant@cpan.org)',
		ABSTRACT => 'Fetch astronomical data from SIMBAD 4.',
		($mmv >= 6.31 ?
		    (LICENSE => 'perl') : ())
		) : (),
	);

