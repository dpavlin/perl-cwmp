# Dobrica Pavlinusic, <dpavlin@rot13.org> 10/26/07 21:37:12 CEST
package CWMP::Store::DBMDeep;

use strict;
use warnings;

use DBM::Deep;
use Data::Dump qw/dump/;
use Carp qw/confess/;

=head1 NAME

CWMP::Store::DBMDeep - use DBM::Deep as storage

=head1 METHODS

=head2 open

  $store->open({
	path => 'var/',
	debug => 1,
	clean => 1,
  });

=cut

my $db;

my $debug = 0;

sub open {
	my $self = shift;

	my $args = shift;

	$debug = $args->{debug};
	my $path = $args->{path} || confess "no path?";

	warn "open ",dump( $args ) if $debug;

	$path = "$path/state.db" if ( -d $args->{path} );

	if ( $args->{clean} && -e $path ) {
		warn "removed old $path\n";
		unlink $path || die "can't remove $path: $!";
	}

	$db = DBM::Deep->new(
		file => $path,
		locking => 1,
		autoflush => 1,
	) || confess "can't open $path: $!";

}

=head2 update_uid_state

  $store->update_uid_state( $uid, $state );

=cut

sub update_uid_state {
	my ( $self, $uid, $state ) = @_;

	if ( my $o = $db->get( $uid ) ) {
		warn "## update state of $uid\n" if $debug;
		return $o->import( $state );
	} else {
		warn "## create new state for $uid\n" if $debug;
		return $db->put( $uid => $state );
	}
}

=head2 get_state

  $store->get_state( $uid );

=cut

sub get_state {
	my ( $self, $uid ) = @_;

	if ( my $state = $db->get( $uid ) ) {
		return $state->export;
	} else {
		return;
	}
}

=head2 all_uids

  my @uids = $store->all_uids;

=cut

sub all_uids {
	my $self = shift;
	return keys %$db;
}

1;
