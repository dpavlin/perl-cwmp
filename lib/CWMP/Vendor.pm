package CWMP::Vendor;

use strict;
use warnings;


use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/
debug
/ );

#use Carp qw/confess/;
use Data::Dump qw/dump/;

=head1 NAME

CWMP::Vendor - implement vendor specific logic into ACS server

=head1 METHODS

=head2 new

  my $obj = CWMP::Vendor->new({
	debug => 1
  });

=cut

my $debug = 0;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	warn "created ", __PACKAGE__, "(", dump( @_ ), ") object\n" if $self->debug;

	$debug = $self->debug;

	return $self;
}

our $cpe_faulty;

my $serial2ip = {
	'CP0636JT3SH' => '10.0.0.1',
	'CP0644JTHJ4' => '10.0.0.2',
	'CP0624BH55U' => '10.0.0.3',
};

my ( $last_ip, $last_serial );

=head2 state2serial

  my $serial = state2serial( $state );

=cut

sub state2serial {
	my $state = shift;

	my $serial = $state->{DeviceId}->{SerialNumber} || die "no DeviceId.SerialNumber in ",dump($state);
	chomp($serial);
	my $ip =
		$state->{Parameter}->{'.ExternalIPAddress'} ||
		$state->{Parameter}->{
			# fix for firmware 5.3.3.4 which returns full path
			( grep { m/\.ExternalIPAddress/ } keys %{ $state->{Parameter} } )[0]
		} ||
		die "no .ExternalIPAddress in ",dump($state);

	warn "## state2serial $serial $ip\n" if $debug;

	( $last_ip, $last_serial ) = ( $ip, $serial );

	return ( $serial, $ip );
}

=head2 add_triggers

Install all custom triggers

  CWMP::Vendor->add_triggers;

=cut

sub add_triggers {
}

1;

__END__

	warn __PACKAGE__, "->add_triggers\n" if $debug;

CWMP::Request->add_trigger( name => 'Fault', callback => sub {
	my ( $self, $state ) = @_;
	warn "## Fault trigger state = ",dump( $self, $state ) if $debug;
	die "can't map fault to serial!" unless $last_serial;
	warn "ERROR: got Fault and ingoring $last_ip $last_serial\n";
	$cpe_faulty->{$last_serial}++;
});

CWMP::Request->add_trigger( name => 'Inform', callback => sub {
	my ( $self, $state ) = @_;

	my ( $serial, $ip ) = state2serial( $state );

	if ( $cpe_faulty->{$serial} ) {
		warn "## Inform trigger from $ip $serial -- IGNORED\n" if $debug;
		return;
	}

	warn "## Inform trigger from $ip $serial\n" if $debug;

	my $found = 0;

	warn "### serial2ip = ",dump( $serial2ip ) if $debug;

	foreach my $target_serial ( keys %$serial2ip ) {

		next unless $target_serial eq $serial;

		$found++;

		my $target_ip = $serial2ip->{$target_serial};

		if ( $ip ne $target_ip ) {

			warn "CHANGE IP $ip to $target_ip for $serial\n";

			return; # FIXME

			my $q = CWMP::Queue->new({ id => $serial, debug => $debug }) || die "no queue?";

			$q->enqueue( 'SetParameterValues', {
				'InternetGatewayDevice.LANDevice.1.LANHostConfigManagement.IPInterface.1.IPInterfaceIPAddress' => $target_ip,
			});

		} else {
			warn "IP $ip of $serial ok\n";
		}
	}

	warn "UNKNOWN CPE $ip $serial\nadd\t'$serial' => '$ip',\n" unless $found;

});

}#add_triggers

1;
