package CWMP::Queue;

use strict;
use warnings;


use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
id
debug

/ );

#use Carp qw/confess/;
use Data::Dump qw/dump/;
use File::Spec;
use File::Path qw/mkpath/;
use IPC::DirQueue;
use Carp qw/confess/;

=head1 NAME

CWMP::Queue - implement commands queue for CPE

=head1 METHODS

=head2 new

  my $obj = CWMP::Queue->new({
  	id => 'CPE_serial_number',
	debug => 1
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	die "need id" unless $self->id;

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") object\n" if $self->debug;

	my $dir = File::Spec->catfile('queue',$self->id);

	if ( ! -e $dir ) {
		mkpath $dir || die "can't create $dir: $!";
		print "created new queue $dir\n";
	}

	my $id = $self->id;

	if ( ! defined( $self->{dq}->{$id} ) ) {
		$self->{dq}->{$id} = IPC::DirQueue->new({
			dir => $dir,
			ordered => 1,
			queue_fanout => 0,
		});
		warn "## created queue object for CPE $id path $dir\n" if $self->debug;
	}

	return $self;
}

=head2 enqueue

  $q->enqueue(
  	'foo.bar.baz' => 42,
  );

=cut

sub enqueue {
	my $self = shift;

	my $id = $self->id;
	my $data = {@_} || confess "need data";

	warn "## enqueue( $id, ", dump( $data ), " )\n" if $self->debug;

	$self->{dq}->{$id}->enqueue_string( $id, $data );
}

=head2 dequeue

  my $data = $q->dequeue;

=cut

sub dequeue {
	my $self = shift;

	my $id = $self->id;

	my $data = $self->{dq}->{$id}->pickup_queued_job();
	return unless defined $data;

	warn "## dequeue( $id ) = ", dump( $data ), " )\n" if $self->debug;

	return $data->{metadata};
}
1;
