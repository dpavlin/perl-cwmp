#!/usr/bin/perl -w

# dump.pl
#
# 06/22/07 16:23:05 CEST Dobrica Pavlinusic <dpavlin@rot13.org>

use strict;
use DBM::Deep;
use Data::Dump qw/dump/;

my $path = shift @ARGV || 'state.db'; #die "usage: $0 state.db";

my $db = DBM::Deep->new(
	file => $path,
);

warn "file: $path\n";
print dump( $db );
