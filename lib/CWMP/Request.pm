package CWMP::Request;

use warnings;
use strict;

use XML::Rules;
use CWMP::Tree;
use Data::Dump qw/dump/;
use Carp qw/confess cluck/;

=head1 NAME

CWMP::Request - parse SOAP request

=head1 METHODS

=head2 _tag

Get value of tag. Tag name is case insensitive (don't ask why),
we ignore namespaces and can take optional C<sub_key>
(usually C<_content>).

  _tag( $tag_hash, $name, $sub_key )

=cut

sub _tag {
	my ( $tag_hash, $name, $sub_key ) = @_;
	confess "need hash as first argument" unless ( ref $tag_hash eq 'HASH' );
	$name = (grep { m/^(?:\w+:)*$name$/i } keys %$tag_hash )[0];
#	$name =~ s/^\w+://;
	if ( defined $tag_hash->{$name} ) {
		if ( ! defined $sub_key ) {
			return $tag_hash->{$name};
		} elsif ( defined $tag_hash->{$name}->{$sub_key} ) {
			return $tag_hash->{$name}->{$sub_key};
		} else {
			return if ( $name =~ m/^value$/i );
			warn "can't find '$name/$sub_key' in ", dump( $tag_hash );
			return;
		}
	} else {
		warn "can't find '$name' in ", dump( $tag_hash );
		return;
	}
}

our $state;	# FIXME check this!

my $tree = CWMP::Tree->new({ debug => 0 });

my $parser = XML::Rules->new(
#	start_rules => [
#		'^division_name,fax' => 'skip',
#	],
	namespaces => {
		'http://schemas.xmlsoap.org/soap/envelope/' => 'soapenv',
		'http://schemas.xmlsoap.org/soap/encoding/' => 'soap',
		'http://www.w3.org/2001/XMLSchema' => 'xsd',
		'http://www.w3.org/2001/XMLSchema-instance' => 'xsi',
		'urn:dslforum-org:cwmp-1-0' => '',
	},
	rules => [
		#_default => 'content trim',
		x_default => sub {
			my ($tag_name, $tag_hash, $context, $parent_data) = @_;
			warn dump( $tag_name, $tag_hash, $context );
		},
		'ID' => sub {
			my ($tag_name, $tag_hash, $context, $parent_data) = @_;
			$state->{ID} = $tag_hash->{_content};
		},
		#
		# Inform
		#
		'Inform' => sub {
			$state->{_dispatch} = 'InformResponse';		# what reponse to call
		},
		'DeviceId' => sub {
			my ($tag_name, $tag_hash, $context, $parent_data) = @_;
			foreach my $name ( keys %$tag_hash ) {
				next if $name eq '_content';
				my $key = $name;
				$key =~ s/^\w+://;	# stip namespace
				$state->{DeviceID}->{ $key } = _tag( $tag_hash, $name, '_content' );
			}
		},
		'EventStruct' => sub {
			my ($tag_name, $tag_hash, $context, $parent_data) = @_;
			push @{ $state->{EventStruct} }, $tag_hash->{EventCode}->{_content};
		},
		qr/(MaxEnvelopes|CurrentTime|RetryCount)/ => sub {
			my ($tag_name, $tag_hash, $context, $parent_data) = @_;
			$state->{$tag_name} = $tag_hash->{_content};
		},
		'ParameterValueStruct' => sub {
			my ($tag_name, $tag_hash, $context, $parent_data) = @_;
			# Name/Value tags must be case insnesitive
			my $value = (grep( /value/i, keys %$tag_hash ))[0];
			$state->{Parameter}->{ _tag($tag_hash, 'Name', '_content') } = _tag($tag_hash, 'Value', '_content' );
		},
		#
		# GetRPCMethodsResponse
		#
		qr/^(?:^\w+:)*string$/ => 'content array',
		'MethodList' => sub {
			my ($tag_name, $tag_hash, $context, $parent_data) = @_;
			$state->{MethodList} = _tag( $tag_hash, 'string' );
		},
		#
		# GetParameterNamesResponse
		#
		'ParameterInfoStruct' => sub {
			my ($tag_name, $tag_hash, $context, $parent_data) = @_;
			my $name = _tag($tag_hash, 'Name', '_content');
			my $writable = _tag($tag_hash, 'Writable', '_content' );

			confess "need state" unless ( $state );	# don't remove!

			# XXX dragons ahead: convert name to tree rewriting it into perl
			my $s = '$state->{ParameterInfo}->' . $tree->name2perl( $name ) . "->{writable} = $writable;";
			eval "$s";
			confess "can't eval $s : $@" if ($@);

			#warn "## state = dump( $state ), "\n";
		},
		#
		# Fault
		#
		'Fault' => sub {
			my ($tag_name, $tag_hash, $context, $parent_data) = @_;
			$state->{Fault} = {
				FaultCode => _tag( $tag_hash, 'FaultCode', '_content' ),
				FaultString => _tag( $tag_hash, 'FaultString', '_content' ),
			};
			warn "FAULT: ", $state->{Fault}->{FaultCode}, " ", $state->{Fault}->{FaultString}, "\n";
		}
	]
);

=head2 parse

  my $state = CWMP::Request->parse( "<soap>request</soap>" );

=cut

sub parse {
	my $self = shift;

	my $xml = shift || confess "no xml?";

	$state = {};
	$parser->parsestring( $xml );
	return $state;
}

1;
