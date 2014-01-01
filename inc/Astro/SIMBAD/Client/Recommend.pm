package Astro::SIMBAD::Client::Recommend;

use strict;
use warnings;

use Carp;
use Config;

my ( $is_5_010, $is_5_012 );

eval {
    require 5.012;
    $is_5_012 = $is_5_010 = 1;
} or eval {
    require 5.010;
    $is_5_010 = 1;
};

sub recommend {
    my @recommend;
    my $pkg_hash = __PACKAGE__ . '::';
    no strict qw{ refs };
    foreach my $subroutine ( sort keys %$pkg_hash ) {
	$subroutine =~ m/ \A _recommend_ \w+ \z /smx or next;
	my $code = __PACKAGE__->can( $subroutine ) or next;
	defined( my $recommendation = $code->() ) or next;
	push @recommend, "\n" . $recommendation;
    }
    @recommend and warn <<'EOD', @recommend,

The following optional modules were not found:
EOD
    <<'EOD';

It is not necessary to install these now. If you decide to install them
later, this software will make use of them when it finds them.

EOD
    return;
}

sub _recommend_soap_lite {
    local $@ = undef;
    eval { require SOAP::Lite; 1 } and return;
    return <<'EOD';
    * SOAP::Lite is not installed.
      This module is required for the query() method. If you do not
      intend to use this method, SOAP::Lite is not needed.
EOD
}

sub _recommend_xml_parser {
    local $@ = undef;
    eval {
	require XML::Parser;
	1;
    } and return;
    return <<'EOD';
    * XML::Parser is not installed. This module is required to process
      the results of VO-format queries. If you do not intend to make
      VO-format queries, XML::Parser is not needed. Or, you may be able
      to make do with XML::Parser::Lite, which comes with SOAP::Lite.
EOD
}

1;

=head1 NAME

Astro::SIMBAD::Client::Recommend - Recommend modules to install. 

=head1 SYNOPSIS

 use lib qw{ inc };
 use Astro::SIMBAD::Client::Recommend;
 Astro::SIMBAD::Client::Recommend->recommend();

=head1 DETAILS

This package generates the recommendations for optional modules. It is
intended to be called by the build system. The build system's own
mechanism is not used because we find its output on the Draconian side.

=head1 METHODS

This class supports the following public methods:

=head2 recommend

 Astro::SIMBAD::Client::Recommend->recommend();

This static method examines the current Perl to see which optional
modules are installed. If any are not installed, a message is printed to
standard out explaining the benefits to be gained from installing the
module, and any possible problems with installing it.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2014 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

__END__

# ex: set textwidth=72 :
