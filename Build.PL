use 5.008;

use strict;
use warnings;

use Module::Build;
use Config;
use FileHandle;

our $VERSION = '0.007_02';

(my $mbv = Module::Build->VERSION) =~ s/_//g;

my %attr = (
    dist_author => 'Tom Wyant (wyant at cpan dot org)',
    dist_abstract => 'Fetch astronomical data from SIMBAD 4.',
    module_name => 'Astro::SIMBAD::Client',
    build_requires => {
####	'Test::More' => 0.40,
    },
    requires => {
	perl => 5.008,	# SOAP::Lite dependencies
	'HTML::Entities' => 0,
	'LWP::UserAgent' => 0,
	'SOAP::Lite' => 0,
	'Scalar::Util' => 1.01,	# Not in Perl 5.6
	'URI::Escape' => 0,
	'XML::DoubleEncodedEntities' => 1.0,
    },
    dynamic_config => 1,
    license => 'perl',
);

$mbv >= 0.28 and $attr{meta_merge} = {
    no_index => {
	directory => [qw{inc t}],
    },
};

my $bldr = Module::Build->new (%attr);

my (@exe_files, @clean_files);

print <<eod;

The simbadc script is a simple wrapper for Astro::SIMBAD::Client, which
may be used interactively or as a Unix filter.

eod

foreach my $exe (qw{simbadc}) {
    $bldr->prompt ("Do you want to install $exe?", 'n') =~ m/^y/i
	and push @exe_files, $exe;
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

@clean_files and $bldr->add_to_cleanup (\@clean_files);
@exe_files and $bldr->script_files (\@exe_files);

$bldr->create_build_script ();

