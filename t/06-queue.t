#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 256;
use Data::Dump qw/dump/;
use lib 'lib';

#use Devel::LeakTrace::Fast;

BEGIN {
	use_ok('CWMP::Queue');
}

use Cwd qw/abs_path/;
ok(my $abs_path = abs_path($0), "abs_path");
$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

ok( my $obj = CWMP::Queue->new({
	id => 'test',
	dir => "$abs_path/queue",
	clean => 1,
	debug => $debug,
}), 'new' );
isa_ok( $obj, 'CWMP::Queue' );

for my $i ( 1 .. 42 ) {
	ok( $obj->enqueue(
		"command-$i",
		{
			i => $i,
			foo => 'bar',
		}
	), "enqueue $i" );
};

my $i = 1;

while ( my $job = $obj->dequeue ) {
	ok( $job, "dequeue $i" );
	ok( my ( $dispatch, $args ) = $job->dispatch, "job->dispatch $i" );
	cmp_ok( $dispatch, 'eq', "command-$i", "dispatch $i" );
	diag "args = ",dump( $args ) if $debug;
	cmp_ok( $args->{i}, '==', $i, "args i == $i" );
	ok( $job->finish, "finish $i" );
	$i++;
}
