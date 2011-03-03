use 5.008;

use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker qw{WriteMakefile prompt};
use Getopt::Std;

our $VERSION = '0.019';

my %opt;
getopts('ny', \%opt) or die <<eod;
The only legal options are
  -n = answer all questions 'no'.
  -y = answer all questions 'yes'.
You may not assert both of these at once - it's too confusing.
eod


my (@exe_files, @clean_files);

print <<eod;

The simbadc script is a simple wrapper for Astro::SIMBAD::Client, which
may be used interactively or as a Unix filter.

eod

if ($opt{n}) {
    print "Because you have asserted -n, simbadc will not be installed.\n";
} elsif ($opt{y}) {
    print "Because you have asserted -y, simbadc will be installed.\n";
    push @exe_files, 'simbadc';
} else {
    print <<eod;
To supress the following prompt, run Makefile.PL with the -y option to
install the script, or with the -n option not to install the script.
Setting environment variable PERL_MM_USE_DEFAULT true, or running non-
interactively without data on STDIN will also cause the script not to be
installed.

eod
    
    prompt ("Do you want to install simbadc?", 'n') =~ m/^y/i
	and push @exe_files, 'simbadc';
}

if ($^O eq 'MSWin32') {
    @exe_files = map {"bin/$_"} @exe_files;
    foreach (@exe_files) {`pl2bat $_`}
    @clean_files = @exe_files = grep {-e $_} map {"$_.bat"} @exe_files;
} elsif ($^O eq 'VMS') {
    foreach my $fni (map {"[.bin]$_"} @exe_files) {
	my $fno = "$fni.com";
	open (my $fhi, '<', $fni) or die "Unable to open $fni: $!\n";
	open (my $fho, '>', $fno) or die "Unable to open $fno: $!\n";
	print $fho "$Config{startperl}\n";
	while (<$fhi>) {print $fho $_}
	close $fho;
	close $fhi;
    }
    @clean_files = @exe_files = map {"[.bin]$_.com"} @exe_files;
} else {
    @exe_files = map {"bin/$_"} @exe_files;
}

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;

my %attr = (
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
    AUTHOR => 'Tom Wyant (wyant@cpan.org)',
    ABSTRACT => 'Fetch astronomical data from SIMBAD 4.',
);

$mmv >= 6.31 and $attr{LICENSE} = 'perl';

$mmv >= 6.4501 and $attr{META_ADD} = {
    no_index => {
	directory => [ qw{ inc t xt } ],
    },
};

$mmv >= 6.4501 and $attr{META_MERGE} = {
    build_requires => {
####	'Test::More' => 0.40,
    },
    resources => {
	bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-SIMBAD-Client',
	license => 'http://dev.perl.org/licenses/',
    },
};

WriteMakefile (%attr);

