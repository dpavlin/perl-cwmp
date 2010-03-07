package CWMP::Parser;

use warnings;
use strict;

use XML::Bare;
use Data::Dump qw/dump/;
use Carp qw/confess cluck/;

=head1 NAME

CWMP::Parser - parse SOAP request XML

=head1 DESCRIPTION

Design is based on my expirience with L<XML::Rules>, but show-stopper
was it's inability to parse invalid XML returned by some devices, so
in this version we depend on L<XML::Bare>

=cut

our $state;	# FIXME check this!
my $debug = 0;

sub _get_array {
	my ( $tree ) = @_;

	my @out;

	foreach my $n ( keys %$tree ) {
		next unless ref($tree->{$n}) eq 'ARRAY';
		@out = map { $_->{value} } @{ $tree->{$n} };
		last;
	}

	die "no array in ",dump($tree) unless @out;

	return @out;
}

sub _hash_value {
	my ( $tree ) = @_;
	my $hash;
	foreach my $n ( keys %$tree ) {
		next unless ref($tree->{$n}) eq 'HASH';
		$hash->{$n} = $tree->{$n}->{value};
	}
	die "no hash value in ",dump($hash) unless $hash;
	return $hash;
}

sub _walk {
	my ( $tree ) = @_;

	foreach my $node ( keys %$tree ) {
		next if $node =~ m/^_/;

		my $dump = 0;

		if ( $node =~ m/GetRPCMethodsResponse/ ) {

			$state->{MethodList} = [ _get_array( $tree->{$node}->{MethodList} ) ];
			$dump = 1;

		} elsif ( $node =~ m/(ID|MaxEnvelopes|CurrentTime|RetryCount)/ ) {

			$state->{$1} = $tree->{$node}->{value};
			chomp $state->{$1};
			$dump = 1;

		} elsif ( $node =~ m/(DeviceId)/ ) {

			$state->{$1} = _hash_value $tree->{$node};
			$dump = 1;

		} elsif ( $node =~ m/(Fault)/ && ! defined $tree->{$node}->{detail} ) {

			$state->{$1} = _hash_value $tree->{$node};
			$dump = 1;

		} elsif ( $node =~ m/(EventStruct|ParameterValueStruct|ParameterInfoStruct)/ ) {

			my $name = $1;
			$name =~ s/Struct//;
			$name =~ s/Value//;

			my @struct;

			if ( ref $tree->{$node} eq 'HASH' ) {
				@struct = ( $tree->{$node} );
			} elsif ( ref $tree->{$node} eq 'ARRAY' ) {
				@struct = @{ $tree->{$node} };
			} else {
				die "don't know how to handle $node in ",dump($tree);
			}

			foreach my $e ( @struct ) {
				my $hash = _hash_value $e;

				if ( my $n = delete $hash->{Name} ) {
					my @keys = keys %$hash;
					if ( $#keys > 0 ) {
						$state->{$name}->{$n} = $hash;
					} else {
						$state->{$name}->{$n} = $hash->{ $keys[0] };
#							warn "using $keys[0] as value for $name.$n\n";
					}
				} else {
					push @{ $state->{$name} }, $hash;
				}
			}

			$dump = 1;

		} elsif ( ref($tree->{$node}) eq 'HASH' ) {

			$state->{_dispatch} = 'InformResponse' if $node =~ m/Inform/;

			warn "## recurse $node\n" if $debug;
			_walk( $tree->{$node} );

		}
	
		if ( $dump ) {
#			warn "XXX tree ",dump( $tree->{$node} );
			warn "## state ",dump( $state ) if $debug;
		}
	}
}

sub parse {
	my $self = shift;

	my $xml = shift || confess "no xml?";

	$state = {};

	my $bare = XML::Bare->new( text => $xml );
	my $hash = $bare->parse();

	_walk $hash;
#warn "# parsed to ",dump($hash);

	return $state;
}

1;
