# Dobrica Pavlinusic, <dpavlin@rot13.org> 10/26/07 21:37:12 CEST
package CWMP::Store::YAML;

use strict;
use warnings;

use Data::Dump qw/dump/;
use YAML qw/LoadFile DumpFile/;

=head1 NAME

CWMP::Store::YAML - use YAML as storage

=head1 METHODS

=head2 open

=cut

my $dir = 'yaml';

my $debug = 1;

sub open {
	my $self = shift;

	warn "open ",dump( @_ );

	if ( ! -e $dir ) {
		mkdir $dir || die "can't create $dir: $!";
		warn "created $dir directory\n";
	}

}

=head2 update_uid_state

  $store->update_uid_state( $uid, $state );

=cut

sub update_uid_state {
	my ( $self, $uid, $state ) = @_;

	my $file = "$dir/$uid.yml";

	DumpFile( $file, $state ) || die "can't write $file: $!";

}

=head2 get_state

  $store->get_state( $uid );

=cut

sub get_state {
	my ( $self, $uid ) = @_;

	my $file = "$dir/$uid.yml";

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

	opendir(my $d, $dir) || die "can't opendir $dir: $!";
	my @uids = grep { /\.yml$/ && -f "$dir/$_" } readdir($d);
	closedir $d;

	return map { my $l = $_; $l =~ s/\.yml$//; $l } @uids;
}

1;
