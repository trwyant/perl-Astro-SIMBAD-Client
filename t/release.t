package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::SIMBAD::Client::Test;

access;

call 'release';
test qr{ \A SIMBAD4 \b }smxi, 'Scalar release()';

call_a 'release';
deref 0;
test 4, 'Major version number';

end;


1;
