#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 129;
use Data::Dump qw/dump/;
use lib 'lib';

BEGIN {
	use_ok('CWMP::Queue');
}

#use Cwd qw/abs_path/;
#ok(my $abs_path = abs_path($0), "abs_path");
#$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

ok( my $obj = CWMP::Queue->new({
	id => 'test',
	debug => $debug,
}), 'new' );
isa_ok( $obj, 'CWMP::Queue' );

for my $i ( 1 .. 42 ) {
	ok( $obj->enqueue(
		i => $i,
		foo => 'bar',
	), "enqueue $i" );
};

my $i = 1;

while ( my $data = $obj->dequeue ) {
	ok( $data, "dequeue $i" );
	cmp_ok( $data->{i}, '==', $i, "i == $i" );
	$i++;
}
