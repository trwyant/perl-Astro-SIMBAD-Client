use strict;
use warnings;

use t::TestSimbad;

t::TestSimbad::test (*DATA);

__END__

access

set type txt
set format txt=FORMAT_TXT_SIMPLE_BASIC
set parser txt=Parse_TXT_Simple

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

deref 0 pmra
want_load arcturus pmra
test query id Arcturus (txt) - proper motion in right ascension

deref 0 pmdec
want_load arcturus pmdec
test query id Arcturus (txt) - proper motion in declination

deref 0 radial
want_load arcturus radial
test query id Arcturus (txt) - radial velocity in recession

clear
noskip
set parser script=Parse_TXT_Simple

echo <<eod

The following tests use the script interface
eod

script <<eod
format obj "---\nname: %idlist(NAME|1)\ntype: %otype\nlong: %otypelist\nra: %coord(d;A)\ndec: %coord(d;D)\nplx: %plx(V)\npmra: %pm(A)\npmdec: %pm(D)\nradial: %rv(V)\nredshift: %rv(Z)\nspec: %sptype(S)\nbmag: %fluxlist(B)[%flux(F)]\nvmag: %fluxlist(V)[%flux(F)]\nident: %idlist[%*,]\n"
query id arcturus
eod

count
want 1
test script 'query id arcturus' - number of objects returned

deref 0 name
want_load arcturus name
test script 'query id arcturus' - name

deref 0 ra
want_load arcturus ra
test script 'query id arcturus' - right ascension

deref 0 dec
want_load arcturus dec
test script 'query id arcturus' - declination

deref 0 plx
want_load arcturus plx
test script 'query id arcturus' - parallax

deref 0 pmra
want_load arcturus pmra
test script 'query id arcturus' - proper motion in right ascension

deref 0 pmdec
want_load arcturus pmdec
test script 'query id arcturus' - proper motion in declination

deref 0 radial
want_load arcturus radial
test script 'query id arcturus' - radial velocity in recession

clear

echo <<eod

The following tests use the script_file interface
eod

script_file t/arcturus.simple

count
want 1
test script_file t/arcturus.simple - number of objects returned

deref 0 name
want_load arcturus name
test script_file t/arcturus.simple - name

deref 0 ra
want_load arcturus ra
test script_file t/arcturus.simple - right ascension

deref 0 dec
want_load arcturus dec
test script_file t/arcturus.simple - declination

deref 0 plx
want_load arcturus plx
test script_file t/arcturus.simple - parallax

deref 0 pmra
want_load arcturus pmra
test script_file t/arcturus.simple - proper motion in right ascension

deref 0 pmdec
want_load arcturus pmdec
test script_file t/arcturus.simple - proper motion in declination

deref 0 radial
want_load arcturus radial
test script_file t/arcturus.simple - radial velocity in recession
