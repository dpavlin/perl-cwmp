#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 4;
use blib;

#use Devel::LeakTrace::Fast;

BEGIN {
	use_ok('CWMP::Server');
	use_ok('CWMP::Parser');
	use_ok('CWMP::Methods');
	use_ok('CWMP::Store');
}


