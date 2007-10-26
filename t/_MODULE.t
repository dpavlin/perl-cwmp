#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 3;
use Data::Dump qw/dump/;
use lib 'lib';

BEGIN {
	use_ok('CWMP::_MODULE');
}

#use Cwd qw/abs_path/;
#ok(my $abs_path = abs_path($0), "abs_path");
#$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

ok( my $obj = CWMP::_MODULE->new({
	debug => $debug,
}), 'new' );
isa_ok( $obj, 'CWMP::_MODULE' );

