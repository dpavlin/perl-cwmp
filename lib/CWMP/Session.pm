# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/18/07 10:19:50 CEST
package CWMP::Session;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
debug
store_path

sock
state
queue
store
/ );

use HTTP::Daemon;
use Data::Dump qw/dump/;
use Carp qw/confess cluck croak/;
use File::Slurp;

use CWMP::Request;
use CWMP::Response;
use CWMP::Store;

=head1 NAME

CWMP::Session - implement logic of CWMP protocol

=head1 METHODS

=head2 new

  my $server = CWMP::Session->new({
	sock => $io_socket_object,
	store_path => 'state.db',
	queue => [ qw/GetRPCMethods GetParameterNames/ ],
	debug => 1,
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	confess "need sock" unless $self->sock;

	$self->debug( 0 ) unless $self->debug;

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") for ", $self->sock->peerhost, "\n" if $self->debug;

	$self->store( CWMP::Store->new({
		debug => $self->debug,
		path => $self->store_path,
	}) );

	croak "can't open ", $self->store_path, ": $!" unless $self->store;

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

my $dump_nr = 0;

sub process_request {
	my $self = shift;

	my $sock = $self->sock || die "no sock?";

#	die "not IO::Socket::INET but ", ref( $sock ) unless ( ref($sock) eq 'Net::Server::Proto::TCP' );

	if ( ! $sock->connected ) {
		warn "SOCKET NOT CONNECTED\n";
		return 0;
	}

	bless $sock, 'HTTP::Daemon::ClientConn';

	# why do I have to do this?
	# solution from http://use.perl.org/~Matts/journal/12896
	${*$sock}{'httpd_daemon'} = HTTP::Daemon->new;

	my $r = $sock->get_request || confess "can't get_request";

	my $chunk = $r->content;

	my $size = length( $chunk );

	warn "<<<< ", $sock->peerhost, " [" . localtime() . "] ", $r->method, " ", $r->uri, " $size bytes\n";

	if ( $self->debug > 2 ) {
		my $file = sprintf("dump/%04d.request", $dump_nr++);
		write_file( $file, $r->as_string );
		warn "### request dump: $file\n";
	}

	my $state;

	if ( $size > 0 ) {

		die "no SOAPAction header in ",dump($chunk) unless defined ( $r->header('SOAPAction') );


		if ( $chunk ) {
			warn "## request chunk: ",length($chunk)," bytes\n$chunk\n" if $self->debug;

			$state = CWMP::Request->parse( $chunk );

			warn "## acquired state = ", dump( $state ), "\n";

			$self->state( $state );
			$self->store->update_state( ID => $state->{ID}, $state );

		} else {
			warn "## empty request\n";
		}

	} else {
		$state = $self->state;
		warn "last request state = ", dump( $state ), "\n" if $self->debug > 1;
	}


	$sock->send(join("\r\n",
		'HTTP/1.1 200 OK',
		'Content-Type: text/xml; charset="utf-8"',
		'Server: AcmeCWMP/42',
		'SOAPServer: AcmeCWMP/42'
	)."\r\n");

	$sock->send( "Set-Cookie: ID=" . $state->{ID} . "; path=/\r\n" ) if ( $state->{ID} );
	
	my $xml = '';

	if ( my $dispatch = $state->{_dispatch} ) {
		$xml = $self->dispatch( $dispatch );
	} elsif ( $dispatch = shift @{ $self->queue } ) {
		$xml = $self->dispatch( $dispatch );
	} elsif ( $size == 0 ) {
		warn ">>> closing connection\n";
		return 0;
	} else {
		warn ">>> empty response\n";
		$state->{NoMoreRequests} = 1;
		$xml = $self->dispatch( 'xml', sub {} );
	}

	$sock->send( "Content-Length: " . length( $xml ) . "\r\n\r\n" );
	$sock->send( $xml ) or die "can't send response";

	warn ">>>> " . $sock->peerhost . " [" . localtime() . "] sent ", length( $xml )," bytes\n";

	warn "### request over\n" if $self->debug;

	return 1;	# next request
};

=head2 dispatch

  $xml = $self->dispatch('Inform', $response_arguments );

If debugging level of 3 or more, it will create dumps of responses named C<< dump/nr.response >>

=cut

sub dispatch {
	my $self = shift;

	my $dispatch = shift || die "no dispatch?";

	my $response = CWMP::Response->new({ debug => $self->debug });

	if ( $response->can( $dispatch ) ) {
		warn ">>> dispatching to $dispatch\n";
		my $xml = $response->$dispatch( $self->state, @_ );
		warn "## response payload: ",length($xml)," bytes\n$xml\n" if $self->debug;
		if ( $self->debug > 2 ) {
			my $file = sprintf("dump/%04d.response", $dump_nr++);
			write_file( $file, $xml );
			warn "### response dump: $file\n";
		}
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
