#!/usr/local/bin/perl

use strict;
use warnings;

use t::TestSimbad;

t::TestSimbad::test (*DATA);

__DATA__

access

require YAML

set type txt
set parser txt=YAML::Load
set format txt=FORMAT_TXT_YAML_BASIC

query id Arcturus

count
want 1
test query id Arcturus (txt) - number of objects returned

deref 0 name
want <<eod
NAME ARCTURUS
eod
test query id Arcturus (txt) - name

deref 0 ra
want 213.9153
test query id Arcturus (txt) - right ascension

deref 0 dec
want 19.1824103
test query id Arcturus (txt) - declination

deref 0 plx
want 88.85
test query id Arcturus (txt) - parallax

deref 0 pm 0
want -1093.43
test query id Arcturus (txt) - proper motion in right ascension

deref 0 pm 1
want -1999.43
test query id Arcturus (txt) - proper motion in declination

deref 0 radial
want -5.2
test query id Arcturus (txt) - radial velocity in recession

clear
set parser script=YAML::Load

script <<eod
format obj "---\nname: '%idlist(NAME|1)'\ntype: '%otype'\nlong: '%otypelist'\nra: %coord(d;A)\ndec: %coord(d;D)\nplx: %plx(V)\npm:\n  - %pm(A)\n  - %pm(D)\nradial: %rv(V)\nredshift: %rv(Z)\nspec: %sptype(S)\nbmag: %fluxlist(B)[%flux(F)]\nvmag: %fluxlist(V)[%flux(F)]\nident:\n%idlist[  - '%*'\n]"
query id arcturus
eod

count
want 1
test script 'query id Arcturus' - number of objects returned

deref 0 name
want <<eod
NAME ARCTURUS
eod
test script 'query id Arcturus' - name

deref 0 ra
want 213.9153
test script 'query id Arcturus' - right ascension

deref 0 dec
want 19.1824103
test script 'query id Arcturus' - declination

deref 0 plx
want 88.85
test script 'query id Arcturus' - parallax

deref 0 pm 0
want -1093.43
test script 'query id Arcturus' - proper motion in right ascension

deref 0 pm 1
want -1999.43
test script 'query id Arcturus' - proper motion in declination

deref 0 radial
want -5.2
test script 'query id Arcturus' - radial velocity in recession


clear

script_file t/arcturus.yaml

count
want 1
test script_file t/arcturus.yaml - number of objects returned

deref 0 name
want <<eod
NAME ARCTURUS
eod
test script_file t/arcturus.yaml - name

deref 0 ra
want 213.9153
test script_file t/arcturus.yaml - right ascension

deref 0 dec
want 19.1824103
test script_file t/arcturus.yaml - declination

deref 0 plx
want 88.85
test script_file t/arcturus.yaml - parallax

deref 0 pm 0
want -1093.43
test script_file t/arcturus.yaml - proper motion in right ascension

deref 0 pm 1
want -1999.43
test script_file t/arcturus.yaml - proper motion in declination

deref 0 radial
want -5.2
test script_file t/arcturus.yaml - radial velocity in recession

