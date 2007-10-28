#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 4;
use blib;

BEGIN {
	use_ok('CWMP::Server');
	use_ok('CWMP::Request');
	use_ok('CWMP::Methods');
	use_ok('CWMP::Store');
}


