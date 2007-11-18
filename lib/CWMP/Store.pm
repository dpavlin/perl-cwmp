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

  $store->update_state( $state );

=cut

sub update_state {
	my $self = shift;

	my ( $state ) = @_;

	confess "need state" unless $state;

	my $uid = $self->state_to_uid( $state );

	warn "#### update_state( ", dump( $state ), " ) for $uid\n" if $self->debug > 2;
	$self->current_store->update_uid_state( $uid, $state );
}

=head2 get_state

  my $state = $store->get_state( $uid );

Returns normal unblessed hash (actually, in-memory copy of state in database).

=cut

sub get_state {
	my $self = shift;
	my ( $uid ) = @_;
	confess "need uid" unless $uid;

	warn "#### get_state( $uid )\n" if $self->debug > 4;

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

=head2 state_to_uid

  my $CPE_uid = $store->ID_to_uid( $state );

It uses C<< DeviceID.SerialNumber >> from C<Inform> message as unique ID
for each CPE.

=cut

sub state_to_uid {
	my $self = shift;
	my ( $state ) = @_;

	warn "#### state_to_uid",dump( $state ),$/ if $self->debug > 4;

	my $uid = $state->{DeviceID}->{SerialNumber} ||
		confess "no DeviceID.SerialNumber in ",dump( $state );

	return $uid;
}

1;
