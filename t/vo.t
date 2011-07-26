package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::SIMBAD::Client::Test;

Astro::SIMBAD::Client::Test::test (*DATA);

1;
__DATA__

access

require XML::Parser XML::Parser::Lite

load t/canned.data

set type vo
set parser vo=Parse_VO_Table

echo <<eod

The following tests use the query (SOAP) interface
eod

query id Arcturus

count
want 1
test query id Arcturus (vo) - count of tables

# For a long time the following did not work. Because the problem
# appeared to be on the SIMBAD end, they were 'todo'.

deref 0 data
count
want 1
test query id arcturus (vo) - count of rows

deref 0 data 0 0 value
want_load arcturus name
test query id Arcturus (vo) - name

deref 0 data 0 2 value
want_load arcturus ra
test query id Arcturus (vo) - right ascension

deref 0 data 0 3 value
want_load arcturus dec
test query id Arcturus (vo) - declination

deref 0 data 0 4 value
want_load arcturus plx
test query id Arcturus (vo) - parallax

deref 0 data 0 5 value
want_load arcturus pmra
test query id Arcturus (vo) - proper motion in right ascension

deref 0 data 0 6 value
want_load arcturus pmdec
test query id Arcturus (vo) - proper motion in declination

deref 0 data 0 7 value
want_load arcturus radial
test query id Arcturus (vo) - radial velocity

# For a long time the previous was 'todo'

echo <<eod

The following tests use the script_file interface
eod

noskip
require XML::Parser XML::Parser::Lite
set parser script=Parse_VO_Table
script_file t/arcturus.vo

count
want 1
test script_file t/arcturus.vo - count table

deref 0 data
count
want 1
test script_file t/arcturus.vo - count rows

deref 0 data 0 0 value
want_load arcturus name
test script_file t/arcturus.vo - name

deref 0 data 0 2 value
want_load arcturus ra
test script_file t/arcturus.vo - right ascension

deref 0 data 0 3 value
want_load arcturus dec
test script_file t/arcturus.vo - declination

deref 0 data 0 4 value
want_load arcturus plx
test script_file t/arcturus.vo - parallax

deref 0 data 0 5 value
want_load arcturus pmra
test script_file t/arcturus.vo - proper motion in right ascension

deref 0 data 0 6 value
want_load arcturus pmdec
test script_file t/arcturus.vo - proper motion in declination

deref 0 data 0 7 value
want_load arcturus radial
test script_file t/arcturus.vo - radial velocity

echo <<eod

The following tests use the url_query interface
eod

noskip
require XML::Parser XML::Parser::Lite
set url_args coodisp1=d
url_query id Ident Arcturus

count
want 1
test url_query id Arcturus (vo) - count of tables

deref 0 data
count
want 1
test url_query id arcturus (vo) - count of rows

deref 0 data 0
find meta 1 name MAIN_ID
deref_curr value
want_load arcturus name
test url_query id Arcturus (vo) - name

deref 0 data 0
find meta 1 name RA
deref_curr value
# want 213.9153
# As of about SIMBAD4 1.005 the default became sexagesimal
# As of 1.069 (probably much earlier) you can set coodisp1=d to display
# in decimal. But this seems not to work for VOTable output.
# As of 1.117 (April 9 2009) votable output went back to decimal. The
# coodisp option still seems not to affect it, though.
# want_load arcturus ra_hms
want_load arcturus ra
test url_query id Arcturus (vo) - right ascension

deref 0 data 0
find meta 1 name DEC
deref_curr value
# want +19.18241027778
# As of about SIMBAD4 1.005 the default became sexigesimal
# As of 1.069 (probably much earlier) you can set coodisp1=d to display
# in decimal. But this seems not to work for VOTable output.
# As of 1.117 (April 9 2009) votable output went back to decimal. The
# coodisp option still seems not to affect it, though.
# want_load arcturus dec_dms
want_load arcturus dec
test url_uery id Arcturus (vo) - declination

deref 0 data 0
find meta 1 name PLX_VALUE
deref_curr value
want_load arcturus plx
test url_query id Arcturus (vo) - parallax

deref 0 data 0
find meta 1 name PMRA
deref_curr value
want_load arcturus pmra
test url_query id Arcturus (vo) - proper motion in right ascension

deref 0 data 0
find meta 1 name PMDEC
deref_curr value
want_load arcturus pmdec
test url_query id Arcturus (vo) - proper motion in declination

deref 0 data 0
find meta 1 name oRV:RVel
deref_curr value
# Velocity in recession retrieved by every method but this changed on or
# about July 25 2011 to -5.19.
# want_load arcturus radial
want -5.2
test url_query id Arcturus (vo) - radial velocity

