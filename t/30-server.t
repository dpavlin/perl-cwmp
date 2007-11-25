#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 135;
use Data::Dump qw/dump/;
use Cwd qw/abs_path/;
use File::Find;
use File::Slurp;
use File::Path qw/rmtree mkpath/;
use YAML::Syck;
use blib;

BEGIN {
	use_ok('Net::HTTP');
	use_ok('CWMP::Server');
	use_ok('CWMP::Store');
	use_ok('CWMP::Request');
}

my $port = 4242;

eval {
	$SIG{ALRM} = sub { die; };
	alarm 30;
};

ok(my $abs_path = abs_path($0), "abs_path");
$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

my $store_path = "$abs_path/var/";
my $store_module = 'YAML';

rmtree $store_path if -e $store_path;
ok( mkpath $store_path, "mkpath $store_path" );

ok( my $server = CWMP::Server->new({
	debug => $debug,
	port => $port,
	session => {
		store => {
			module => $store_module,
			path => $store_path,
#			clean => 1,
		},
		create_dump => 0,
	}
}), 'new' );
isa_ok( $server, 'CWMP::Server' );

my $pid;

if ( $pid = fork ) {
	ok( $pid, 'fork ');
	diag "forked $pid";
} elsif (defined($pid)) {
	# child
	$server->run;
	exit;
} else {
	die "can't fork";
}

sleep 1;	# so server can start

my $s;

sub cpe_connect {
	return $s if $s;
	diag "CPE connect";
	ok( $s = Net::HTTP->new(Host => "localhost:$port"), 'CPE client' );
	$s->keep_alive( 1 );
}

sub cpe_disconnect {
	return unless $s;
	diag "CPE disconnect";
	$s->keep_alive( 0 );
	ok( $s->write_request(
		POST => '/',
		'SOAPAction' => '',
		'Content-Type' => 'text/xml',
	), 'write_request' );
	my ($code, $mess, %h) = $s->read_response_headers;
	undef $s;
	diag "$code $mess";
	return $code == 200 ? 1 : 0;
}

sub test_request {
	my $path = shift;

	ok( -e $path, $path );

	cpe_disconnect if $path =~ m/Inform/;
	cpe_connect;

	ok( $s->write_request(
		POST => '/',
		'Transfer-Encoding' => 'chunked',
		'SOAPAction' => '',
		'Content-Type' => 'text/xml',
	), 'write_request' );

	my $xml = read_file( $path );
	$xml =~ s/^.+?</</s;

	my $chunk_size = 5000;

	foreach my $part ( 0 .. int( length($xml) / $chunk_size ) ) {
		my $chunk = substr( $xml, $part * $chunk_size, $chunk_size );
		ok( $s->write_chunk( $chunk ), "chunk $part " . length($chunk) . " bytes" );
	}
	ok( $s->write_chunk_eof, 'write_chunk_eof' );

	my($code, $mess, %h) = $s->read_response_headers;
	diag "$code $mess";
	while (1) {
		my $buf;
		my $n = $s->read_entity_body($buf, 1024);
		die "read failed: $!" unless defined $n;
		last unless $n;
		diag $buf;
	}

	ok( my $store = CWMP::Store->new({ module => $store_module, path => $store_path, debug => $debug }), 'another store' );

	my $state = LoadFile( "$path.yml" );

	$path =~ s!/[^/]+$!!; #!vim
	ok( my $uid = $store->state_to_uid( LoadFile( "$path/Inform.yml" ) ), 'state_to_uid' );

	ok( my $store_state = $store->current_store->get_state( $uid ), 'get_state' );

	my $s;

	# ignore
	foreach my $k ( keys %$state ) {
		if ( defined( $store_state->{$k} ) ) {
			$s->{$k} = $store_state->{$k};
		} else {
			die "store_state doesn't have $k: ",dump( $store_state );
		}
	}

	is_deeply( $s, $state, 'store->current_store->get_state' );

}

find({
	no_chdir => 1,
	wanted => sub {
		my $path = $File::Find::name;
		return unless -f $path;
		return if $path =~ m/\.yml$/;
		eval {
			test_request( $path );
		};
		ok( ! $@, "request $path" );
	}
},'t/dump/');

ok( cpe_disconnect, 'cpe_disconnect' );

diag "shutdown server";

ok( kill(9,$pid), 'kill ' . $pid );

ok( waitpid($pid,0), 'waitpid' );

