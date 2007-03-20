=head1 NAME

Astro::SIMBAD::Client - Fetch astronomical data from SIMBAD 4.

=head1 SYNOPSIS

 use Astro::SIMBAD::Client;
 my $simbad = Astro::SIMBAD::Client->new ();
 print $simbad->query (id => 'Arcturus');

=head1 DESCRIPTION

This package implements the SOAP query interface to version 4 of the
SIMBAD on-line astronomical catalog, as documented at
L<http://simbad.u-strasbg.fr/simbad4.htx>. B<This package will not work
with SIMBAD version 3.> Its primary purpose is to obtain SIMBAD data,
though some rudimentary parsing functionality also exists.

There are three ways to access this data.

- URL queries are essentially page scrapers, but their use is
documented, and output is available as HTML, text, or VOTable. URL
queries are implemented by the url_query() method.

- Scripts may be submitted using the script() or script_file() methods.
The former takes as its argument the text of the script, the latter
takes a file name.

- Queries may be made using the web services (SOAP) interface. The
query() method implements this, and queryObjectByBib,
queryObjectByCoord, and queryObjectById have been provided as
convenience methods. The documentation speaks of this functionality as
under development. As of December 13 2006 'txt' queries work as
advertised, but 'vo' queries return empty VOTables. I<Caveat user.>

Astro::SIMBAD::Client is object-oriented, with the object supplying not
only the SIMBAD server name, but the default format and output type for
URL and web service queries.

A simple command line client application is also provided, as are
various examples in the F<eg> directory.

=head2 Methods

The following methods should be considered public:

=over 4

=cut

use strict;
use warnings;

package Astro::SIMBAD::Client;

use Carp;				# Standard
use LWP::UserAgent;			# Comes with libwww-perl
use HTTP::Request::Common qw{POST};	# Comes with libwww-perl
use SOAP::Lite;
use URI::Escape;			# Comes with libwww-perl
use XML::DoubleEncodedEntities;

our $VERSION = '0.006';

our @CARP_NOT = qw{Astro::SIMBAD::Client::WSQueryInterfaceService};

use constant FORMAT_TXT_SIMPLE_BASIC => <<'eod';
---\n
name: %IDLIST(NAME|1)\n
type: %OTYPE\n
long: %OTYPELIST\n
ra: %COO(d;A)\n
dec: %COO(d;D)\n
plx: %PLX(V)\n
pmra: %PM(A)\n
pmdec: %PM(D)\n
radial: %RV(V)\n
redshift: %RV(Z)\n
spec: %SP(S)\n
bmag: %FLUXLIST(B)[%flux(F)]\n
vmag: %FLUXLIST(V)[%flux(F)]\n
ident: %IDLIST[%*,]
eod

use constant FORMAT_TXT_YAML_BASIC => <<'eod';
---\n
name: '%IDLIST(NAME|1)'\n
type: '%OTYPE'\n
long: '%OTYPELIST'\n
ra: %COO(d;A)\n
dec: %COO(d;D)\n
plx: %PLX(V)\n
pm:\n
  - %PM(A)\n
  - %PM(D)\n
radial: %RV(V)\n
redshift: %RV(Z)\n
spec: %SP(S)\n
bmag: %FLUXLIST(B)[%flux(F)]\n
vmag: %FLUXLIST(V)[%flux(F)]\n
ident:\n%IDLIST[  - '%*'\n]
eod

#	Documentation errors/omissions:
#	%PLX:
#	     P = something. Yields '2' for Arcturus
#	%SP: is really %sptype
#	     B = bibcode? Yields '~' for Arcturus
#	     N = don't know -- yields 'S' for Arcturus
#	     Q = quality? Yields 'C' for Arcturus
#	     S = spectral type

use constant FORMAT_VO_BASIC => join ',', qw{
    id(NAME|1) otype ra dec plx_value pmra pmdec rv_value z_value
    sp_type flux(B) flux(V)};
    # Note that idlist was documented at one point as being the
    # VOTable equivalent of %IDLIST. But it is no longer documented,
    # and never returned anything but '<TD>?IDLIST</TD>'.

my %static = (
    autoload => 1,
    debug => 0,
    format => {
	txt => FORMAT_TXT_YAML_BASIC,
	vo => FORMAT_VO_BASIC,
	script => '',
    },
    parser => {
	txt => '',
	vo => '',
	script => '',
    },
    type => 'txt',
##    server => 'simweb.u-strasbg.fr',
    server => 'simbad.u-strasbg.fr',
    verbatim => 0,
);

=item $simbad = Astro::SIMBAD::Client->new ();

This method instantiates an Astro::SIMBAD::Client object. Any arguments will be
passed to the set() method once the object is instantiated.

=cut

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless {}, $class;
    $self->set (%static, @_);
    return $self;
}

=item @attribs = $simbad->attributes ();

This method retrieves the names of all public attributes, in
alphabetical order. It can be called as a static method, or
even as a subroutine.

