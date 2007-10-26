# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/22/07 14:35:38 CEST
package CWMP::Server;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
port
store_path
default_queue
background
debug

server
/ );

use CWMP::Session;

use Carp qw/confess/;
use Data::Dump qw/dump/;

=head1 NAME

CWMP::Server - description

=head1 METHODS

=head2 new

  my $server = CWMP::Server->new({
  	port => 3333,
	store_path => 'state.db',
	default_queue => [ qw/GetRPCMethods GetParameterNames/ ],                                                           
	background => 1,
	debug => 1
  });

Options:

=over 4

=item port

port to listen on

=item store_path

path to L<DBM::Deep> database file to preserve state

=item default_queue

commands which will be issued to every CPE on connect

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
			default_queue => $self->default_queue,
			store_path => $self->store_path,
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
	foreach my $p ( qw/ store_path debug / ) {
		$prop->{ $p } ||= undef;
		$template->{ $p } = \$prop->{ $p };
	}

	# new multi-value options
	foreach my $p ( qw/ default_queue / ) {
		$prop->{ $p } ||= [];
		$template->{ $p } = $prop->{ $p };
	}
}


=head2 process_request

=cut

sub process_request {
	my $self = shift;

	my $prop = $self->{server};
	confess "no server in ", ref( $self ) unless $prop;
	my $sock = $prop->{client};
	confess "no sock in ", ref( $self ) unless $sock;

	warn "default CPE queue ( " . join(",",@{$prop->{default_queue}}) . " )\n" if defined($prop->{default_queue});

	my $session = CWMP::Session->new({
		sock => $sock,
		queue => $prop->{default_queue},
		store_path => $prop->{store_path},
		debug => $prop->{debug},
	}) || confess "can't create session";

	while ( $session->process_request ) {
		warn "...another one bites the dust...\n";
	}

	warn "...returning to accepting new connections\n";

}

1;
