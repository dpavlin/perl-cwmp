#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 16;
use Data::Dump qw/dump/;
use Cwd qw/abs_path/;
use File::Slurp;
use blib;

BEGIN {
	use_ok('CWMP::Methods');
}

ok(my $abs_path = abs_path($0), "abs_path");
$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

ok( my $method = CWMP::Methods->new({ debug => $debug }), 'new' );
isa_ok( $method, 'CWMP::Methods' );

sub check_method {
	my $command = shift || die "no command?";

	my $state = {
		ID => 42,
	};

	diag "check_method $command",dump( 'state', @_ ) if $debug;
	ok( my $xml = $method->$command( $state, shift ), "generate method $command" . dump(@_) );

	my $file = "$abs_path/methods/$command.xml";

	if ( ! -e $file ) {
		diag "creating $file";
		write_file( $file, $xml );
	}

	my $template_xml = read_file( $file ) || die "can't read template xml $file: $!";

	is( $xml, $template_xml, "compare $file" );
}

check_method( 'InformResponse' );
check_method( 'GetRPCMethods' );
check_method( 'Reboot' );
check_method( 'SetParameterValues', {
	'InternetGatewayDevice.DeviceInfo.ProvisioningCode' => 'test provision',
	'InternetGatewayDevice.DeviceInfo.X_000E50_Country' => 42,
});
check_method( 'GetParameterNames', [ 'InternetGatewayDevice.DeviceInfo.SerialNumber' ] );
check_method( 'GetParameterValues', [
	'InternetGatewayDevice.DeviceInfo.SerialNumber',
	'InternetGatewayDevice.DeviceInfo.VendorConfigFile.',
]);
