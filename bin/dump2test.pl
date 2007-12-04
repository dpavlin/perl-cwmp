#!/usr/bin/perl -w

# dump2test.pl
#
# convert dump from one CPE to test files

use strict;
use File::Find;
use File::Path qw/mkpath/;
use Data::Dump qw/dump/;
use File::Slurp;
use blib;
use CWMP::Request;
use YAML::Syck;

my $path = shift @ARGV || die "usage: $0 dump/client_ip/\n";

my $requests;

find({
	no_chdir => 1,
	wanted => sub {
		my $path = $File::Find::name;

		return unless -l $path;

		if ( $path =~ m!\d+-(.+)!) {
			my $name = $1;
			$requests->{$name} = $path;
		} else {
			warn "can't find request name in $path\n";
		}

	}
}, $path);

warn "## requests = ",dump( $requests );

my $test_path = 't/dump/';

sub xml2state {
	my $xml = shift;
	$xml =~ s/^.*?</</s;
	return CWMP::Request->parse( $xml );
}

if ( my $i = $requests->{Inform} ) {

	my $xml = read_file($i);

#	warn "## xml: $xml\n";

	my $state = xml2state( $xml );

#	warn "## state = ",dump( $state );

	$test_path .=
		$state->{Parameter}->{'InternetGatewayDevice.DeviceInfo.HardwareVersion'}
		. '/' .
		$state->{Parameter}->{'InternetGatewayDevice.DeviceInfo.SoftwareVersion'}
		;

} else {
	die "need Inform found ", dump( $requests );
}

mkpath $test_path unless -e $test_path;

warn "dumping new tests into $test_path\n";

foreach my $name ( keys %$requests ) {
	my $from = $requests->{$name};
	my $to   = "$test_path/$name";
	if ( -e $to ) {
		warn "SKIP $to\n";
		next;
	}
	warn "## $from -> $to\n";
	my $xml = read_file( $from );
	write_file( $to, $xml );
	DumpFile( "$to.yml", xml2state( $xml ) );
	warn "created $to\n";
}
