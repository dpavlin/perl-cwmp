#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 34;
use Data::Dump qw/dump/;
use Cwd qw/abs_path/;
use lib 'lib';

BEGIN {
	use_ok('CWMP::Store');
	use_ok('CWMP::Store::DBMDeep');
	use_ok('CWMP::Store::YAML');
}

ok(my $abs_path = abs_path($0), "abs_path");
$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

my $path = "$abs_path/var/";

sub test_store {
	my $module = shift;

	diag "testing store plugin $module";

	ok( my $store = CWMP::Store->new({
		debug => $debug,
		module => $module,
		path => $path,
		clean => 1,
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

	ok( my $store_state = $store->get_state( ID => '42'), 'get_state ID' );

	is_deeply( $store_state, $state, 'state ID' );

	ok( $store_state = $store->get_state( uid =>  123456 ), 'get_state uid' );

	is_deeply( $store_state, $state, 'state ID same as uid' );

	ok( $store->update_state( ID => 42, { baz => 12345 } ), 'update_state existing' );

	$state->{baz} = 12345;

	is_deeply( $store->get_state( ID => 42 ), $state, 'get_state ID' );

	is_deeply( $store->get_state( uid => 123456 ), $state, 'get_state uid' );

	is_deeply( [ $store->all_uids ], [ 123456 ], 'all_uids' );

	ok( $store->update_state( ID => 11, { DeviceID => { SerialNumber => 99999 } } ), 'new device' );

	is_deeply( [ $store->all_uids ], [ 123456, 99999 ], 'all_uids' );

}

# now test all stores

test_store('DBMDeep');
test_store('YAML');

