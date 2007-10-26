#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 6;
use Data::Dump qw/dump/;
use lib 'lib';

BEGIN {
	use_ok('CWMP::Tree');
}

#use Cwd qw/abs_path/;
#ok(my $abs_path = abs_path($0), "abs_path");
#$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

ok( my $obj = CWMP::Tree->new({
	debug => $debug,
}), 'new' );
isa_ok( $obj, 'CWMP::Tree' );

my @perl = qw/
{'InternetGatewayDevice'}->{'DeviceInfo'}->{'HardwareVersion'}
{'InternetGatewayDevice'}->{'DeviceInfo'}->{'VendorConfigFile'}->[1]->{'Date'}
{'InternetGatewayDevice'}->{'Services'}->{'VoiceService'}->[1]->{'PhyInterface'}->[2]->{'PhyPort'}
/;

foreach my $name ( qw/
InternetGatewayDevice.DeviceInfo.HardwareVersion
InternetGatewayDevice.DeviceInfo.VendorConfigFile.1.Date
InternetGatewayDevice.Services.VoiceService.1.PhyInterface.2.PhyPort
/ ) {
	my $expect = shift @perl;
	cmp_ok( $obj->name2perl( $name ), 'eq', $expect, "name2perl( $name )" );
}
