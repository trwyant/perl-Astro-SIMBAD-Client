use 5.008;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Meta;
use My::Module::Recommend;
use Config;
use ExtUtils::MakeMaker qw{WriteMakefile prompt};
use Getopt::Std;

my %opt;
getopts('ny', \%opt) or die <<eod;
The only legal options are
  -n = answer all questions 'no'.
  -y = answer all questions 'yes'.
You may not assert both of these at once - it's too confusing.
eod

My::Module::Recommend->recommend();

my (@exe_files, @clean_files);

print <<EOD;

The simbadc script is a simple wrapper for Astro::SIMBAD::Client, which
may be used interactively or as a Unix filter.

>>>> NOTICE <<<<\a\a\a

As of version 0.032_01 the simbadc script is installed by default. If
you do not wish it installed. run this script with the -n option. The -y
option is still accepted for backward compatibility.

EOD

if ( $opt{n} ) {
    print "Because you have asserted -n, simbadc will not be installed.\n";
} else {
    push @exe_files, 'simbadc';
}

if ($^O eq 'MSWin32') {
    @exe_files = map {"script/$_"} @exe_files;
    foreach (@exe_files) {`pl2bat $_`}
    @clean_files = @exe_files = grep {-e $_} map {"$_.bat"} @exe_files;
} elsif ($^O eq 'VMS') {
    foreach my $fni (map {"[.script]$_"} @exe_files) {
	my $fno = "$fni.com";
	open (my $fhi, '<', $fni) or die "Unable to open $fni: $!\n";
	open (my $fho, '>', $fno) or die "Unable to open $fno: $!\n";
	print $fho "$Config{startperl}\n";
	local $_ = undef;	# while (<>) ... does not localize $_.
	while (<$fhi>) {print $fho $_}
	close $fho;
	close $fhi;
    }
    @clean_files = @exe_files = map {"[.script]$_.com"} @exe_files;
} else {
    @exe_files = map {"script/$_"} @exe_files;
}

( my $mmv = ExtUtils::MakeMaker->VERSION ) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    ABSTRACT	=> $meta->abstract(),
    AUTHOR	=> $meta->author(),
    DISTNAME	=> $meta->dist_name(),
    EXE_FILES	=> \@exe_files,
    NAME	=> $meta->module_name(),
    PREREQ_PM	=> $meta->requires(),
    PL_FILES	=> {},	# Prevent old MakeMaker from running Build.PL
    realclean	=> {
	FILES => join( ' ', @clean_files ),
    },
    VERSION_FROM	=> $meta->version_from(),
);

$mmv >= 6.31
    and $args{LICENSE} = $meta->license();

if ( $mmv >= 6.4501 ) {
    $args{META_ADD} = {
	no_index => $meta->no_index(),
	$meta->provides(),
    };
    $args{META_MERGE} = $meta->meta_merge();
}

$mmv >= 6.4701
    and $args{MIN_PERL_VERSION} = $meta->requires_perl();


if ( $mmv >= 6.52 ) {
    $args{BUILD_REQUIRES} = $meta->build_requires();
    $args{CONFIGURE_REQUIRES} = $meta->configure_requires();
} elsif ( $mmv >= 6.5501 ) {
    $args{BUILD_REQUIRES} = $meta->build_requires();
    $args{META_MERGE}{configure_requires} = $meta->configure_requires();
} elsif ( $mmv >= 6.4501 ) {
    $args{META_MERGE}{build_requires} = $meta->build_requires();
    $args{META_MERGE}{configure_requires} = $meta->configure_requires();
} else {
    foreach my $method ( qw{ configure_requires build_requires } ) {
	my $req = $meta->$method();
	foreach my $key ( keys %{ $req } ) {
	    exists $args{PREREQ_PM}{$key}
		or $args{PREREQ_PM}{$key} = $req->{$key};
	}
    }
}

WriteMakefile( %args );

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $test = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(TEST_FILES)' );
    my $structural_test = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(STRUCTURAL_TEST_FILES)' );
    foreach ( $test, $structural_test ) {
	s/ \s+ \z //smx;
	s/ \A \s+ //smx;
    }
    my $optionals = join ',', My::Module::Recommend->optionals();

    return <<"EOD";

STRUCTURAL_TEST_FILES = xt/author/*.t

functional_test :: pure_all
	\$(NOECHO) \$(ECHO)
	\$(NOECHO) \$(ECHO) functional_test
	AUTHOR_TESTING=1 $test

entities_test :: pure_all
	\$(NOECHO) \$(ECHO)
	\$(NOECHO) \$(ECHO) entities_test
	AUTHOR_TESTING=1 PERL5OPT=-MTest::Without::Module=XML::DoubleEncodedEntities $test

optionals_test :: pure_all
	\$(NOECHO) \$(ECHO)
	\$(NOECHO) \$(ECHO) optionals_test
	AUTHOR_TESTING=1 PERL5OPT=-MTest::Without::Module=$optionals $test

structural_test :: pure_all
	\$(NOECHO) \$(ECHO)
	\$(NOECHO) \$(ECHO) structural_test
	AUTHOR_TESTING=1 $structural_test

authortest :: functional_test entities_test optionals_test structural_test

testcover :: pure_all
	cover -test -ignore_re=inc/ -ignore_re=eg/

.PHONY: functional_test optionals_test structural_test authortest testcover

EOD
}

# ex: set textwidth=72 :
