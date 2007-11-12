#!/usr/bin/perl -w

# cpe-queue.pl
#
# 11/12/2007 10:03:53 PM CET  <>

use strict;

use lib './lib';
use CWMP::Queue;
use Getopt::Long;

my $debug = 0;
my $protocol_dump = 1;

GetOptions(
	'debug+' => \$debug,
	'protocol-dump!' => \$protocol_dump,
);

my $id = shift @ARGV || die "usage: $0 CPE_id [--protocol-dump]\n";

$id =~ s!^.*queue/+!!;
$id =~ s!/+$!!;	#!

die "ID isn't valid: $id\n" unless $id =~ m/^\w+$/;

my $q = CWMP::Queue->new({ id => $id, debug => $debug });

if ( $protocol_dump ) {

	warn "generating dump of xml protocol with CPE\n";

	$q->enqueue( 'GetRPCMethods' );
	$q->enqueue( 'GetParameterNames' );

#	$q->enqueue( 'GetParameterNames', 'InternetGatewayDevice.DeviceInfo.SerialNumber', 0 );
#	$q->enqueue( 'GetParameterNames', 'InternetGatewayDevice.DeviceInfo.', 1 );

	$q->enqueue( 'GetParameterValues',
				'InternetGatewayDevice.DeviceInfo.SerialNumber',
				'InternetGatewayDevice.DeviceInfo.VendorConfigFile.',
				'InternetGatewayDevice.DeviceInfo.X_000E50_Country',
	);
	$q->enqueue( 'SetParameterValues',
				'InternetGatewayDevice.DeviceInfo.ProvisioningCode' => 'test provision',
#			'InternetGatewayDevice.DeviceInfo.X_000E50_Country' => 1,
	);

#	$q->enqueue( 'Reboot' );

}

