package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::SIMBAD::Client::Test;

Astro::SIMBAD::Client::Test::test (*DATA);

1;
__DATA__

access

require YAML YAML::Syck

set type txt
loaded YAML set parser txt=YAML::Load
loaded YAML::Syck set parser txt=YAML::Syck::Load
set format txt=FORMAT_TXT_YAML_BASIC

load t/canned.data

echo <<eod

The following tests use the query (SOAP) interface
eod

query id Arcturus

count
want 1
test query id Arcturus (txt) - number of objects returned

deref 0 name
want_load arcturus name
test query id Arcturus (txt) - name

deref 0 ra
want_load arcturus ra
test query id Arcturus (txt) - right ascension

deref 0 dec
want_load arcturus dec
test query id Arcturus (txt) - declination

deref 0 plx
want_load arcturus plx
test query id Arcturus (txt) - parallax

deref 0 pm 0
want_load arcturus pmra
test query id Arcturus (txt) - proper motion in right ascension

deref 0 pm 1
want_load arcturus pmdec
test query id Arcturus (txt) - proper motion in declination

deref 0 radial
want_load arcturus radial
test query id Arcturus (txt) - radial velocity in recession

# Maybe we're skipping because of a problem with SOAP; so we clear
# the skip indicator. We re-require after this, because maybe we're
# skipping because of missing modules.

noskip
require YAML YAML::Syck
loaded YAML set parser script=YAML::Load
loaded YAML::Syck set parser script=YAML::Syck::Load

clear

echo <<eod

The following tests use the script interface
eod

script <<eod
format obj "---\nname: '%idlist(NAME|1)'\ntype: '%otype'\nlong: '%otypelist'\nra: %coord(d;A)\ndec: %coord(d;D)\nplx: %plx(V)\npm:\n  - %pm(A)\n  - %pm(D)\nradial: %rv(V)\nredshift: %rv(Z)\nspec: %sptype(S)\nbmag: %fluxlist(B)[%flux(F)]\nvmag: %fluxlist(V)[%flux(F)]\nident:\n%idlist[  - '%*'\n]"
query id arcturus
eod

count
want 1
test script 'query id Arcturus' - number of objects returned

deref 0 name
want_load arcturus name
test script 'query id Arcturus' - name

deref 0 ra
want_load arcturus ra
test script 'query id Arcturus' - right ascension

deref 0 dec
want_load arcturus dec
test script 'query id Arcturus' - declination

deref 0 plx
want_load arcturus plx
test script 'query id Arcturus' - parallax

deref 0 pm 0
want_load arcturus pmra
test script 'query id Arcturus' - proper motion in right ascension

deref 0 pm 1
want_load arcturus pmdec
test script 'query id Arcturus' - proper motion in declination

deref 0 radial
want_load arcturus radial
test script 'query id Arcturus' - radial velocity in recession


clear

echo <<eod

The following tests use the script_file interface
eod

script_file t/arcturus.yaml

count
want 1
test script_file t/arcturus.yaml - number of objects returned

deref 0 name
want_load arcturus name
test script_file t/arcturus.yaml - name

deref 0 ra
want_load arcturus ra
test script_file t/arcturus.yaml - right ascension

deref 0 dec
want_load arcturus dec
test script_file t/arcturus.yaml - declination

deref 0 plx
want_load arcturus plx
test script_file t/arcturus.yaml - parallax

deref 0 pm 0
want_load arcturus pmra
test script_file t/arcturus.yaml - proper motion in right ascension

deref 0 pm 1
want_load arcturus pmdec
test script_file t/arcturus.yaml - proper motion in declination

deref 0 radial
want_load arcturus radial
test script_file t/arcturus.yaml - radial velocity in recession

