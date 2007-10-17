use strict;
use warnings;

use t::TestSimbad;

t::TestSimbad::test (*DATA);

__END__

access

set type txt
set format txt=FORMAT_TXT_SIMPLE_BASIC
set parser txt=Parse_TXT_Simple

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

deref 0 pmra
want -1093.43
test query id Arcturus (txt) - proper motion in right ascension

deref 0 pmdec
want -1999.43
test query id Arcturus (txt) - proper motion in declination

deref 0 radial
want -5.2
test query id Arcturus (txt) - radial velocity in recession

clear
set parser script=Parse_TXT_Simple

script <<eod
format obj "---\nname: %idlist(NAME|1)\ntype: %otype\nlong: %otypelist\nra: %coord(d;A)\ndec: %coord(d;D)\nplx: %plx(V)\npmra: %pm(A)\npmdec: %pm(D)\nradial: %rv(V)\nredshift: %rv(Z)\nspec: %sptype(S)\nbmag: %fluxlist(B)[%flux(F)]\nvmag: %fluxlist(V)[%flux(F)]\nident: %idlist[%*,]\n"
query id arcturus
eod

count
want 1
test script 'query id arcturus' - number of objects returned

deref 0 name
want <<eod
NAME ARCTURUS
eod
test script 'query id arcturus' - name

deref 0 ra
want 213.9153
test script 'query id arcturus' - right ascension

deref 0 dec
want 19.1824103
test script 'query id arcturus' - declination

deref 0 plx
want 88.85
test script 'query id arcturus' - parallax

deref 0 pmra
want -1093.43
test script 'query id arcturus' - proper motion in right ascension

deref 0 pmdec
want -1999.43
test script 'query id arcturus' - proper motion in declination

deref 0 radial
want -5.2
test script 'query id arcturus' - radial velocity in recession

clear

script_file t/arcturus.simple

count
want 1
test script_file t/arcturus.simple - number of objects returned

deref 0 name
want <<eod
NAME ARCTURUS
eod
test script_file t/arcturus.simple - name

deref 0 ra
want 213.9153
test script_file t/arcturus.simple - right ascension

deref 0 dec
want 19.1824103
test script_file t/arcturus.simple - declination

deref 0 plx
want 88.85
test script_file t/arcturus.simple - parallax

deref 0 pmra
want -1093.43
test script_file t/arcturus.simple - proper motion in right ascension

deref 0 pmdec
want -1999.43
test script_file t/arcturus.simple - proper motion in declination

deref 0 radial
want -5.2
test script_file t/arcturus.simple - radial velocity in recession
