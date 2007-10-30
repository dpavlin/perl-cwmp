# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/22/07 14:35:38 CEST
package CWMP::Store;

use strict;
use warnings;


use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
module
path
debug
/ );

use Carp qw/confess/;
use Data::Dump qw/dump/;
use Module::Pluggable search_path => 'CWMP::Store', sub_name => 'possible_stores', require => 1;

=head1 NAME

CWMP::Store - parsist CPE state on disk

=head1 METHODS

=head2 new

  my $store = CWMP::Store->new({
  	module => 'DBMDeep',
  	path => '/path/to/state.db',
	clean => 1,
	debug => 1,
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	confess "requed parametar module is missing" unless $self->module;

	# XXX it's important to call possible_stores once, because current_store won't work
	my @plugins = $self->possible_stores();

	warn "Found store plugins: ", join(", ", @plugins ), "\n" if $self->debug;

	$self->current_store->open( @_ );

	# so that we don't have to check if it's defined
	$self->debug( 0 ) unless $self->debug;

	return $self;
}

=head2 current_store

Returns currnet store plugin object

=cut

sub current_store {
	my $self = shift;

	my $module = $self->module;
	my $s = $self->only( ref($self).'::'.$module );

	confess "unknown store module $module not one of ", dump( $self->possible_stores ) unless $s;

#	warn "#### current store = $s\n" if $self->debug > 4;

	return $s;
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

	warn "#### update_state( $k => $v, ", dump( $state ), " )\n" if $self->debug > 4;

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

	$self->current_store->update_uid_state( $uid, $state );
}

=head2 get_state

  my $state = $store->get_state( ID => $ID );
  my $state = $store->get_state( uid => $uid );

Returns normal unblessed hash (actually, in-memory copy of state in database).

=cut

sub get_state {
	my $self = shift;
	my ( $k, $v ) = @_;
	confess "need ID or uid" unless $k =~ m/^(ID|uid)$/;
	confess "need $k value" unless $v;

	warn "#### get_state( $k => $v )\n" if $self->debug > 4;

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

	return $self->current_store->get_state( $uid );

}

=head2 all_uids

  my @cpe = $store->all_uids;

=cut

sub all_uids {
	my $self = shift;
	my @cpes = $self->current_store->all_uids;
	warn "## all_uids = ", dump( @cpes ), "\n" if $self->debug;
	return @cpes;
}

=head2 ID_to_uid

  my $CPE_uid = $store->ID_to_uid( $ID, $state );

It uses C<< DeviceID.SerialNumber >> from C<Inform> message as unique ID
for each CPE.

=cut

my $session;

sub ID_to_uid {
	my $self = shift;
	my ( $ID, $state ) = @_;

	confess "need ID" unless $ID;

	warn "#### ID_to_uid",dump( $ID, $state ),$/ if $self->debug > 4;

	warn "##### current session = ",dump( $session ), $/ if $self->debug > 5;

	$session->{ $ID }->{last_seen} = time();

	my $uid;

	if ( $uid = $session->{ $ID }->{ ID_to_uid } ) {
		return $uid;
	} elsif ( $uid = $state->{DeviceID}->{SerialNumber} ) {
		warn "## created new session for $uid session $ID\n" if $self->debug;
		$session->{ $ID } = {
			last_seen => time(),
			ID_to_uid => $uid,
		};
		return $uid;
	} else {
		warn "## can't find uid for ID $ID, first seen?\n";
	}

	# TODO: expire sessions longer than 30m

	return;
}

1;
