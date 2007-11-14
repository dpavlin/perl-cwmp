# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/18/07 10:19:50 CEST
package CWMP::Session;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
debug
store

sock
state
store
/ );

use HTTP::Daemon;
use Data::Dump qw/dump/;
use Carp qw/confess cluck croak/;
use File::Slurp;

use CWMP::Request;
use CWMP::Methods;
use CWMP::Store;

=head1 NAME

CWMP::Session - implement logic of CWMP protocol

=head1 METHODS

=head2 new

  my $server = CWMP::Session->new({
	sock => $io_socket_object,
	store => 'state.db',
	debug => 1,
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	confess "need sock" unless $self->sock;

	$self->debug( 0 ) unless $self->debug;

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") for ", $self->sock->peerhost, "\n" if $self->debug;

	my $store_obj = CWMP::Store->new({
		debug => $self->debug,
		%{ $self->store },
	});

	croak "can't open ", dump( $self->store ), ": $!" unless $store_obj;

	# FIXME looks ugly. Should we have separate accessor for this?
	$self->store( $store_obj );

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

	my $xml = $r->content;

	my $size = length( $xml );

	warn "<<<< ", $sock->peerhost, " [" . localtime() . "] ", $r->method, " ", $r->uri, " $size bytes\n";

	$dump_nr++;
	my $file = sprintf("dump/%04d-%s.request", $dump_nr, $sock->peerhost);

	if ( $self->debug > 2 ) {
		write_file( $file, $r->as_string );
		warn "### request dumped to file: $file\n";
	}

	my $state;

	if ( $size > 0 ) {

		die "no SOAPAction header in ",dump($xml) unless defined ( $r->header('SOAPAction') );

		warn "## request payload: ",length($xml)," bytes\n$xml\n" if $self->debug;

		$state = CWMP::Request->parse( $xml );

		if ( defined( $state->{_dispatch} ) && $self->debug > 2 ) {
			my $type = sprintf("dump/%04d-%s-%s", $dump_nr, $sock->peerhost, $state->{_dispatch});
			symlink $file, $type || warn "can't symlink $file -> $type: $!";
		}

		warn "## acquired state = ", dump( $state ), "\n";

		$self->state( $state );
		$self->store->update_state( ID => $state->{ID}, $state );

	} else {

		warn "## empty request, using last request state\n";

		$state = $self->state;
		delete( $state->{_dispatch} );
		#warn "last request state = ", dump( $state ), "\n" if $self->debug > 1;
	}


	$sock->send(join("\r\n",
		'HTTP/1.1 200 OK',
		'Content-Type: text/xml; charset="utf-8"',
		'Server: AcmeCWMP/42',
		'SOAPServer: AcmeCWMP/42'
	)."\r\n");

	$sock->send( "Set-Cookie: ID=" . $state->{ID} . "; path=/\r\n" ) if ( $state->{ID} );

	my $uid = $self->store->ID_to_uid( $state->{ID}, $state );

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
	} elsif ( $size == 0 ) {
		warn ">>> no more queued commands, closing connection to $uid\n";
		return 0;
	} else {
		warn ">>> empty response to $uid\n";
		$state->{NoMoreRequests} = 1;
		$xml = $self->dispatch( 'xml', sub {} );
	}

	$sock->send( "Content-Length: " . length( $xml ) . "\r\n\r\n" );
	$sock->send( $xml ) or die "can't send response";

	warn ">>>> " . $sock->peerhost . " [" . localtime() . "] sent ", length( $xml )," bytes to $uid\n";

	$job->finish if $job;
	warn "### request over for $uid\n" if $self->debug;

	return 1;	# next request
};

=head2 dispatch

  $xml = $self->dispatch('Inform', $response_arguments );

If debugging level of 3 or more, it will create dumps of responses named C<< dump/nr.response >>

=cut

sub dispatch {
	my $self = shift;

warn "##!!! dispatch(",dump( @_ ),")\n";

	my $dispatch = shift || die "no dispatch?";
	my $args = shift;

	my $response = CWMP::Methods->new({ debug => $self->debug });

	if ( $response->can( $dispatch ) ) {
		warn ">>> dispatching to $dispatch with args ",dump( $args ),"\n";
		my $xml = $response->$dispatch( $self->state, $args );
		warn "## response payload: ",length($xml)," bytes\n$xml\n" if $self->debug;
		if ( $self->debug > 2 ) {
			my $file = sprintf("dump/%04d-%s.response", $dump_nr++, $self->sock->peerhost);
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
