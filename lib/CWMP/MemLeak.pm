# Dobrica Pavlinusic, <dpavlin@rot13.org> 06/22/07 14:35:38 CEST
package CWMP::MemLeak;

use strict;
use warnings;


use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
tracker
generator
debug
/ );

#use Carp qw/confess/;
use Data::Dump qw/dump/;
use Devel::Events::Handler::ObjectTracker;
use Devel::Events::Generator::Objects;
use Devel::Size 'total_size';


=head1 NAME

CWMP::MemLeak - debugging module to detect memory leeks

=head1 METHODS

=head2 new

  my $leek = CWMP::MemLeak->new({
	debug => 1
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") object\n" if $self->debug;

	$self->tracker(Devel::Events::Handler::ObjectTracker->new());
	$self->generator(
		Devel::Events::Generator::Objects->new(handler => $self->tracker)
	);
					    
	$self->generator->enable();

	return $self;
}

=head2 report

  my $size = $leek->report;

=cut

my $empty_array = total_size([]);

sub report {
	my $self = shift;

	$self->generator->disable();

	my $leaked = $self->tracker->live_objects;
	my @leaks = keys %$leaked;

	my $size = total_size([ @leaks ]) - $empty_array;

	warn "leaked $size = ",dump( $leaked ),$/ if $size > 2;


	$self->generator(undef);
	$self->tracker(undef);

	return $size;
}

1;
