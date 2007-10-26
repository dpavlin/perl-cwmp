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

GetOptions(
	'debug+' => \$debug,
	'port=i' => \$port,
);

my $server = CWMP::Server->new({
	port => $port,
	store => {
#		module => 'DBMDeep',
		module => 'YAML',
		store_path => 'state.db',
	},
	debug => $debug,
	default_queue => [ qw/
		GetRPCMethods
		GetParameterNames
	/ ],
#		Reboot
});
$server->run();

