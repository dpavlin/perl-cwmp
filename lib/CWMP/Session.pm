# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/18/07 10:19:50 CEST
package CWMP::Session;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
debug
create_dump
session

sock
state
store
/ );

use Data::Dump qw/dump/;
use Carp qw/carp confess cluck croak/;

use CWMP::Request;
use CWMP::Methods;
use CWMP::Store;

#use Devel::LeakTrace::Fast;

=head1 NAME

CWMP::Session - implement logic of CWMP protocol

=head1 METHODS

=head2 new

  my $server = CWMP::Session->new({
	sock => $io_socket_object,
	store => { ... },
	debug => 1,
	create_dump => 1,
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	confess "need store" unless $self->store;

	$self->debug( 0 ) unless $self->debug;

	my $store_obj = CWMP::Store->new({
		debug => $self->debug,
		%{ $self->store },
	});

	croak "can't open ", dump( $self->store ), ": $!" unless $store_obj;

	# FIXME looks ugly. Should we have separate accessor for this?
	$self->store( $store_obj );

	$self->create_dump( 1 ) if $self->debug > 2;

	return $self;
}

=head2 process_request

One request from client/response from server cycle. Call multiple times to
facilitate brain-dead concept of adding state to stateless protocol like
HTTP.

If used with debugging level of 3 or more, it will also create dumps of
requests named C<< dump/nr.request >> where C<nr> is number from 0 to total number
of requests in single session.

=cut


sub process_request {
	my ( $self, $ip, $xml ) = @_;

	my $size = length( $xml );

	my $state;

	if ( $size > 0 ) {

		warn "## request payload: ",length($xml)," bytes\n$xml\n" if $self->debug;

		$state = CWMP::Request->parse( $xml );

		warn "## acquired state = ", dump( $state ), "\n" if $self->debug;

		if ( ! defined( $state->{DeviceID} ) ) {
			if ( $self->state ) {
				warn "## state without DeviceID, using old one...\n";
				$state->{DeviceID} = $self->state->{DeviceID};
			} else {
				warn "WARNING: state without DeviceID, and I don't have old one!\n";
				warn "## state = ",dump( $state );
			}
		}

		$self->state( $state );
		$self->store->update_state( $state );

	} else {

		warn "## empty request, using last request state\n";

		$state = $self->state;
		delete( $state->{_dispatch} );
		#warn "last request state = ", dump( $state ), "\n" if $self->debug > 1;
	}

	my $out = join("\r\n",
		'HTTP/1.1 200 OK',
		'Content-Type: text/xml; charset="utf-8"',
		'Server: Perl-CWMP/42',
		'SOAPServer: Perl-CWMP/42'
	) . "\r\n";

	$out .= "Set-Cookie: ID=" . $state->{ID} . "; path=/\r\n" if $state->{ID};

	my $uid = $self->store->state_to_uid( $state );

	my $to_uid = join(" ", grep { defined($_) } "to $uid",
			# board
			$state->{Parameter}->{'InternetGatewayDevice.DeviceInfo.HardwareVersion'},
			# version
			$state->{Parameter}->{'InternetGatewayDevice.DeviceInfo.SoftwareVersion'},
			# summary
#			$state->{Parameter}->{'InternetGatewayDevice.DeviceSummary'},
	) . "\n";

	my $queue = CWMP::Queue->new({
		id => $uid,
		debug => $self->debug,
	});
	my $job;
	$xml = '';

	if ( my $dispatch = $state->{_dispatch} ) {
		$xml = $self->dispatch( $dispatch );
	} elsif ( $job = $queue->dequeue ) {
		$xml = $self->dispatch( $job->dispatch );
	} else {
		warn ">>> empty response $to_uid";
		$state->{NoMoreRequests} = 1;
		$xml = '';
	}

	$out .= "Content-Length: " . length( $xml ) . "\r\n\r\n";
	$out .= $xml if length($xml);

	$job->finish if $job;
	warn "### request over for $uid\n" if $self->debug;

	return $out;	# next request
};

=head2 dispatch

  $xml = $self->dispatch('Inform', $response_arguments );

If debugging level of 3 or more, it will create dumps of responses named C<< dump/nr.response >>

=cut

sub dispatch {
	my $self = shift;

	my $dispatch = shift || die "no dispatch?";
	my $args = shift;

	my $response = CWMP::Methods->new({ debug => $self->debug });

	if ( $response->can( $dispatch ) ) {
		warn ">>> dispatching to $dispatch with args ",dump( $args ),"\n";
		my $xml = $response->$dispatch( $self->state, $args );
		warn "## response payload: ",length($xml)," bytes\n$xml\n" if $self->debug;
		return $xml;
	} else {
		confess "can't dispatch to $dispatch";
	}
};


=head2 error

  return $self->error( 501, 'System error' );

=cut

sub error {
  my ($self, $number, $msg) = @_;
  $msg ||= 'ERROR';
  $self->sock->send( "HTTP/1.1 $number $msg\r\n" );
  warn "Error - $number - $msg\n";
  return 0;	# close connection
}

1;
