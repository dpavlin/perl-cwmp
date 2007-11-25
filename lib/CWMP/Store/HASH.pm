package CWMP::Store::HASH;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw/
	$debug
/;

use Data::Dump qw/dump/;
use Hash::Merge qw/merge/;
use Carp qw/confess/;

=head1 NAME

CWMP::Store::HASH - base class for hash based storage engines

=head1 METHODS

=head2 open

  $store->open({
	path => 'var/',
	debug => 1,
	clean => 1,
  });

=cut

my $path;

my $debug = 0;

my $cleaned = 0;

sub open {
	my $self = shift;

	my $args = shift;

	$debug = $args->{debug};
	$path = $args->{path} || confess "no path?";

	warn "open ",dump( $args ) if $debug;

	$path = $self->full_path( $path );

	if ( ! -e $path ) {
		mkdir $path || die "can't create $path: $!";
		warn "created $path directory\n" if $debug;
	} elsif ( $args->{clean} && ! $cleaned ) {
		warn "removed old $path\n" if $debug;
		foreach my $uid ( $self->all_uids ) {
			my $file = $self->file( $uid );
			unlink $file || die "can't remove $file: $!";
		}
		$cleaned++;
	}


}

=head2 update_uid_state

  my $new_state = $store->update_uid_state( $uid, $state );

=cut

sub update_uid_state {
	my ( $self, $uid, $state ) = @_;

	my $file = $self->file( $uid );

	my $old_state = $self->get_state( $uid );

	my $combined = merge( $state, $old_state );

#	warn "## ",dump( $old_state, $state, $combined );

	$self->save_hash( $file, $combined ) || die "can't write $file: $!";

	return $combined;
}

=head2 get_state

  $store->get_state( $uid );

=cut

sub get_state {
	my ( $self, $uid ) = @_;

	my $file = $self->file( $uid );

	if ( -e $file ) {
		return $self->load_hash( $file );
	}

	return;
}

=head2 all_uids

  my @uids = $store->all_uids;

=cut

sub all_uids {
	my $self = shift;

	my $ext = $self->extension;
	#warn "## extension: $ext";

	opendir(my $d, $path) || die "can't opendir $path: $!";
	my @uids = grep { $_ =~ m/\Q$ext\E$/ && -f "$path/$_" } readdir($d);
	closedir $d;

	return map { my $l = $_; $l =~ s/\Q$ext\E$//; $l } @uids;
}

1;
