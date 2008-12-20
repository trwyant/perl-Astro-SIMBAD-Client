package main;

use strict;
use warnings;

my $skip;
BEGIN {
    eval {
	require Test::Spelling;
	Test::Spelling->import();
    };
    $@ and do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
}

our $VERSION = '0.002_01';

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
CGI
CPAN
IDs
Ident
Jul
SIMBAD
Oct
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
sexagesimal
simbad
simbadc
simweb
strasbg
todo
txt
vo
vohash
