use strict;
use warnings;

use t::TestSimbad;

t::TestSimbad::test (*DATA);

__END__

access

release
want_re (?i:^SIMBAD4\b)
test Scalar release()

release[0]
want 4
test Major version number
