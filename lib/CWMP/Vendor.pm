package CWMP::Vendor;

use strict;
use warnings;

use YAML qw();

#use Carp qw/confess/;
use Data::Dump qw/dump/;

=head1 NAME

CWMP::Vendor - implement vendor specific logic into ACS server

=cut

my $debug = 1;

sub all_parameters {
	my ( $self, $store, $uid, $queue ) = @_;

	my $stored = $store->get_state( $uid );

	return ( 'GetParameterNames', [ 'InternetGatewayDevice.', 1 ] )
		if ! defined $stored->{ParameterInfo};

	my @params =
		grep { m/\.$/ }
		keys %{ $stored->{ParameterInfo} }
	;

	if ( @params ) {
		warn "# GetParameterNames ", dump( @params );
		my $first = shift @params;
		delete $stored->{ParameterInfo}->{$first};

		foreach ( @params ) {
			$queue->enqueue( 'GetParameterNames', [ $_, 1 ] );
			delete $stored->{ParameterInfo}->{ $_ };
		}
		$store->set_state( $uid, $stored );

		return ( 'GetParameterNames', [ $first, 1 ] );

	} else {

		my @params = sort
			grep { ! exists $stored->{Parameter}->{$_} }
			grep { ! m/\.$/ && ! m/NumberOfEntries/ }
			keys %{ $stored->{ParameterInfo} }
		;
		if ( @params ) {
			warn "# GetParameterValues ", dump( @params );
			my $first = shift @params;
			while ( @params ) {
				my @chunk = splice @params, 0, 16; # FIXME 16 seems to be max
				$queue->enqueue( 'GetParameterValues', [ @chunk ] );
			}

			return ( 'GetParameterValues', [ $first ] );
		}
	}

	return;
}

our $tried;

sub vendor_config {
	my ( $self, $store, $uid, $queue ) = @_;

	my $stored = $store->get_state( $uid );

	my @refresh;

	my $vendor = YAML::LoadFile 'vendor.yaml';
	$vendor = $vendor->{Parameter} || die  "no Parameter in vendor.yaml";
	$stored = $stored->{Parameter} || warn "no Parameter in stored ", dump($stored);

	warn "# vendor.yaml ",dump $vendor;

	foreach my $n ( keys %$vendor ) {
		if ( ! exists $stored->{$n} ) {
			warn "# $uid missing $n\n";
			push @refresh, $n;
		} elsif ( $vendor->{$n} ne $stored->{$n} && ! $tried->{$uid}->{$n}->{set} && $tried->{$uid}->{$n}->{set} ne $vendor->{$n} ) {
			$queue->enqueue( 'SetParameterValues', { $n => $vendor->{$n} } );
			push @refresh, $n;
			$tried->{$uid}->{$n}->{set} = $vendor->{$n};
			warn "# set $uid $n $stored->{$n} -> $vendor->{$n}\n";
		} else {
			warn "# ok $uid $n\n";
		}
	}

	return ( 'GetParameterValues', [ @refresh ] ) if @refresh;

	warn "# tried ",dump $tried;

	return;
}

1;
