# Dobrica Pavlinusic, <dpavlin@rot13.org> 10/26/07 21:37:12 CEST
package CWMP::Store::YAML;

use strict;
use warnings;

use CWMP::Store::HASH;
use base qw/CWMP::Store::HASH/;

use YAML::Syck;

=head1 NAME

CWMP::Store::YAML - use YAML as storage

=cut

my $full_path;

sub full_path {
	my ( $self, $path ) = @_;
	$full_path = "$path/yaml";
	warn "## full_path: $full_path" if $debug;
	return $full_path;
}

sub file {
	my ( $self, $uid ) = @_;
	my $file = "$full_path/$uid" . $self->extension;
	warn "## file -> $file" if $debug;
	return $file;
}

sub save_hash {
	my ( $self, $file, $hash ) = @_;
	DumpFile( $file . '.tmp', $hash );
	rename $file . '.tmp', $file || die "can't rename $file.tmp -> $file: $!";
}

sub load_hash {
	my ( $self, $file ) = @_;
	LoadFile( $file );
}

sub extension { '.yml' };

1;