=cut

sub attributes {
    wantarray ? sort keys %static : [sort keys %static]
}

=item $value = $simbad->get ($attrib);

This method retrieves the current value of the named
L<attribute|/Attributes>. It can be called as a static method to
retrieve the default value.

=cut

sub get {
    my $self = shift;
    croak "Error - First argument must be an @{[__PACKAGE__]} object"
	unless UNIVERSAL::isa ($self, __PACKAGE__);
    $self = \%static unless ref $self;
    my $name = shift;
    croak "Error - Attribute '$name' is unknown"
	unless exists $static{$name};
    return $self->{$name};
}

=item $result = Parse_TXT_Simple ($data);

This subroutine (B<not> method) parses the given text data under the
assumption that it was generated using FORMAT_TXT_SIMPLE_BASIC or
something similar. The data is expected to be formatted as follows:

A line consisting of exactly '---' separates objects.

Data appear on lines that look like

 name: data

and are parsed into a hash keyed by the given name. If the line ends
with a comma, it is assumed to contain multiple items, and the data
portion of the line is split on the commas; the resultant hash value
is a list reference.

The user would normally not call this directly, but specify it as the
parser for 'txt'-type queries:

 $simbad->set (parser => {txt => 'Parse_TXT_Simple'});

=cut

sub Parse_TXT_Simple {
    my $obj = {};
    my @data;
    foreach (split '\s*\n', $_[0]) {
	next unless $_;
	if (m/^-+$/) {
	    $obj = {};
	    push @data, $obj;
	} else {
	    my ($name, $val) = split ':\s*', $_;
	    $val =~ s/,$// and $val = [split ',', $val];
	    $obj->{$name} = $val;
	}
    }
    @data;
}


=item $result = Parse_VO_Table ($data);

This subroutine (B<not> method) parses the given VOTable data,
returning a list of anonymous hashes describing the data. The $data
value is split on '<?xml' before parsing, so that you get multiple
VOTables back (rather than a parse error) if that is what the input
contains.

