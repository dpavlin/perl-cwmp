# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/22/07 14:35:38 CEST
package CWMP::_MODULE;

use strict;
use warnings;


use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
debug
/ );

#use Carp qw/confess/;
use Data::Dump qw/dump/;

=head1 NAME

CWMP::_MODULE - description

=head1 METHODS

=head2 new

  my $obj = CWMP::_MODULE->new({
	debug => 1
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") object\n" if $self->debug;

	return $self;
}


1;
