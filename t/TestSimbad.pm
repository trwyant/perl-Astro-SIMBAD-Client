package t::TestSimbad;

use strict;
use warnings;

use Astro::SIMBAD::Client;
use Test;

sub test {
    my $fh = shift;
    {
	my $loc = tell $fh;
	my $test = 0;
	my @todo;
	while (<$fh>) {
	    m/^\s*test\b/ and do {$test++; next};
	    m/^\s*todo\b/ and do {$test++; push @todo, $test; next};
	    m/^\s*access\b/ and do {
		eval {require LWP::UserAgent} or do {
		    print "1..0 # Skipped: Can not load LWP::UserAgent\n";
		    exit;
		};
		my $svr = Astro::SIMBAD::Client->get ('server');
		my $resp = LWP::UserAgent->new->get ("http://$svr/");
		$resp->is_success or do {
		    print "1..0 # Skipped: $svr @{[$resp->status_line]}\n";
		    exit;
		};
	    };
	}
	plan tests => $test, todo => \@todo;
	seek $fh, $loc, 0;
    }
    my $test = 0;
    my $class = 'Astro::SIMBAD::Client';
    my $smb = $class->new ();
    my $obj = $smb;
    my ($got, $ref, $skip, $want);
    while (<$fh>) {
	chomp;
	s/^\s+//;
	next unless $_;
	next if substr ($_, 0, 1) eq '#';
	s/\s+$//;
	my @args;
	foreach (split '\s+', $_) {
	    if (m/^<<(.+)$/) {
		my $eod = $1 . "\n";
		my $arg = '';
		while (<$fh>) {
		    last if $_ eq $eod;
		    $arg .= $_;
		}
		push @args, $arg;
	    } else {
		push @args, $_;
	    }
	}
	my $verb = shift @args;
	if ($verb eq 'static') {
	    $obj = $class;
	    $verb = shift;
	} else {
	    $obj = $smb;
	}
	if ($verb eq 'access') {
	} elsif ($verb eq 'clear') {
	    $got = $ref = undef;
	} elsif ($verb eq 'count') {
	    if (!defined $got) {
		$got = undef;
	    } elsif (ref $got eq 'ARRAY') {
		$got = @$got;
	    } else {
		die "Error - \$got does not refer to a list.\n";
	    }
	} elsif ($verb eq 'deref' || $verb eq 'deref_curr') {
	    $got = $ref unless $verb eq 'deref_curr';
	    foreach my $key (@args) {
		my $type = ref $got;
		if ($type eq 'ARRAY') {
		    $got = $got->[$key];
		} elsif ($type eq 'HASH') {
		    $got = $got->{$key};
		} else {
		    $got = undef;
		}
	    }
	} elsif ($verb eq 'dump') {
	    require Data::Dumper;
	    local $Data::Dumper::Terse = 1;
	    warn "\$got = ", Data::Dumper::Dumper ($got);
	} elsif ($verb eq 'find') {
	    my $target = pop @args;
	    if (ref $got eq 'ARRAY') {
		foreach my $item (@$got) {
		    my $test = $item;
		    foreach my $key (@args) {
			my $type = ref $test;
			if ($type eq 'ARRAY') {
			    $test = $test->[$key];
			} elsif ($type eq 'HASH') {
			    $test = $test->{$key};
			} else {
			    $test = undef;
			} 
		    }
		    defined $test && $test eq $target
		       and do {$got = $item; last;};
		}
	    }
	} elsif ($verb eq 'require') {
	    $skip = @args > 1 ? ("Can not load any of " . join (', ', @args)) :
		@args ? "Can not load @args" : '';
	    foreach (@args) {
		eval "require $_";
		$@ or do {$skip = ''; last};
	    }
	} elsif ($verb eq 'test' || $verb eq 'todo') {
	    $test++;
	    $got = 'undef' unless defined $got;
	    chomp $got;
	    chomp $want;
	    print <<eod;
#
# Test $test - @args
#     Expect: $want
#        Got: $got
eod
	    if (numberp ($want) && numberp ($got)) {
		skip ($skip, $want == $got);
	    } else {
		skip ($skip, $want eq $got);
	    }
	} elsif ($verb eq 'want') {
	    $want = shift @args;
	} elsif ($obj->can ($verb)) {
	    unless ($skip) {
		$got = eval {$obj->$verb (@args)};
		if ($@) {
		    warn $@;
		    $got = $@;
		}
		$ref = $got if ref $got;
	    }
	} else {
	    die "Error - $class does not support method $verb\n";
	}
    }
}


sub numberp {
    $_[0] =~ m/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/
}

1;
