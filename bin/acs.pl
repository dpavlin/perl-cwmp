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

GetOptions(
	'debug+' => \$debug,
	'port=i' => \$port,
	'store-path=s' => \$store_path,
	'store-plugin=s' => \$store_plugin,
);

my $server = CWMP::Server->new({
	port => $port,
	store => {
		module => $store_plugin,
		path => $store_path,
		debug => $debug,
	},
	debug => $debug,
	default_queue => [
		'GetRPCMethods',
		[ 'GetParameterNames', 'InternetGatewayDevice.DeviceInfo.SerialNumber', 0 ],
		[ 'GetParameterValues', 'InternetGatewayDevice.DeviceInfo.SerialNumber', 1 ],
#		'Reboot',
	],
});
$server->run();

