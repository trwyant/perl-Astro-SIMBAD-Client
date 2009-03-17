package t::TestSimbad;

use strict;
use warnings;

use Astro::SIMBAD::Client;
use Test;

my %loaded;

sub test {
    my $fh = shift;
    {
	my $loc = tell $fh;
	my $test = 0;
	my @todo;
	while (<$fh>) {
	    m/^\s*end\b/ and last;
	    m/^\s*test\b/ and do {$test++; next};
	    m/^\s*todo\b/ and do {$test++; push @todo, $test; next};
	    m/^\s*access\b/ and do {
		eval {require LWP::UserAgent} or do {
		    print "1..0 # skip Can not load LWP::UserAgent\n";
		    exit;
		};
		my $svr = Astro::SIMBAD::Client->get ('server');
		my $resp = LWP::UserAgent->new->get ("http://$svr/");
		$resp->is_success or do {
		    print "1..0 # skip $svr @{[$resp->status_line]}\n";
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
    my ($canned, $got, $ref, $skip, $want);
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
	if ($verb eq 'loaded') {
	    $loaded{shift @args} or next;
	    $verb = shift @args;
	    ($verb eq 'test' || $verb eq 'todo')
		and die "'test' or 'todo' in 'loaded' not supported";
	}
	if ($verb eq 'static') {
	    $obj = $class;
	    $verb = shift;
	} else {
	    $obj = $smb;
	}
	my $index;
	if ($verb =~ s/\[(\d+)\]$//) {
	    $index = $1;
	}
	if ($verb eq 'access') {
	} elsif ($verb eq 'clear') {
	    $got = $ref = undef;
	} elsif ($verb eq 'count') {
	    if ($skip || !defined $got) {
		$got = undef;
	    } elsif (ref $got eq 'ARRAY') {
		$got = @$got;
	    } else {
		warn "Error - \$got is $got, not a list reference.\n";
		$got = undef;
##		die "Error - \$got does not refer to a list.\n";
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
	} elsif ($verb eq 'echo') {
	    foreach (split '\n', join ' ', @args) {
		print "# $_\n";
	    }
	} elsif ($verb eq 'end') {
	    last;
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
		    (defined $test && $test eq $target)
		       and do {$got = $item; last;};
		}
	    }
	} elsif ($verb eq 'load') {
	    if (@args) {
		my $fn = $args[0];
		open (my $fh, '<', $fn) or die "Failed to open $fn: $!\n";
		local $/ = undef;
		# Perl::Critic does not like string evals, but the
		# following needs to load arbitrary data dumped with
		# Data::Dumper. I could switch to YAML, but that is
		# not a core module.
		$canned = eval scalar <$fh>;	## no critic (ProhibitStringyEval)
		$@ and die $@;
		close $fh;
	    } else {
		$canned = undef;
	    }
	} elsif ($verb eq 'noskip') {
	    $skip = undef;
	} elsif ($verb eq 'require') {
	    $skip = @args > 1 ? ("Can not load any of " . join (', ', @args)) :
		@args ? "Can not load @args" : '';
	    foreach (@args) {
		eval "require $_";
		$@ or do {
		    $skip = '';
		    $loaded{$_} = 1;
		    last
		};
	    }
	} elsif ($verb eq 'test' || $verb eq 'todo') {
	    $test++;
	    $got = 'undef' unless defined $got;
	    foreach ($want, $got) {
		ref $_ and next;
		chomp $_;
		m/(.+?)\s+$/ and numberp ($1 . '') and $_ = $1;
	    }
	    print <<eod;
#
# Test $test - @args
#     Expect: @{[groom ($want)]}
#        Got: @{[groom ($got)]}
eod
	    if (ref $want eq 'Regexp') {
		skip ($skip, $got =~ m/$want/);
	    } elsif (numberp ($want) && numberp ($got)) {
		skip ($skip, $want == $got);
	    } else {
		skip ($skip, $want eq $got);
	    }
	} elsif ($verb eq 'want') {
	    $want = shift @args;
	} elsif ($verb eq 'want_load') {
	    $want = $canned;
	    foreach my $key (@args) {
		my $ref = ref $want;
		if ($ref eq 'ARRAY') {
		    $want = $want->[$key];
		} elsif ($ref eq 'HASH') {
		    $want = $want->{$key};
		} elsif ($ref) {
		    die "Loaded data contains unexpected $ref reference for key $key\n";
		} else {
		    die "Loaded data does not contain key @args\n";
		}
	    }
	} elsif ($verb eq 'want_re') {
	    $want = shift @args;
	    $want = qr{$want};
	} elsif ($obj->can ($verb)) {
	    unless ($skip) {
		if (defined $index) {
		    $got = eval {($obj->$verb (@args))[$index]};
		} else {
		    $got = eval {$obj->$verb (@args)};
		}
		if ($@) {
		    warn $@;
		    $got = $@;
		    if ($got =~ m/^(5\d+)/) {
			$skip = $got;
		    }
		}
		$ref = $got if ref $got;
	    }
	} else {
	    die "Error - $class does not support method $verb\n";
	}
    }
    return;
}


sub groom {
    my $thing = shift;
    defined $thing or return 'undef';
    ref $thing and return $thing;
    numberp ($thing) and return $thing;
    return "'$thing'"
}

sub numberp {
    return ($_[0] =~ m/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
}

1;
