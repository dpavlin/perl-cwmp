# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/22/07 14:35:38 CEST
package CWMP::Tree;

use strict;
use warnings;


use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
debug
/ );

use Carp qw/confess/;
use Data::Dump qw/dump/;

=head1 NAME

CWMP::Tree - description

=head1 METHODS

=head2 new

  my $obj = CWMP::Tree->new({
	debug => 1
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") object\n" if $self->debug;

	return $self;
}

=head2 name2perl

Perl is dynamic language and we want parametars from TR-069 as
a tree. So we do rewrite of parametar to perl code and eval that.

  my $perl = $self->name2perl( 'InternetGatewayDevice.DeviceSummary' );

=cut

sub name2perl {
	my ( $self, $s ) = @_;

	confess "no name?" unless $s;

	warn "===> $s\n" if $self->debug;
	$s =~ s/^([^\.]+)/{'$1'}/;
	warn "---> $s\n"  if $self->debug;

	my $stat;
	while ( $s =~ s/\.(\d+)/->[$1]/ ) {
		$stat->{array}++;
		warn "-\@-> $s\n" if $self->debug;
	}
	while ( $s =~ s/\.([a-zA-Z0-9_]+)/->{'$1'}/ ) {
		$stat->{scalar}++;
		warn "-\$-> $s\n" if $self->debug;

	};

	warn "## $s ", dump( $stat ), $/ if $self->debug;

	return $s;
}

1;
