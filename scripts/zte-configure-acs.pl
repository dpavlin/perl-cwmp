#!/usr/bin/perl

use warnings;
use strict;

my $acs = 'http://192.168.2.100:3333';
my $cpe = 'http://192.168.2.1';

use WWW::Mechanize;
my $mech = WWW::Mechanize->new();

$mech->get( $cpe );

$mech->submit_form(
	form_number => 1,
	fields => {
		tUsername => 'admin',
		tPassword => 'admin',
	}
);

$mech->follow_link( text_regex => qr/Advanced/ );

$mech->follow_link( text_regex => qr/TR069/ );

#$mech->dump_forms;
#$mech->dump_links;
#$mech->dump_all;

my $uid = 'time-' . time();

$mech->submit_form(
	form_number => 2,
	fields => {
		_ACS_URL => $acs,
		_ACS_NAME => $uid,
		_ENABLE => '_ENABLE',
	}
);


warn $uid;

