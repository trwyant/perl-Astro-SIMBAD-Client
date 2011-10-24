package main;

use strict;
use warnings;

use lib qw{ inc };

use Astro::SIMBAD::Client::Test;


access;

# If I choose to try more of the possible YAML modules, I need to do
# three things:
# * Add the possible modules to load_module, below
# * Add the appropriate module_loaded wherever needed below.
# * Add the possible modules to the @hide array in
#   inc/Astro/SIMBAD/Client/Build.pm

load_module qw{ YAML YAML::Syck };

call set => type => 'txt';
module_loaded 'YAML',       call => set => parser => 'txt=YAML::Load';
module_loaded 'YAML::Syck', call => set => parser => 'txt=YAML::Syck::Load';
call set => format => 'txt=FORMAT_TXT_YAML_BASIC';

load_data 't/canned.data';

echo <<'EOD';

Test the formatting and handling of YAML

The following tests use the query (SOAP) interface
EOD

call query => id => 'Arcturus';
count;
test 1, 'query id Arcturus (txt) - number of objects returned';

deref 0, 'name';
test canned( arcturus => 'name' ), 'query id Arcturus (txt) - name';

deref 0, 'ra';
test canned( arcturus => 'ra' ), 'query id Arcturus (txt) - right ascension';

deref 0, 'dec';
test canned( arcturus => 'dec' ), 'query id Arcturus (txt) - declination';

deref 0, 'plx';
test canned( arcturus => 'plx' ), 'query id Arcturus (txt) - parallax';

deref 0, 'pm', 0;
test canned( arcturus => 'pmra' ),
    'query id Arcturus (txt) - proper motion in right ascension';

deref 0, 'pm', 1;
test canned( arcturus => 'pmdec' ),
    'query id Arcturus (txt) - proper motion in declination';

deref 0, 'radial';
test canned( arcturus => 'radial' ),
    'query id Arcturus (txt) - radial velocity in recession';


# Maybe we're skipping because of a problem with SOAP; so we clear
# the skip indicator. We re-require after this, because maybe we're
# skipping because of missing modules.

clear;
load_module qw{ YAML YAML::Syck };
module_loaded 'YAML',       call => set => parser => 'script=YAML::Load';
module_loaded 'YAML::Syck', call => set => parser => 'script=YAML::Syck::Load';

echo <<'EOD';

The following tests use the script interface
EOD

call script => <<'EOD';
format obj "---\nname: '%idlist(NAME|1)'\ntype: '%otype'\nlong: '%otypelist'\nra: %coord(d;A)\ndec: %coord(d;D)\nplx: %plx(V)\npm:\n  - %pm(A)\n  - %pm(D)\nradial: %rv(V)\nredshift: %rv(Z)\nspec: %sptype(S)\nbmag: %fluxlist(B)[%flux(F)]\nvmag: %fluxlist(V)[%flux(F)]\nident:\n%idlist[  - '%*'\n]"
query id arcturus
EOD

count;
test 1, q{script 'query id Arcturus' - number of objects returned};

deref 0, 'name';
test canned( arcturus => 'name' ), q{script 'query id Arcturus' - name};

deref 0, 'ra';
test canned( arcturus => 'ra' ),
    q{script 'query id Arcturus' - right ascension};

deref 0, 'dec';
test canned( arcturus => 'dec' ),
    q{script 'query id Arcturus' - declination};

deref 0, 'plx';
test canned( arcturus => 'plx' ), q{script 'query id Arcturus' - parallax};

deref 0, 'pm', 0;
test canned( arcturus => 'pmra' ),
    q{script 'query id Arcturus' - proper motion in right ascension};

deref 0, 'pm', 1;
test canned( arcturus => 'pmdec' ),
    q{script 'query id Arcturus' - proper motion in declination};

deref 0, 'radial';
test canned( arcturus => 'radial' ),
    q{script 'query id Arcturus' - radial velocity in recession};



# Maybe we're skipping because of a problem with SOAP; so we clear
# the skip indicator. We re-require after this, because maybe we're
# skipping because of missing modules.

clear;
load_module qw{ YAML YAML::Syck };
module_loaded 'YAML',       call => set => parser => 'script=YAML::Load';
module_loaded 'YAML::Syck', call => set => parser => 'script=YAML::Syck::Load';

echo <<'EOD';

The following tests use the script_file interface
EOD

call script_file => 't/arcturus.yaml';
#{
#    my $rtn = returned_value;
#    $rtn = defined $rtn ? "'$rtn'" : 'undef';
#    diag "Debug - script_file( 't/arcturus.yaml' ) returned $rtn";
#}
count;
test 1, 'script_file t/arcturus.yaml - number of objects returned';

deref 0, 'name';
test canned( arcturus => 'name' ), 'script_file t/arcturus.yaml - name';

deref 0, 'ra';
test canned( arcturus => 'ra' ),
    'script_file t/arcturus.yaml - right ascension';

deref 0, 'dec';
test canned( arcturus => 'dec' ),
    'script_file t/arcturus.yaml - declination';

deref 0, 'plx';
test canned( arcturus => 'plx' ), 'script_file t/arcturus.yaml - parallax';

deref 0, 'pm', 0;
test canned( arcturus => 'pmra' ),
    'script_file t/arcturus.yaml - proper motion in right ascension';

deref 0, 'pm', 1;
test canned( arcturus => 'pmdec' ),
    'script_file t/arcturus.yaml - proper motion in declination';

deref 0, 'radial';
test canned( arcturus => 'radial' ),
    'script_file t/arcturus.yaml - radial velocity in recession';



end;


1;

# ex: set textwidth=72 :
