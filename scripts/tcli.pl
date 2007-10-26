#!/usr/bin/perl -w

use strict;
use Expect;
use Net::Telnet;

my $modem = '192.168.1.254';
my @commands = (
':system config led=flash',
);

while(<>) {
	chomp;
	next if (/^#/ || /^\s*$/);
	push @commands, $_;
}

push @commands, ':system config led=off';

my $debug = 0;

my $telnet = new Net::Telnet( $modem ) or die "Cannot telnet to $modem: $!\n";
my $exp = Expect->exp_init($telnet);
$exp->debug( $debug );

$exp->log_stdout( 1 );

my ( $username, $password ) = ('Administrator','');
my $timeout = 3;

$exp->expect($timeout, 'Username : ');
$exp->send("$username\r\n");
$exp->expect($timeout, 'Password :');
$exp->send("$password\r\n");
$exp->expect($timeout, '=>');

foreach my $cmd ( @commands ) {
	$exp->send( "$cmd\r\n" );
	$exp->expect($timeout, '=>');
}

$exp->send( "exit\r\n" );
$exp->soft_close();

