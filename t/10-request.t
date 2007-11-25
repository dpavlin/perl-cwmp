#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 73;
use Data::Dump qw/dump/;
use Cwd qw/abs_path/;
use File::Slurp;
use blib;

#use Devel::LeakTrace::Fast;

BEGIN {
	use_ok('CWMP::Request');
}

my @models = ( qw/SpeedTouch-706 SpeedTouch-780/ );

ok( $#models + 1, 'got models' );

ok(my $abs_path = abs_path($0), "abs_path");
$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

my $path2method;
my $triggers_count;

sub file_is_deeply {
	my ( $path ) = @_;

	ok( my $xml = read_file( $path ), "read_file( $path )" );

	diag $xml if $debug;

	ok( my $trigger = $path2method->{$path}, "path2method($path)" );

	CWMP::Request->add_trigger( name => $trigger, callback => sub {
		my ( $self, $state ) = @_;
		$triggers_count->{$trigger}++;
		ok( $state, "called trigger $trigger" );
	});

	ok( my $state = CWMP::Request->parse( $xml ), 'parse' );

	my $dump_path = $path;
	$dump_path =~ s/\.xml/\.pl/;

	write_file( $dump_path, dump( $state ) ) unless ( -e $dump_path );

	diag "$path ? $dump_path" if $debug;

	ok( my $hash = read_file( $dump_path ), "read_file( $dump_path )" );
	ok ( $hash = eval "$hash", 'eval' );

	is_deeply( $state, $hash, 'same' );
}

foreach my $model ( @models ) {

	my $dir = "$abs_path/$model/";
	opendir(DIR, $dir) || die "can't opendir $dir: $!";
	my @xmls = map {
		my $path = "$dir/$_";
		my $method = $_;
		$method =~ s/\.xml$//;
		$path2method->{$path} = $method;
		$path;
	} grep { /\.xml$/ && -f "$dir/$_" } readdir(DIR);
	closedir DIR;

	diag "$model has ", $#xmls + 1, " xml tests";

	ok( $#xmls, "xmls" );

	foreach my $xml_path ( @xmls ) {
		ok ( $xml_path, 'xml path' );
		file_is_deeply( $xml_path );
	}
}

diag "triggers_count = ",dump( $triggers_count ) if $debug;

