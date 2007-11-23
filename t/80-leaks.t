#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 4;
use Data::Dump qw/dump/;
use lib 'lib';

BEGIN {
	use_ok('CWMP::MemLeak');
}

#use Cwd qw/abs_path/;
#ok(my $abs_path = abs_path($0), "abs_path");
#$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

ok( my $leak = CWMP::MemLeak->new({
	debug => $debug,
}), 'new' );
isa_ok( $leak, 'CWMP::MemLeak' );

ok( ! $leak->report, 'report' );

