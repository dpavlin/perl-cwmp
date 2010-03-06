# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/22/07 14:35:38 CEST
package CWMP::Server;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
port
session
background
debug
create_dump

server
/ );

use CWMP::Session;
use CWMP::Queue;

use Carp qw/confess/;
use Data::Dump qw/dump/;

use IO::Socket::INET;
use File::Path qw/mkpath/;
use File::Slurp;

=head1 NAME

CWMP::Server - description

=head1 METHODS

=head2 new

  my $server = CWMP::Server->new({
  	port => 3333,
	session => { ... },
	background => 1,
	debug => 1
  });

Options:

=over 4

=item port

port to listen on

=item session

hash with key C<module> with value C<DBMDeep> if L<CWMP::Store::DBMDeep>
is used. Other parametars are optional.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") object\n" if $self->debug;

	warn "ACS waiting for request on port ", $self->port, "\n";

	$self->debug( 0 ) unless $self->debug;
	warn "## debug level: ", $self->debug, "\n" if $self->debug;

	return $self;
}

=head2 run

=cut

sub run {
	my $self = shift;

	my $server = IO::Socket::INET->new(
			Proto     => 'tcp',
			LocalPort => $self->port,
			Listen    => SOMAXCONN,
			Reuse     => 1
	) || die "can't start server on ", $self->port, ": $!";

	warn "listen on ", $server->sockhost, ":", $server->sockport, "\n";

	while (1) {
		my $client = $server->accept() || next; # ALARM trickle us

		my $session = CWMP::Session->new( $self->session ) || confess "can't create sessision";

		while ( $self->sock_session( $client, $session ) ) {
			warn "# another one\n";
		}

		warn "# connection to ", $client->peerhost, " closed\n";
	}

}

my $dump_by_ip;

sub sock_session {
	my ( $self, $sock, $session ) = @_;

	my $request = <$sock>;
	return unless $request;
	my $ip = $sock->peerhost;

	my $headers;

	while ( my $header = <$sock> ) {
		$request .= $header;
		chomp $header;
		last if $header =~ m{^\s*$};
		my ( $n, $v ) = split(/:\s*/, $header);
		$v =~ s/[\r\n]+$//;
		$headers->{ lc $n } = $v;
	}

	warn "<<<< $ip START\n$request\n";

	return $sock->connected unless $headers;

warn dump( $headers );

	warn "missing $_ header\n" foreach grep { ! defined $headers->{ lc $_ } } ( 'SOAPAction' );

	my $body;
	if ( my $len = $headers->{'content-length'} ) {
		read( $sock, $body, $len );
	} elsif ( $headers->{'transfer-encoding'} =~ m/^chunked/i ) {
		while ( my $len = <$sock> ) {
warn "chunked ",dump($len);
			$len =~ s/[\r\n]+$//;
			$len = hex($len);
			last if $len == 0;
warn "reading $len bytes\n";
			read( $sock, my $chunk, $len );
warn "|$chunk| $len == ", length($chunk);
			$body .= $chunk;
			my $padding = <$sock>;
warn "padding ",dump($padding);
		}
	} else {
		warn "empty request\n";
	}

	warn "$body\n<<<< $ip END\n";

	my $response = $session->process_request( $ip, $body );

	my $dump_nr = $dump_by_ip->{$ip}++;

	if ( $self->create_dump ) {
		mkpath "dump/$ip" unless -e "dump/$ip";
		write_file( sprintf("dump/%s/%04d.request", $ip, $dump_nr), "$request\r\n$body" );
		write_file( sprintf("dump/%s/%04d.response", $ip, $dump_nr ), $response );
	}

	warn ">>>> $ip START\n$response\n>>>> $ip END\n";
	print $sock $response;

	return $sock->connected;

}


1;
