package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::SIMBAD::Client::Test;

Astro::SIMBAD::Client::Test::test (*DATA);

1;
__END__

access

release
want_re (?i:^SIMBAD4\b)
test Scalar release()

release[0]
want 4
test Major version number
