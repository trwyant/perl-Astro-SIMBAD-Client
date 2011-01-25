package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	Test::Spelling->import();
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
}

our $VERSION = '0.018';

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
