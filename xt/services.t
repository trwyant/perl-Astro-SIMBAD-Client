package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::SIMBAD::Client::Test;

Astro::SIMBAD::Client::Test::test (*DATA);

1;
__END__

access

echo <<eod

Test individual format effectors of the web services (SOAP) interface
eod

load t/canned.data

set type txt
set parser txt=

set format txt=%IDLIST(NAME|1)
query id Arcturus

want_load arcturus name
test query id Arcturus -- %IDLIST(NAME|1)

set format txt=%OTYPE
query id Arcturus

want_load arcturus type
test query id Arcturus -- %OTYPE

set format txt=%OTYPELIST
query id Arcturus

want_load arcturus long
test query id Arcturus -- %OTYPELIST

set format txt=%COO(d;A)
query id Arcturus

want_load arcturus ra
test query id Arcturus -- %COO(d;A)

set format txt=%COO(d;D)
query id Arcturus

want_load arcturus dec
test query id Arcturus -- %COO(d;D)

set format txt=%PLX(V)
query id Arcturus

want_load arcturus plx
test query id Arcturus -- %PLX(V)

set format txt=%PM(A)
query id Arcturus

want_load arcturus pmra
test query id Arcturus -- %PM(A)

set format txt=%PM(D)
query id Arcturus

want_load arcturus pmdec
test query id Arcturus -- %PM(D)

set format txt=%RV(V)
query id Arcturus

want_load arcturus radial
test query id Arcturus -- %RV(V)

set format txt=%RV(Z)
query id Arcturus

want_load arcturus redshift
test query id Arcturus -- %RV(Z)

set format txt=%SP(S)
query id Arcturus

want_load arcturus spec
test query id Arcturus -- %SP(S)

set format txt=%FLUXLIST(B)[%flux(F)]
query id Arcturus

want_load arcturus bmag
test query id Arcturus -- %FLUXLIST(B)[%flux(F)]

set format txt=%FLUXLIST(V)[%flux(F)]
query id Arcturus

want_load arcturus vmag
test query id Arcturus -- %FLUXLIST(V)[%flux(F)]

end

set format txt=%IDLIST
query id Arcturus

want_load ident
test query id Arcturus -- %IDLIST

