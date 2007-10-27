# Dobrica Pavlinusic, <dpavlin@rot13.org> 10/26/07 21:37:12 CEST
package CWMP::Store::YAML;

use strict;
use warnings;

use Data::Dump qw/dump/;
use YAML qw/LoadFile DumpFile/;
use Hash::Merge qw/merge/;
use Carp qw/confess/;

=head1 NAME

CWMP::Store::YAML - use YAML as storage

=head1 METHODS

=head2 open

=cut

my $path;

my $debug = 1;

sub open {
	my $self = shift;

	my $args = shift;

	$debug = $args->{debug};
	$path = $args->{path} || confess "no path?";

	warn "open ",dump( $args ) if $debug;

	$path = "$path/yaml";

	if ( ! -e $path ) {
		mkdir $path || die "can't create $path: $!";
		warn "created $path directory\n";
	}

}

=head2 update_uid_state

  $store->update_uid_state( $uid, $state );

=cut

sub update_uid_state {
	my ( $self, $uid, $state ) = @_;

	my $file = "$path/$uid.yml";

	my $old_state = $self->get_state( $uid );

	my $combined = merge( $state, $old_state );

#	warn "## ",dump( $old_state, $state, $combined );

	DumpFile( $file, $combined ) || die "can't write $file: $!";

}

=head2 get_state

  $store->get_state( $uid );

=cut

sub get_state {
	my ( $self, $uid ) = @_;

	my $file = "$path/$uid.yml";

	if ( -e $file ) {
		return LoadFile( $file );
	}

	return;
}

=head2 all_uids

  my @uids = $store->all_uids;

=cut

sub all_uids {
	my $self = shift;

	opendir(my $d, $path) || die "can't opendir $path: $!";
	my @uids = grep { /\.yml$/ && -f "$path/$_" } readdir($d);
	closedir $d;

	return map { my $l = $_; $l =~ s/\.yml$//; $l } @uids;
}

1;
