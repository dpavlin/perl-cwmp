#!/usr/bin/perl -w

use strict;
use Expect;
use Net::Telnet;
use Data::Dump qw/dump/;

die "usage: $0 [modem] commands\n" unless @ARGV;

my $modem = '10.0.0.138';
$modem = shift @ARGV if $#ARGV >= 1;

my @commands = (
':system config led=flash',
);

sub ask {
	my ( $prompt, $default ) = @_;
	warn "## ask $prompt [default]";
	print "$prompt [$default] ";
	my $in = <STDIN>;
	chomp($in);
	$in = $default unless length($in) > 1;
	return $in;
}

while(<>) {
	chomp;
	next if (/^#/ || /^\s*$/);
	my $l = $_;
	warn "--$_--";
	$l =~ s/ask\(([^|\)]+)(?:\|([^\)]+))?\)/ask($1,$2)/eg;
	warn "++ $l\n";
	push @commands, $l;
}

push @commands, ':system config led=off';

my $debug = 0;

warn "## connecting to $modem\n";

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

