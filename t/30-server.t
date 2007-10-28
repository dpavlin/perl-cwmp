#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 19;
use Data::Dump qw/dump/;
use Cwd qw/abs_path/;
use blib;

BEGIN {
	use_ok('Net::HTTP');
	use_ok('CWMP::Server');
	use_ok('CWMP::Store');
}

my $port = 4242;

eval {
	$SIG{ALRM} = sub { die; };
	alarm 30;
};

ok(my $abs_path = abs_path($0), "abs_path");
$abs_path =~ s!/[^/]*$!/!;	#!fix-vim

my $store_path = "$abs_path/var/";
#my $store_module = 'DBMDeep';
my $store_module = 'YAML';

ok( my $server = CWMP::Server->new({
	debug => $debug,
	port => $port,
	store => {
		module => $store_module,
		path => $store_path,
		clean => 1,
	},
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

ok( my $s = Net::HTTP->new(Host => "localhost:$port"), 'client' );
$s->keep_alive( 1 );

ok( $s->write_request(
	POST => '/',
	'Transfer-Encoding' => 'chunked',
	'SOAPAction' => '',
	'Content-Type' => 'text/xml',
), 'write_request' );

foreach my $chunk (qq{

<soapenv:Envelope soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:soap="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cwmp="urn:dslforum-org:cwmp-1-0">
 <soapenv:Header>
<cwmp:ID soapenv:mustUnderstand="1">1_THOM_TR69_ID</cwmp:ID>
 </soapenv:Header>
 <soapenv:Body>
<cwmp:Inform>
<DeviceId>
 <Manufacturer>THOMSON</Manufacturer>
 <OUI>00147F</OUI>
 <ProductClass>SpeedTouch 780</ProductClass>
 <SerialNumber>CP0644JTHJ4</SerialNumber>
</DeviceId>
<Event soap:arrayType="cwmp:EventStruct[03]">
<EventStruct>
 <EventCode>0 BOOTSTRAP</EventCode>
 <CommandKey></CommandKey>
</EventStruct>
<EventStruct>
 <Event},qq{Code>1 BOOT</EventCode>
 <CommandKey></CommandKey>
</EventStruct>
<EventStruct>
 <EventCode>4 VALUE CHANGE</EventCode>
 <CommandKey></CommandKey>
</EventStruct>
</Event>
<MaxEnvelopes>2</MaxEnvelopes>
<CurrentTime>1970-01-01T00:04:33Z</CurrentTime>
<RetryCount>01</RetryCount>},qq{
<ParameterList soap:arrayType="cwmp:ParameterValueStruct[12]">
<ParameterValueStruct>
 <Name>InternetGatewayDevice.DeviceSummary</Name>
 <Value xsi:type="xsd:string">InternetGatewayDevice:1.1[] (Baseline:1, EthernetLAN:1, ADSLWAN:1, Bridging:1, Time:1, WiFiLAN:1)</Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>}, qq{
InternetGatewayDevice.DeviceInfo.SpecVersion</Name>
 <Value xsi:type="xsd:string">1.1</Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>InternetGatewayDevice.DeviceInfo.HardwareVersion</Name>
 <Value xsi:type="xsd:string">BANT-R</Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>InternetGatewayDevice.DeviceInfo.SoftwareVersion</Name>
 <Value xsi:type="xsd:string">6.2.15.5</Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>InternetGatewayDevice.DeviceInfo.ProvisioningCode</Name>
 <Value xsi:type="xsd:string"></Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>InternetGatewayDevice.DeviceInfo.VendorConfigFile.1.Name</Name>
 <Value xsi:type="xsd:string">Routed PPPoE on 0/35 and 8/35</Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>InternetGatewayDevice.DeviceInfo.VendorConfigFile.1.Version</Name>
 <Value xsi:type="xsd:string"></Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>InternetGatewayDevice.DeviceInfo.VendorConfigFile.1.Date</Name>
 <Value xsi:type="xsd:dateTime">0000-00-00T00:00:00</Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>InternetGatewayDevice.DeviceInfo.VendorConfigFile.1.Description</Name>
 <Value xsi:type="xsd:string">Factory Defaults</Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>InternetGatewayDevice.ManagementServer.ConnectionRequestURL</Name>
 <Value}, qq{ xsi:type="xsd:string">http://192.168.1.254:51005/</Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>InternetGatewayDevice.ManagementServer.ParameterKey</Name>
 <Value xsi:type="xsd:string"></Value>
</ParameterValueStruct>
<ParameterValueStruct>
 <Name>.ExternalIPAddress</Name>
 <Value xsi:type="xsd:string">192.168.1.254</Value>
</ParameterValueStruct>
</ParameterList>
</cwmp:Inform>
 </soapenv:Body>
</soapenv:Envelope>
} ) {
	ok( $s->write_chunk( $chunk ), "chunk " . length($chunk) . " bytes" );
}
ok( $s->write_chunk_eof, 'write_chunk_eof' );

sleep 1;

ok( my $store = CWMP::Store->new({ module => $store_module, path => $store_path, debug => $debug }), 'another store' );

my $state = {
  CurrentTime    => "1970-01-01T00:04:33Z",
  DeviceID       => {
                      Manufacturer => "THOMSON",
                      OUI => "00147F",
                      ProductClass => "SpeedTouch 780",
                      SerialNumber => "CP0644JTHJ4",
                    },
  EventStruct    => ["0 BOOTSTRAP", "1 BOOT", "4 VALUE CHANGE"],
  ID             => "1_THOM_TR69_ID",
  MaxEnvelopes   => 2,
#  NoMoreRequests => undef,
  Parameter      => {
                      "\nInternetGatewayDevice.DeviceInfo.SpecVersion"                  => "1.1",
                      ".ExternalIPAddress"                                              => "192.168.1.254",
                      "InternetGatewayDevice.DeviceInfo.HardwareVersion"                => "BANT-R",
                      "InternetGatewayDevice.DeviceInfo.ProvisioningCode"               => undef,
                      "InternetGatewayDevice.DeviceInfo.SoftwareVersion"                => "6.2.15.5",
                      "InternetGatewayDevice.DeviceInfo.VendorConfigFile.1.Date"        => "0000-00-00T00:00:00",
                      "InternetGatewayDevice.DeviceInfo.VendorConfigFile.1.Description" => "Factory Defaults",
                      "InternetGatewayDevice.DeviceInfo.VendorConfigFile.1.Name"        => "Routed PPPoE on 0/35 and 8/35",
                      "InternetGatewayDevice.DeviceInfo.VendorConfigFile.1.Version"     => undef,
                      "InternetGatewayDevice.DeviceSummary"                             => "InternetGatewayDevice:1.1[] (Baseline:1, EthernetLAN:1, ADSLWAN:1, Bridging:1, Time:1, WiFiLAN:1)",
                      "InternetGatewayDevice.ManagementServer.ConnectionRequestURL"     => "http://192.168.1.254:51005/",
                      "InternetGatewayDevice.ManagementServer.ParameterKey"             => undef,
                    },
  RetryCount     => "01",
  _dispatch      => "InformResponse",
};

is_deeply( $store->current_store->get_state( 'CP0644JTHJ4' ), $state, 'store->current_store->get_state' );

ok( kill(9,$pid), 'kill ' . $pid );

ok( waitpid($pid,0), 'waitpid' );
