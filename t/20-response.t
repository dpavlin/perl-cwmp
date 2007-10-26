#!/usr/bin/perl
use strict;
use warnings;

my $debug = shift @ARGV;

use Test::More tests => 11;
use Data::Dump qw/dump/;
use blib;

BEGIN {
	use_ok('CWMP::Response');
}

#ok( my $xml = join("",<DATA>), 'xml' );
#diag $xml if $debug;

ok( my $response = CWMP::Response->new({ debug => $debug }), 'new' );
isa_ok( $response, 'CWMP::Response' );

sub is_like {
	my ( $command, $template_xml ) = @_;

	ok( my $xml = $response->$command({ ID => 42 }), $command );
	diag $xml if $debug;
	chomp( $xml );
	chomp( $template_xml );
	like( $xml, qr{^\Q$template_xml\E$}, $command . ' xml' );
}

is_like( 'InformResponse', <<__SOAP__
<soap:Envelope xmlns:cwmp="urn:dslforum-org:cwmp-1-0" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <soap:Header>
    <cwmp:ID mustUnderstand="1">42</cwmp:ID>
    <cwmp:NoMoreRequests>0</cwmp:NoMoreRequests>
  </soap:Header>
  <soap:Body>
    <cwmp:InformResponse>
      <cwmp:MaxEnvelopes>1</cwmp:MaxEnvelopes>
    </cwmp:InformResponse>
  </soap:Body>
</soap:Envelope>
__SOAP__
);

is_like( 'GetRPCMethods', <<__SOAP__
<soap:Envelope xmlns:cwmp="urn:dslforum-org:cwmp-1-0" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <soap:Header>
    <cwmp:ID mustUnderstand="1">42</cwmp:ID>
    <cwmp:NoMoreRequests>0</cwmp:NoMoreRequests>
  </soap:Header>
  <soap:Body>
    <GetRPCMethods />
  </soap:Body>
</soap:Envelope>
__SOAP__
);

is_like( 'Reboot', <<__SOAP__
<soap:Envelope xmlns:cwmp="urn:dslforum-org:cwmp-1-0" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <soap:Header>
    <cwmp:ID mustUnderstand="1">42</cwmp:ID>
    <cwmp:NoMoreRequests>0</cwmp:NoMoreRequests>
  </soap:Header>
  <soap:Body>
    <Reboot />
  </soap:Body>
</soap:Envelope>
__SOAP__
);

is_like( 'GetParameterNames', <<__SOAP__
<soap:Envelope xmlns:cwmp="urn:dslforum-org:cwmp-1-0" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <soap:Header>
    <cwmp:ID mustUnderstand="1">42</cwmp:ID>
    <cwmp:NoMoreRequests>0</cwmp:NoMoreRequests>
  </soap:Header>
  <soap:Body>
    <cwmp:GetParameterNames>
      <cwmp:ParameterPath></cwmp:ParameterPath>
      <cwmp:NextLevel>0</cwmp:NextLevel>
    </cwmp:GetParameterNames>
  </soap:Body>
</soap:Envelope>
__SOAP__
);
