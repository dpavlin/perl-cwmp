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

server
/ );

use CWMP::Session;
use CWMP::Queue;
use CWMP::MemLeak;

use Carp qw/confess/;
use Data::Dump qw/dump/;

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

	$self->server(
		CWMP::Server::Helper->new({
			proto => 'tcp',
			port => $self->port,
			session => $self->session,
			debug => $self->debug,
			background => $self->background,
		})
	);

	return $self;
}

=head2 run

=cut

sub run {
	my $self = shift;

	$self->server->run;
}

package CWMP::Server::Helper;

use warnings;
use strict;

use base qw/Net::Server/;
use Carp qw/confess/;
use Data::Dump qw/dump/;

sub options {
	my $self     = shift;
	my $prop     = $self->{'server'};
	my $template = shift;

	### setup options in the parent classes
	$self->SUPER::options($template);

	# new single-value options
	foreach my $p ( qw/ session debug / ) {
		$prop->{ $p } ||= undef;
		$template->{ $p } = \$prop->{ $p };
	}

	# new multi-value options
#	foreach my $p ( qw/ default_queue / ) {
#		$prop->{ $p } ||= [];
#		$template->{ $p } = $prop->{ $p };
#	}
}


=head2 process_request

=cut

sub process_request {
	my $self = shift;

	my $leak = CWMP::MemLeak->new;

	my $prop = $self->{server};
	confess "no server in ", ref( $self ) unless $prop;
	my $sock = $prop->{client};
	confess "no sock in ", ref( $self ) unless $sock;

	my $sess = $prop->{session} || confess "no session";

	eval  {
		$sess->{sock} = $sock;
		$sess->{debug} = $prop->{debug};

		my $session = CWMP::Session->new( $sess ) || confess "can't create session from ",dump( $sess );

		while ( $session->process_request ) {
			warn "...waiting for next request from CPE...\n" if $prop->{debug};
		}
	};

	warn "ERROR: $@\n" if $@;

	warn "...returning to accepting new connections\n" if $prop->{debug};

	$leak->report;

}

1;