This is B<not> a full-grown VOTable parser capable of handling
the full spec (see L<http://www.ivoa.net/Documents/latest/VOT.html>).
It is oriented toward returning E<lt>TABLEDATAE<gt> contents, and the
metadata that can reasonably be associated with those contents.

The return is a list of anonymous hashes, one per E<lt>TABLEE<gt>. Each
hash contains two keys:

  {data} is the data contained in the table, and
  {meta} is the metadata for the table.

The {meta} element for the table is a reference to a list of data
gathered from the E<lt>TABLEE<gt> tag. Element zero is the tag name
('TABLE'), and element 1 is a reference to a hash containing the
attributes of the E<lt>TABLEE<gt> tag. Subsequent elements if any
represent metadata tags in the order encountered in the parse.

The {data} contains an anonymous list, each element of which is a row of
data from the E<lt>TABLEDATAE<gt> element of the E<lt>TABLEE<gt>, in the
order encountered by the parse. Each row is a reference to a list of
anonymous hashes, which represent the individual data of the row, in the
order encountered by the parse. The data hashes contain two keys:

 {value} is the value of the datum with undef for '~', and
 {meta} is a reference to the metadata for the datum.

The {meta} element for a datum is a reference to the metadata tag that
describes that datum. This will be an anonymous list, of which element 0
is the tag ('FIELD'), element 1 is a reference to a hash containing that
tag's attributes, and subsequent elements will be the contents of the
tag (typically including a reference to the list representing the
E<lt>DESCRIPTIONE<gt> tag for that FIELD).

All values are returned as provided by the XML parser; no further
decoding is done. Specifically, the datatype and arraysize attributes
are ignored.

This parser is based on XML::Parser if that is available. Otherwise it
uses XML::Parser::Lite, which should be available since it comes with
SOAP::Lite.

The user would normally not call this directly, but specify it as the
parser for 'vo'-type queries:

 $simbad->set (parser => {vo => 'Parse_VO_Table'});

=cut

{	# Begin local symbol block.

    my $xml_parser;
    
    foreach (qw{XML::Parser XML::Parser::Lite}) {
	eval {_load_module ($_)};
	next if $@;
	$xml_parser = $_;
	last;
    }

    sub Parse_VO_Table {
	my $data = shift;

	my $root;
	my @tree;
	my @table;
	my @to_strip;

#	Arguments:
#	Init ($class)
#	Start ($class, $tag, $attr => $value ...)
#	Char ($class, $text)
#	End ($class, $tag)
#	Final ($class)

	my $psr = $xml_parser->new (
	    Handlers => {
		Init => sub {
		    $root = [];
		    @tree = ($root);
		    @table = ();
		},
		Start => sub {
		    shift;
		    my $tag = shift;
		    my $item = [$tag, {@_}];
		    push @{$tree[$#tree]}, $item;
		    push @tree, $item;
		},
		Char => sub {
		    push @{$tree[$#tree]}, $_[1];
		},
		End => sub {
		    my $tag = $_[1];
		    die <<eod unless @tree > 1;
Error - Unmatched end tag </$tag>
eod
		    die <<eod unless $tag eq $tree[$#tree][0];
Error - End tag </$tag> does not match start tag <$tree[$#tree][0]>
eod

#	From here to the end of the subroutine is devoted to detecting
#	the </TABLE> tag and extracting the data of the table into what
#	is hopefully a more usable format. Any relationship of tables
#	to resources is lost.

		    my $element = pop @tree;
		    if ($element->[0] eq 'TABLE') {
			my (@meta, @data, @descr);
			foreach (@$element) {
			    next unless ref $_ eq 'ARRAY';
			    if ($_->[0] eq 'FIELD') {
				push @meta, $_;
				push @descr, $_;
			    } elsif ($_->[0] eq 'DATA') {
				foreach (@$_) {
				    next unless ref $_ eq 'ARRAY';
				    next unless $_->[0] eq 'TABLEDATA';
				    foreach (@$_) {
					next unless ref $_ eq 'ARRAY';
					next unless $_->[0] eq 'TR';
					my @row;
					foreach (@$_) {
					    next unless ref $_ eq 'ARRAY';
					    next unless $_->[0] eq 'TD';
					    my @inf = grep {!ref $_} @$_;
					    shift @inf;
					    push @row, join ' ', @inf;
					}
					push @data, \@row;
				    }
				}
			    } else {
				push @descr, $_;
			    }
			}
			foreach (@data) {
			    my $inx = 0;
			    @$_ = map { {
				    value => (defined $_ && $_ eq '~')
					? undef : $_,
				    meta => $meta[$inx++],
				} } @$_;
			}
			push @to_strip, @descr;
			push @table, {
			    data => \@data,
			    meta => [$element->[0],
				$element->[1], @descr],
			};
		    }
		},
		Final => sub {
		    die <<eod if @tree > 1;
Error - Missing end tags.
eod

##		    _strip_empty ($root);
##		    @$root;
#	If the previous two lines were uncommented and the following two
#	commented, the parser would return the parse tree for the
#	VOTable.
		    _strip_empty (\@to_strip);
		    @table;
		},
	    });
	map {$_ ? $psr->parse ($_) : ()} split '(?=<\?xml)', $data
    }

}	# End of local symbol block.

#	_strip_empty (\@tree)
#
#	splices out anything in the tree that is not a reference and
#	does not match m/\S/.

sub _strip_empty {
    my $ref = shift;
    my $inx = @$ref;
    while (--$inx >= 0) {
	my $val = $ref->[$inx];
	my $typ = ref $val;
	if ($typ eq 'ARRAY') {
	    _strip_empty ($val);
	} elsif (!$typ) {
	    splice @$ref, $inx, 1 unless $val =~ m/\S/ms;
	}
    }
}

=item $result = $simbad->query ($query => @args);

This method issues a web services (SOAP) query to the SIMBAD database.
The $query specifies a SIMBAD query method, and the @args are the
arguments for that method.  Valid $query values and the corresponding
SIMBAD methods and arguments are:

  bib => queryObjectByBib ($bibcode, $format, $type)
  coo => queryObjectByCoord ($coord, $radius, $format, $type)
  id => queryObjectById ($id, $format, $type)

where:

  $bibcode is a SIMBAD bibliographic code
  $coord is a set of coordinates
  $radius is an angular radius around the coordinates
  $type is the type of data to be returned
  $format is a format appropriate to the data type.

The $type defaults to the value of the L<type|/type> attribute, and
the $format defaults to the value of the L<format|/format> attribute
for the given $type.

The return value depends on a number of factors:

If the query found nothing, you get undef in scalar context, and an
empty list in list context.

If a L<parser|/parser> is defined for the given type, the returned
data will be fed to the parser, and the output of the parser will be
returned. This is assumed to be a list, so a reference to the list
will be used in scalar context. Parser exceptions are not trapped,
so the caller will need to be prepared to deal with malformed data.

Otherwise, the result of the query is returned as-is.

I<Caveat:> Chapter 1 of the SIMBAD 4 Users Guide at
L<http://simbad.u-strasbg.fr/guide/ch01.htx> speaks of the Web Services
as 'to be developed'. They are documented in the help at
L<http://simbad.u-strasbg.fr/simbad/sim-help?Page=simbad4>, and this
method implements that interface to the best of my ability. But 'vo'
queries began returning empty VOTables on or about December 3 2006, and
as of January 26 2007 still behave this way. The 'txt' queries appear to
work.

=cut

{	# Begin local symbol block

    my %query_args = (
	id => {
	    type => 2,
	    format => 1,
	    method => 'queryObjectById',
	},
	bib => {
	    type => 2,
	    format => 1,
	    method => 'queryObjectByBib',
	},
	coo => {
	    type => 3,
	    format => 2,
	    method => 'queryObjectByCoord',
	},
    );

    my %transform = (
	txt => sub {local $_ = $_[0]; s/\n//gm; $_},
	vo => sub {
	    local $_ = ref $_[0] ? join (',', @{$_[0]}) : $_[0];
	    s/\s+/,/gms;
	    s/^,+//;
	    s/,+$//;
	    s/,+/,/g;
	    $_
	},
    );


    sub query {
	my $self = shift;
	my $query = shift;
	croak "Error - Illegal query type '$query'"
	    unless $query_args{$query};
	my $method = $query_args{$query}{method};
	croak "Programming error - Illegal query $query method $method"
	    unless Astro::SIMBAD::Client::WSQueryInterfaceService->can ($method);
	my $debug = $self->get ('debug');
	my @args = @_;
	my $parser;
	if (defined (my $type = $query_args{$query}{type})) {
	    $args[$type] ||= $self->get ('type');
	    if (defined (my $format = $query_args{$query}{format})) {
		$args[$format] ||= $self->get ('format')->{$args[$type]};
		$args[$format] = $transform{$args[$type]}->($args[$format])
		    if $transform{$args[$type]};
		warn "$args[$type] format: $args[$format]\n" if $debug;
		$args[$format] = undef unless $args[$format];
	    }
	    $parser = $self->_get_parser ($args[$type]);
	}
	SOAP::Lite->import (+trace => $debug ? 'all' : '-all');
##	$debug and SOAP::Trace->import ('all');
	my $resp = Astro::SIMBAD::Client::WSQueryInterfaceService->$method (
	    $self->get ('server'), @args);
	return unless defined $resp;
	$resp = XML::DoubleEncodedEntities::decode ($resp);
	return wantarray ? ($parser->($resp)) : [$parser->($resp)]
	    if $parser;
	return $resp;
    }

}	# End local symbol block.

=item $value = $simbad->queryObjectByBib ($bibcode, $format, $type);

This method is just a convenience wrapper for

 $value = $simbad->query (bib => $bibcode, $format, $type);

See the query() documentation for more information.

=cut

sub queryObjectByBib {
    my $self = shift;
    $self->query (bib => @_);
}

=item $value = $simbad->queryObjectByCoord ($coord, $radius, $format, $type);

This method is just a convenience wrapper for

 $value = $simbad->query (coo => $coord, $radius, $format, $type);

See the query() documentation for more information.

=cut

sub queryObjectByCoord {
    my $self = shift;
    $self->query (coo => @_);
}

=item $value = $simbad->queryObjectById ($id, $format, $type);

This method is just a convenience wrapper for

 $value = $simbad->query (id => $id, $format, $type);

See the query() documentation for more information.

=cut

sub queryObjectById {
    my $self = shift;
    $self->query (id => @_);
}

=item $value = $simbad->script ($script);

This method submits the given script to SIMBAD4. The $script variable
contains the text if the script; if you want to submit a script file
by name, use the script_file() method.

If the L<verbatim|/verbatim> attribute is false, the front matter of the
result (up to and including the '::data:::::' line) is stripped. If
there is no '::data:::::' line, the entire script output is raised as an
exception.

If a 'script' L<parser|/parser> was specified, the output of the script
(after stripping front matter if that was specified) is passed to it.
The parser is presumed to return a list, so if script() was called in
scalar context you get a reference to that list back.

If no 'script' L<parser|/parser> is specified, the output of the script
(after stripping front matter if that was specified) is simply returned
to the caller.

=cut

{

    my $escaper;

    sub script {
	my $self = shift;
	my $debug = $self->get ('debug');
	my $script = shift;
##    if (my $format = $self->get ('format')->{script}) {
##	$format =~ s/\n//gm;
##	$script = 'format obj "' . $format . "\"\n\n" . $script;
##    }

	$escaper ||= URI::Escape->can ('uri_escape_utf8') ||
	    URI::Escape->can ('uri_escape') || croak <<eod;
Error - URI::Escape does not implement uri_escape_utf8() or
        uri_escape(). Please upgrade.
eod
	$script = $escaper->($script);

	my $server = $self->get ('server');
	my $url = "http://$server/simbad/sim-script?" .
	    'submit=submit+script&script=' . $script;
	my $ua = LWP::UserAgent->new ();
	my $resp = $ua->get ($url);

	$resp->is_success or croak $resp->status_line;

	my $rslt = $resp->content or return;
	unless ($self->get ('verbatim')) {
	    $rslt =~ s/.*?::data:+\s*//sm or croak $rslt;
	}
	$rslt = XML::DoubleEncodedEntities::decode ($rslt);
	if (my $parser = $self->_get_parser ('script')) {
##	$rslt =~ s/.*?::data:+.?$//sm or croak $rslt;
	    my @rslt = $parser->($rslt);
	    return wantarray ? @rslt : \@rslt;
	} else {
	    return $rslt;
	}

    }

}


=item $value = $simbad->script_file ($filename);

This method submits the given script file to SIMBAD, returning the
result of the script. Unlike script(), the argument is the name of the
file containing the script, not the text of the script. However, if a
parser for 'script' has been specified, it will be applied to the
output.

=cut


sub script_file {
    my $self = shift;
    my $file = shift;

    my $server = $self->get ('server');
    my $url = "http://$server/simbad/sim-script";
    my $ua = LWP::UserAgent->new ();
    my $rqst = POST $url, 
	Content_Type => 'form-data',
	Content => [
	    submit => 'submit file',
	    CriteriaFile => [$file, undef],	# May need to specify Content_Type => application/octet-stream.
	];
    my $resp = $ua->request ($rqst);

    $resp->is_success or croak $resp->status_line;

    my $rslt = $resp->content or return;
    unless ($self->get ('verbatim')) {
	$rslt =~ s/.*?::data:+\s*//sm or croak $rslt;
    }
    if (my $parser = $self->_get_parser ('script')) {
##	$rslt =~ s/.*?::data:+.?$//sm or croak $rslt;
##	$rslt =~ s/\s+//sm;
	my @rslt = $parser->($rslt);
	return wantarray ? @rslt : \@rslt;
    } else {
	return $rslt;
    }

}

=item $simbad->set ($name => $value ...);

This method sets the value of the given L<attributes|/Attributes>. More
than one name/value pair may be specified. If called as a static method,
it sets the default value of the attribute.

=cut

{	# Begin local symbol block.

    my %mutator = (
	format => \&_set_hash,
	parser => \&_set_hash,
    );

    my %transform = (
	format => sub {
	    my ($self, $name, $val, $key) = @_;
	    if ($val !~ m/\W/ && (my $code = eval {
			$self->_get_coderef ($val)})) {
		$val = $code->();
	    }
	    $val;
	},
	parser => sub {
	    my ($self, $name, $val, $key) = @_;
	    if (!ref $val) {
		unless ($val =~ m/::/) {
		    my $pkg = $self->_parse_subroutine_name ($val);
		    $val = $pkg . '::' . $val;
		}
		$self->_get_coderef ($val);	# Just to see if we can.
	    } elsif (ref $val ne 'CODE') {
		croak "Error - $_[1] value must be scalar or code reference";
	    }
	    $val;
	},
    );

    foreach my $key (keys %static) {
	$transform{$key} ||= sub {$_[2]};
	$mutator{$key} ||= sub {
	    my $hash = ref $_[0] ? $_[0] : \%static;
	    $hash->{$_[1]} = $transform{$_[1]}->(@_)
	};
    }

    sub set {
	my $self = shift;
	croak "Error - First argument must be an @{[__PACKAGE__]} object"
	    unless UNIVERSAL::isa ($self, __PACKAGE__);
	while (@_) {
	    my $name = shift;
	    croak "Error - Attribute '$name' is unknown"
		unless exists $mutator{$name};
	    $mutator{$name}->($self, $name, shift);
	}
	$self;
    }

    sub _set_hash {
	my ($self, $name, $value) = @_;
	my $hash = ref $self ? $self : \%static;
	unless (ref $value) {
	    $value = {$value =~ m/=/ ?
		split ('=', $value, 2) : ($value => undef)};
	}
	$hash->{$name} = {} if $value->{clear};
	delete $value->{clear};
	foreach my $key (keys %$value) {
	    my $val = $value->{$key};
	    if (!defined $val) {
		delete $hash->{$name}{$key};
	    } elsif ($val) {
		$hash->{$name}{$key} =
		    $transform{$name}->($self, $name, $value->{$key}, $key);
	    } else {
		$hash->{$name}{$key} = '';
	    }
	}
    }

}	# End local symbol block.


=item $value = $simbad->url_query ($type => ...)

This method performs a query by URL, returning the results. The type
is one of:

 id = query by identifier,
 coo = query by coordinates,
 ref = query by references,
 sam = query by criteria.

The arguments depend on on the type, and are documented at
L<http://simbad.u-strasbg.fr/simbad/sim-help?Page=sim-url>. They are
specified as name => value. For example:

 $simbad->url_query (id =>
    Ident => 'Arcturus',
    NbIdent => 1
 );

Note that in an id query you must specify 'Ident' explicitly. This is
true in general, because it is not always possible to derive the first
argument name from the query type, and consistency was chosen over
brevity.

The output.format argument can be defaulted based on the object's type
setting as follows:

 txt becomes 'ASCII',
 vo becomes 'VOTable'.

Any other value is passed verbatim.

If the query succeeds, the results will be passed to the appropriate
parser if any. The reverse of the above translation is done to determine
the appropriate parser, so the 'vo' parser (if any) is called if
output.format is 'VOTable', and the 'txt' parser (if any) is called if
output.format is 'ASCII'. If output.format is 'HTML', you will need to
explicitly set up a parser for that.

=cut

{	# Begin local symbol block.

    my %type_map = (	# Map SOAP type parameter to URL output.format.
	txt	=> 'ASCII',
	vo	=> 'VOTable',
    );
    my %type_unmap;
    while (my ($key, $value) = each %type_map) {
	$type_unmap{$value} = $key;
    }

    sub url_query {
	my $self = shift;
	my $query = shift;
	my $url = 'http://' . $self->get ('server') . '/simbad/sim-' .
	    $query;
	my $ua = LWP::UserAgent->new ();
	@_ % 2 and croak <<eod;
Error - url_query needs an even number of arguments after the query
        type.
eod
	my %args = @_;
	unless ($args{'output.format'}) {
	    my $type = $self->get ('type');
	    $args{'output.format'} = $type_map{$type} || $type;
	}
	my $resp = $ua->post ($url, \%args);

	$resp->is_success or croak $resp->status_line;
	$resp = XML::DoubleEncodedEntities::decode ($resp->content);

	my $parser;
	if (my $type = $type_unmap{$args{'output.format'}}) {
	    $parser = $self->_get_parser ($type);
	    return wantarray ? ($parser->($resp)) : [$parser->($resp)]
		if $parser;
	}

	$resp;
    }

}	# End local symbol block.


########################################################################
#
#	Utility routines
#

#	$ref = $self->_get_coderef ($string)
#
#	Translates the given string into a code reference, loading
#	modules if needed. If the string is not a fully-qualified
#	subroutine name, it is assumed to be in the namespace of
#	the first caller not in this namespace. Failed loads are
#	cached so that they will not be tried again.

{

    sub _get_coderef {
	my $self = shift;
	my $parser = shift;
	if ($parser && !ref $parser) {
	    my ($pkg, $code, $file) =
		$self->_parse_subroutine_name ($parser);
	    unless ($parser = $pkg->can ($code) or !$self->get ('autoload')) {
		_load_module ($pkg);
		$parser = $pkg->can ($code);
	    }
	    $parser or croak "Error - ${pkg}::$code undefined";
	}
	$parser;
    }

}

#	$parser = $self->_get_parser ($type)

#	returns the code reference to the parser for the given type of
#	data, or false if none. An exception is thrown if the value
#	is a string which does not specify a defined subroutine.

sub _get_parser {
    my ($self, $type) = @_;
    $self->_get_coderef ($self->get ('parser')->{$type});
}

{	# begin local symbol block.

    my %tried = ('.pm' => 'No such module');

    sub _load_module {
	my $pkg = shift;
	(my $file = $pkg) =~ s|::|/|g;
	$file .= '.pm';
	unless ($INC{$file} || $tried{$file}) {
	    eval {require $file};
	    if ($@) {
		$tried{$file} = $@;
	    }
	}
	$tried{$file} and croak "Error - Unable to load $pkg";
    }

}	# end local symbol block.

#	($package, $subroutine, $file) = $self->_parse_subroutine_name ($name);
#
#	This method parses the given name, and returns the package name
#	in which the subroutine is defined, the subroutine name, and the
#	file name of the package in which the subroutine resides.  If
#	the $name is a bare subroutine name, the package is the calling
#	package unless that package contains no such subroutine but
#	$self->can($name) is true, in which case the package is
#	ref($self).
#
#	If called in scalar context, the package is returned.

sub _parse_subroutine_name {
    my ($self, $parser) = @_;
    my @parts = split '::', $parser;
    my $code = pop @parts;
    my $pkg = join '::', @parts;
    unless ($pkg) {
	my %tried = (__PACKAGE__, 1);
	my $inx = 1;
	while ($pkg = (caller ($inx++))[0]) {
	    next if $tried{$pkg};
	    $tried{$pkg} = 1;
	    last if $pkg->can ($code);
	}
	$pkg = ref $self if !$pkg && $self->can ($code);
	defined $pkg or croak <<eod;
Error - '$parser' yields undefined package name.
eod
	@parts = split '::', $pkg;
    }
    return wantarray ? ($pkg, $code, join ('/', @parts) . '.pm') : $pkg;
}


package Astro::SIMBAD::Client::WSQueryInterfaceService;
# Generated by SOAP::Lite (v0.69) for Perl -- soaplite.com
# Copyright (C) 2000-2006 Paul Kulchenko, Byrne Reese
# -- generated at [Thu Aug 31 16:25:31 2006]
# -- generated from http://simweb.u-strasbg.fr/axis/services/WSQuery?wsdl
my %methods = (
queryObjectById => {
##    endpoint => 'http://simweb.u-strasbg.fr:8080/axis/services/WSQuery',
    endpoint => 'http://%s/axis/services/WSQuery',
    soapaction => '',
    namespace => 'http://uif.simbad.cds',
    parameters => [
      SOAP::Data->new(name => 'in0', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in1', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in2', type => 'soapenc:string', attr => {}),
    ], # end parameters
  }, # end queryObjectById
queryObjectByBib => {
##    endpoint => 'http://simweb.u-strasbg.fr:8080/axis/services/WSQuery',
    endpoint => 'http://%s/axis/services/WSQuery',
    soapaction => '',
    namespace => 'http://uif.simbad.cds',
    parameters => [
      SOAP::Data->new(name => 'in0', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in1', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in2', type => 'soapenc:string', attr => {}),
    ], # end parameters
  }, # end queryObjectByBib
queryObjectByCoord => {
##    endpoint => 'http://simweb.u-strasbg.fr:8080/axis/services/WSQuery',
    endpoint => 'http://%s/axis/services/WSQuery',
    soapaction => '',
    namespace => 'http://uif.simbad.cds',
    parameters => [
      SOAP::Data->new(name => 'in0', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in1', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in2', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in3', type => 'soapenc:string', attr => {}),
    ], # end parameters
  }, # end queryObjectByCoord
); # end my %methods

use SOAP::Lite;
use Exporter;
use Carp ();
our @CARP_NOT = qw{SOAP::Lite};

use vars qw(@ISA $AUTOLOAD @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter SOAP::Lite);
@EXPORT_OK = (keys %methods);
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);

sub _call {
  my ($self, $method) = (shift, shift);
  my $name = UNIVERSAL::isa($method => 'SOAP::Data') ? $method->name : $method;
  my %method = %{$methods{$name}};
  ## TRW vvvv
  my $server = shift or Carp::croak "No server specified";;
  $method{endpoint} or Carp::croak "No server address (proxy) specified";
  my $endpoint = sprintf $method{endpoint}, $server;
  ## $self->proxy($method{endpoint} || Carp::croak "No server address (proxy) specified") 
  $self->proxy ($endpoint)
    unless $self->proxy;
  ## TRW ^^^^
  my @templates = @{$method{parameters}};
  my @parameters = ();
  foreach my $param (@_) {
    if (@templates) {
      my $template = shift @templates;
      my ($prefix,$typename) = SOAP::Utils::splitqname($template->type);
      my $method = 'as_'.$typename;
      # TODO - if can('as_'.$typename) {...}
      my $result = $self->serializer->$method($param, $template->name, $template->type, $template->attr);
      push(@parameters, $template->value($result->[2]));
    } else {
      push(@parameters, $param);
    }
  }

## TRW  $self->endpoint($method{endpoint})
## TRW       ->ns($method{namespace})
## TRW      ->on_action(sub{qq!"$method{soapaction}"!});

## vvv TRW

if ($self->can ('ns')) {
    $self->endpoint($endpoint)
	->ns($method{namespace})
	->on_action (sub{$method{soapaction}});
} else {
    $self->endpoint($endpoint)
	->envprefix ('soap')
	->uri($method{namespace})
	->on_action (sub{$method{soapaction}});
}

## ^^^ TRW

if ($self->serializer->can ('register_ns')) {	## TRW
$self->serializer->register_ns("http://schemas.xmlsoap.org/wsdl/soap/","wsdlsoap");
  $self->serializer->register_ns("http://schemas.xmlsoap.org/wsdl/","wsdl");
  $self->serializer->register_ns("http://uif.simbad.cds","intf");
  $self->serializer->register_ns("http://uif.simbad.cds","impl");
  $self->serializer->register_ns("http://schemas.xmlsoap.org/soap/encoding/","soapenc");
  $self->serializer->register_ns("http://xml.apache.org/xml-soap","apachesoap");
  $self->serializer->register_ns("http://www.w3.org/2001/XMLSchema","xsd");
}	## TRW
  my $som = $self->SUPER::call($method => @parameters); 
  if ($self->want_som) {
      return $som;
  }
  UNIVERSAL::isa($som => 'SOAP::SOM') ? wantarray ? $som->paramsall : $som->result : $som;
}

sub BEGIN {
  no strict 'refs';
  for my $method (qw(want_som)) {
    my $field = '_' . $method;
    *$method = sub {
      my $self = shift->new;
      @_ ? ($self->{$field} = shift, return $self) : return $self->{$field};
    }
  }
}
no strict 'refs';
for my $method (@EXPORT_OK) {
  my %method = %{$methods{$method}};
  *$method = sub {
    my $self = UNIVERSAL::isa($_[0] => __PACKAGE__) 
      ? ref $_[0] ? shift # OBJECT
                  # CLASS, either get self or create new and assign to self
                  : (shift->self || __PACKAGE__->self(__PACKAGE__->new))
      # function call, either get self or create new and assign to self
      : (__PACKAGE__->self || __PACKAGE__->self(__PACKAGE__->new));
    $self->_call($method, @_);
  }
}

sub AUTOLOAD {
  my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
  return if $method eq 'DESTROY' || $method eq 'want_som';
  die "Unrecognized method '$method'. List of available method(s): @EXPORT_OK\n";
}

1;

__END__

=back

=head2 Attributes

The Astro::SIMBAD::Client attributes are documented below. The type of
the attribute is given after the attribute name, in parentheses. The
types are:

 boolean - a true/false value (in the Perl sense);
 hash - a reference to one or more key/value pairs;
 integer - an integer;
 string - any characters.

Hash values may be specified either as hash references or as strings.
When a hash value is set, the given value updates the hash rather than
replacing it. For example, specifying

 $simbad->set (format => {txt => '%MAIN_ID\n'});

does not affect the value of the vo format. If a key is set to the
null value, it deletes the key. All keys in the hash can be deleted
by setting key 'clear' to any true value.

When specifying a string for a hash-valued attribute, it must be of
the form 'key=value'. For example,

 $simbad->set (format => 'txt=%MAIN_ID\n');

does the same thing as the previous example. Specifying the key name
without an = sign deletes the key (e.g. set (format => 'txt')).

The Astro::SIMBAD::Client class has the following attributes:

=over

=item autoload (boolean)

=for html <a name="autoload"></a>

This attribute determines whether setting the parser should attempt
to autoload its package.

The default is 1 (i.e. true).

=for html <a name="debug"></a>

=item debug (integer)

This attribute turns on debug output. It is unsupported in the sense
that the author makes no claim what will happen if it is non-zero.

The default value is 0.

=for html <a name="format"></a>

=item format (hash)

This attribute holds the default format for a given query()
output type. See
L<http://simweb.u-strasbg.fr/simbad/sim-help?Page=sim-fscript> for how
to specify formats for each output type. Output type 'script' is used to
specify a format for the script() method.

The format can be specified either literally, or as a subroutine name or
code reference. A string is assumed to be a subroutine name if it looks
like one (i.e. matches (\w+::)*\w+), and if the given subroutine is
actually defined. If no namespace is specified, all namespaces in the
call tree are checked. If a code reference or subroutine name is
specified, that code is executed, and the result becomes the format.

The following formats are defined in this module:

 FORMAT_TXT_SIMPLE_BASIC -
   a simple-to-parse text format providing basic information;
 FORMAT_TXT_YAML_BASIC -
   pseudo-YAML (parsable by YAML::Load) providing basic info;
 FORMAT_VO_BASIC -
   VOTable field names providing basic information.

The FORMAT_TXT_YAML_BASIC format attempts to provide data structured
similarly to the output of L<Astro::SIMBAD>, though
Astro::SIMBAD::Client does not bless the output into any class.

A simple way to examine these formats is (e.g.)

 use Astro::SIMBAD::Client;
 print Astro::SIMBAD::Client->FORMAT_TXT_YAML_BASIC;

Before a format is actually used it is preprocessed in a manner
depending on its intended output type. For 'vo' formats, leading and
trailing whitespace are stripped. For 'txt' and 'script' formats, line
breaks are stripped.

The default specifies formats for output types 'txt' and 'vo'. The
'txt' default is FORMAT_TXT_YAML_BASIC; the 'vo' default is
FORMAT_VO_BASIC.

There is no way to specify a default format for the 'script' or
'script_file' methods.

=for html <a name="parser"></a>

=item parser (hash)

This attribute specifies the parser for a given output type.

Parsers may be specified by either a code reference, or by the
text name of a subroutine. If specified as text and the name
is not qualified by a package name, the calling package is assumed.
The parser must be defined, and must take as its lone argument
the text to be parsed.

If the parser for a given output type is defined, query results of that
type will be passed to the parser, and the result returned. Otherwise
the query results will be returned verbatim.

The output types are anything legal for the query() method (i.e. 'txt'
and 'vo' at the moment), plus 'script' for a script parser. All default
to '', meaning no parser is used.

=for html <a name="server"></a>

=item server (string)

This attribute specifies the server to be used. As of January 26 2007,
only 'simbad.u-strasbg.fr' is valid, since as of that date Harvard
University has not yet converted their mirror to SIMBAD 4.

The default is 'simbad.u-strasbg.fr'.

=for html <a name="type"></a>

=item type (string)

This attribute specifies the default output type. Note that although
SIMBAD only defined types 'txt' and 'vo', we do not validate this,
since the SIMBAD web site hints at more types to come. SIMBAD appears
to treat an unrecognized type as 'txt'.

The default is 'txt'.

=for html <a name="verbatim"></a>

=item verbatim (boolean)

This attribute specifies whether script() and script_file() are to strip
the front matter from the script output. If false, everything up to and
including the '::data:::::' line is removed before passing the output to
the parser or returning it to the user. If true, the script output is
passed to the parser or returned to the user unmodified.

The default is 0 (i.e. false)

=back

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT

Copyright 2006, 2007 by Thomas R. Wyant, III (F<wyant at cpan dot org>).
All rights reserved.

This module is free software; you can use it, redistribute it and/or
modify it under the same terms as Perl itself. Please see
L<http://perldoc.perl.org/index-licence.html> for the current licenses.
