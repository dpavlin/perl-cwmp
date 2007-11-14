#!/usr/bin/perl -w

# acs.pl
#
# 06/18/07 09:19:54 CEST Dobrica Pavlinusic <dpavlin@rot13.org>

use strict;

use lib './lib';
use CWMP::Server;
use CWMP::Session;
use CWMP::Vendor;
use Getopt::Long;
use Data::Dump qw/dump/;

my $port = 3333;
my $debug = 0;
my $store_path = './';
my $store_plugin = 'YAML';
my $create_dump = 1;

GetOptions(
	'debug+' => \$debug,
	'port=i' => \$port,
	'store-path=s' => \$store_path,
	'store-plugin=s' => \$store_plugin,
	'create_dump!' => \$create_dump,
);

my $server = CWMP::Server->new({
	port => $port,
	session => {
		store => {
			module => $store_plugin,
			path => $store_path,
			debug => $debug,
		},
		create_dump => $create_dump,
	},
	debug => $debug,
});

CWMP::Vendor->add_triggers;

$server->run();

