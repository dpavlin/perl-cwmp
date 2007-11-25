#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 32;
use Data::Dump qw/dump/;
use Cwd qw/abs_path/;
use lib 'lib';

#use Devel::LeakTrace::Fast;

BEGIN {
	use_ok('CWMP::Store');
	use_ok('CWMP::Store::YAML');
	use_ok('CWMP::Store::JSON');
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

	cmp_ok( $store->state_to_uid( $state ), 'eq', 123456, 'state_to_uid' );

	ok( $store->update_state( $state ), 'update_state new' );

	ok( my $store_state = $store->get_state( 123456 ), 'get_state' );

	isa_ok( $state, 'HASH' );
	isa_ok( $store_state, 'HASH' );

	if ( $debug ) {

		diag "store_state = ",dump( $store_state );
	
	}

	is_deeply( $state, $store_state, 'state ID same as uid' );

	ok( $store->update_state( {
		DeviceID => {
			SerialNumber => 123456,
		},
		baz => 12345 
	} ), 'update_state existing' );

	$state->{baz} = 12345;

	is_deeply( $store->get_state( 123456 ), $state, 'get_state' );

	is_deeply( [ $store->all_uids ], [ 123456 ], 'all_uids' );

	ok( $store->update_state( { DeviceID => { SerialNumber => 99999 } } ), 'new device' );

	is_deeply( [ $store->all_uids ], [ 123456, 99999 ], 'all_uids' );

}

# now test all stores

test_store('YAML');
test_store('JSON');

