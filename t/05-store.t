#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 18;
use Data::Dump qw/dump/;
use Cwd qw/abs_path/;
use lib 'lib';

BEGIN {
	use_ok('CWMP::Store');
	use_ok('CWMP::Store::DBMDeep');
}

ok(my $abs_path = abs_path($0), "abs_path");
$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

my $path = "$abs_path/var/";

unlink $path if -e $path;

ok( my $store = CWMP::Store->new({
	debug => $debug,
#	module => 'DBMDeep',
	module => 'YAML',
	path => $path,
}), 'new' );
isa_ok( $store, 'CWMP::Store' );

cmp_ok( $store->path, 'eq', $path, 'path' );

my $state = {
	foo => 'bar',
	DeviceID => {
		SerialNumber => 123456,
	},
};

cmp_ok( $store->ID_to_uid( 42, $state ), 'eq', 123456, 'ID_to_uid' );

ok( $store->update_state( ID => 42, $state ), 'update_state new' );

ok( my $store_state = $store->state( ID => '42'), 'db->get' );

is_deeply( $store_state, $state, 'state ID' );

ok( $store_state = $store->state( uid =>  123456 ), 'db->get' );

is_deeply( $store_state, $state, 'state uid' );

ok( $store->update_state( ID => 42, { baz => 12345 } ), 'update_state existing' );

$state->{baz} = 12345;

is_deeply( $store->state( ID => 42 ), $state, 'store->state ID' );

is_deeply( $store->state( uid => 123456 ), $state, 'store->state uid' );

is_deeply( [ $store->known_CPE ], [ 123456 ], 'known_CPE' );

ok( $store->update_state( ID => 11, { DeviceID => { SerialNumber => 99999 } } ), 'new device' );

is_deeply( [ $store->known_CPE ], [ 123456, 99999 ], 'known_CPE' );

