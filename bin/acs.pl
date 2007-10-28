#!/usr/bin/perl -w

# acs.pl
#
# 06/18/07 09:19:54 CEST Dobrica Pavlinusic <dpavlin@rot13.org>

use strict;

use lib './lib';
use CWMP::Server;
use Getopt::Long;

my $port = 3333;
my $debug = 0;
my $store_path = './';
my $store_plugin = 'YAML';
my $protocol_dump = 0;

GetOptions(
	'debug+' => \$debug,
	'port=i' => \$port,
	'store-path=s' => \$store_path,
	'store-plugin=s' => \$store_plugin,
	'protocol-dump!' => \$protocol_dump,
);

my $queue;

if ( $protocol_dump ) {

	warn "generating dump of xml protocol with CPE\n";

	$queue = [
			'GetRPCMethods',
			'GetParameterNames',
#			[ 'GetParameterNames', 'InternetGatewayDevice.DeviceInfo.SerialNumber', 0 ],
#			[ 'GetParameterNames', 'InternetGatewayDevice.DeviceInfo.', 1 ],
			[ 'GetParameterValues',
				'InternetGatewayDevice.DeviceInfo.SerialNumber',
				'InternetGatewayDevice.DeviceInfo.VendorConfigFile.',
				'InternetGatewayDevice.DeviceInfo.X_000E50_Country',
			],
			[ 'SetParameterValues',
				'InternetGatewayDevice.DeviceInfo.ProvisioningCode' => 'test provision',
#			'InternetGatewayDevice.DeviceInfo.X_000E50_Country' => 1,
			],
#			'Reboot',
	];
};


my $server = CWMP::Server->new({
	port => $port,
	store => {
		module => $store_plugin,
		path => $store_path,
		debug => $debug,
	},
	debug => $debug,
	default_queue => [ $queue ],
});
$server->run();

