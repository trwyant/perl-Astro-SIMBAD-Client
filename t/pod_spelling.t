#!/usr/local/bin/perl

use strict;
use warnings;

my $skip;
BEGIN {
    eval "use Test::Spelling";
    $@ and do {
	eval "use Test";
	plan (tests => 1);
	$skip = 'Test::Spelling not available';;
    };
}

our $VERSION = '0.001_01';

if ($skip) {
    skip ($skip, 1);
} else {
    add_stopwords (<DATA>);

    all_pod_files_spelling_ok ();
}
__DATA__
CGI
CPAN
IDs
Ident
Jul
SIMBAD
VOTable
VOTables
Wyant
YAML
arraysize
datatype
fr
metadata
obj
preprocessed
queryObjectByBib
queryObjectByCoord
queryObjectById
simbad
simbadc
simweb
strasbg
txt
vo
vohash
