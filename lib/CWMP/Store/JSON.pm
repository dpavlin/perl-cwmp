package CWMP::Store::JSON;

use strict;
use warnings;

use CWMP::Store::HASH;
use base qw/CWMP::Store::HASH/;

use JSON::XS;
use File::Slurp;

=head1 NAME

CWMP::Store::YAML - use YAML as storage

=cut

my $full_path;

sub full_path {
	my ( $self, $path ) = @_;
	$full_path = "$path/json";
	warn "## full_path: $full_path";
	return $full_path;
}

sub file {
	my ( $self, $uid ) = @_;
	my $file = "$full_path/$uid" . $self->extension;
	warn "## file -> $file";
	return $file;
}

sub save_hash {
	my ( $self, $file, $hash ) = @_;
	write_file( $file, to_json $hash );
}

sub load_hash {
	my ( $self, $file ) = @_;
	from_json read_file( $file );
}

sub extension { '.js' };

1;
