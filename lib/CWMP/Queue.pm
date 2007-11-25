package CWMP::Queue;

use strict;
use warnings;


use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
id
dir
clean
debug

/ );

#use Carp qw/confess/;
use Data::Dump qw/dump/;
use File::Spec;
use File::Path qw/mkpath rmtree/;
use IPC::DirQueue;
use YAML::Syck qw/Dump/;
use Carp qw/confess/;

#use Devel::LeakTrace::Fast;

=head1 NAME

CWMP::Queue - implement commands queue for CPE

=head1 METHODS

=head2 new

  my $obj = CWMP::Queue->new({
  	id => 'CPE_serial_number',
	dir => 'queue',
	clean => 1,
	debug => 1
  });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	die "need id" unless $self->id;

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") object\n" if $self->debug;

	my $dir = File::Spec->catfile( $self->dir || 'queue', $self->id );

	if ( -e $dir && $self->clean ) {
		rmtree $dir || die "can't remove $dir: $!";
		warn "## clean $dir\n" if $self->debug;
	}

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
  	'CommandToDispatch', {
  		'foo.bar.baz' => 42,
	}
  );

=cut

sub enqueue {
	my $self = shift;

	my $id = $self->id;
	my ( $dispatch, $args ) = @_;

	warn "## enqueue( $dispatch with ", dump( $args ), " ) for $id\n" if $self->debug;
	
	$self->{dq}->{$id}->enqueue_string( Dump({ dispatch => $dispatch, args => $args }) );
}

=head2 dequeue

  my $job = $q->dequeue;
  my ( $dispatch, $args ) = $job->dispatch;
  # after dispatch is processed
  $job->finish;

=cut

sub dequeue {
	my $self = shift;

	my $id = $self->id;

	my $job = $self->{dq}->{$id}->pickup_queued_job();
	return unless defined $job;

	warn "## dequeue for $id = ", dump( $job ), " )\n" if $self->debug;

	return CWMP::Queue::Job->new({ job => $job, debug => $self->debug });
}

=head2 dq

Accessor to C<IPC::DirQueue> object

  my $dq = $q->dq;

=cut

sub dq {
	my $self = shift;
	return $self->{dq}->{$self->id};
}

package CWMP::Queue::Job;

=head1 CWMP::Queue::Job

Single queued job

=cut

use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
job
debug
/ );

use YAML qw/LoadFile/;
use Data::Dump qw/dump/;

=head2 dispatch

  my ( $dispatch, $args ) = $job->dispatch;

=cut

sub dispatch {
	my $self = shift;
	my $path = $self->job->get_data_path || die "get_data_path?";
	my $data = LoadFile( $path ) || die "can't read $path: $!";
	warn "## dispatch returns ",dump($data),"\n" if $self->debug;
	return ( $data->{dispatch}, $data->{args} );
}

=head2 finish

Finish job and remove it from queue

  $job->finish;

=cut

sub finish {
	my $self = shift;
	$self->job->finish;
	return 1;
}

1;
