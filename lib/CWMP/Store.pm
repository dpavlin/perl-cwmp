# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/22/07 14:35:38 CEST
package CWMP::Store;

use strict;
use warnings;


use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
debug
path

db
/ );

use Carp qw/confess/;
use Data::Dump qw/dump/;
use DBM::Deep;

=head1 NAME

CWMP::Store - parsist CPE state on disk

=head1 METHODS

=head2 new

  my $store = CWMP::Store->new({
  	path => '/path/to/state.db',
	debug => 1,
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") object\n" if $self->debug;

	confess "need path to state.db" unless ( $self->path );

	$self->db(
		DBM::Deep->new(
			file => $self->path,
			locking => 1,
			autoflush => 1,
		)
	);

	foreach my $init ( qw/ state session / ) {
		$self->db->put( $init => {} ) unless $self->db->get( $init );
	}

	return $self;
}

=head2 update_state

  $store->update_state( ID => $ID, $state );
  $store->update_state( uid => $uid, $state );

=cut

sub update_state {
	my $self = shift;

	my ( $k, $v, $state ) = @_;

	confess "need ID or uid" unless $k =~ m/^(ID|uid)$/;
	confess "need $k value" unless $v;
	confess "need state" unless $state;

	warn "## update_state( $k => $v, ", dump( $state ), " )\n" if $self->debug;

	my $uid;

	if ( $k eq 'ID' ) {
		if ( $uid = $self->ID_to_uid( $v, $state ) ) {
			# nop
		} else {
			warn "## no uid for $v, first seen?\n" if $self->debug;
			return;
		}
	} else {
		$uid = $v;
	}

	if ( my $o = $self->db->get('state')->get( $uid ) ) {
		warn "## update state of $uid [$v]\n" if $self->debug;
		return $o->import( $state );
	} else {
		warn "## create new state for $uid [$v]\n" if $self->debug;
		return $self->db->get('state')->put( $uid => $state );
	}
}

=head2 state

  my $state = $store->state( ID => $ID );
  my $state = $store->state( uid => $uid );

Returns normal unblessed hash (actually, in-memory copy of state in database).

=cut

sub state {
	my $self = shift;
	my ( $k, $v ) = @_;
	confess "need ID or uid" unless $k =~ m/^(ID|uid)$/;
	confess "need $k value" unless $v;

	warn "## state( $k => $v )\n" if $self->debug;

	my $uid;

	if ( $k eq 'ID' ) {
		if ( $uid = $self->ID_to_uid( $v ) ) {
			# nop
		} else {
			warn "## no uid for $v so no state!\n" if $self->debug;
			return;
		}
	} else {
		$uid = $v;
	}

	if ( my $state = $self->db->get('state')->get( $uid ) ) {
		return $state->export;
	} else {
		return;
	}

}

=head2 known_CPE

  my @cpe = $store->known_CPE;

=cut

sub known_CPE {
	my $self = shift;
	my @cpes = keys %{ $self->db->{state} };
	warn "all CPE: ", dump( @cpes ), "\n" if $self->debug;
	return @cpes;
}

=head2 ID_to_uid

  my $CPE_uid = $store->ID_to_uid( $ID, $state );

It uses C<< DeviceID.SerialNumber >> from C<Inform> message as unique ID
for each CPE.

=cut

sub ID_to_uid {
	my $self = shift;
	my ( $ID, $state ) = @_;

	confess "need ID" unless $ID;

	warn "ID_to_uid",dump( $ID, $state ),$/ if $self->debug;

	$self->db->{session}->{ $ID }->{last_seen} = time();

	my $uid;

	if ( $uid = $self->db->{session}->{ $ID }->{ ID_to_uid } ) {
		return $uid;
	} elsif ( $uid = $state->{DeviceID}->{SerialNumber} ) {
		warn "## created new session for $uid session $ID\n" if $self->debug;
		$self->db->{session}->{ $ID } = {
			last_seen => time(),
			ID_to_uid => $uid,
		};
		return $uid;
	} else {
		warn "## can't find uid for ID $ID, first seen?\n";
		return;
	}

	# TODO: expire sessions longer than 30m

	return;
}

1;
