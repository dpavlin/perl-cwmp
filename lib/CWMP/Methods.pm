package CWMP::Methods;

use strict;
use warnings;


use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors( qw/debug/ );

use XML::Generator;
use Carp qw/confess/;
use Data::Dump qw/dump/;

=head1 NAME

CWMP::Methods - generate SOAP meesages for CPE

=head1 METHODS

=head2 new

  my $method = CWMP::Methods->new({ debug => 1 });

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	warn "created XML::Generator object\n" if $self->debug;

	return $self;
}

=head2 xml

Used to implement methods which modify just body of soap message.
For examples, see source of this module.

=cut

my $cwmp = [ cwmp => 'urn:dslforum-org:cwmp-1-0' ];
my $soap = [ soap => 'http://schemas.xmlsoap.org/soap/envelope/' ];
my $xsd  = [ xsd  => 'http://www.w3.org/2001/XMLSchema-instance' ];

sub xml {
	my $self = shift;

	my ( $state, $closure ) = @_;

	confess "no state?" unless ($state);
	confess "no body closure" unless ( $closure );

	confess "no ID in state ", dump( $state ) unless ( $state->{ID} );

	#warn "state used to generate xml = ", dump( $state ) if $self->debug;

	my $X = XML::Generator->new(':pretty');

	return $X->Envelope( $soap, { 'soap:encodingStyle' => "http://schemas.xmlsoap.org/soap/encoding/" },
		$X->Header( $soap,
			$X->ID( $cwmp, { mustUnderstand => 1 }, $state->{ID} ),
			$X->NoMoreRequests( $cwmp, $state->{NoMoreRequests} || 0 ),
		),
		$X->Body( $soap, $closure->( $X, $state ) ),
	);
}

=head1 CPE methods

=head2 GetRPCMethods

  $method->GetRPCMethods( $state );

=cut

sub GetRPCMethods {
	my ( $self, $state ) = @_;
	$self->xml( $state, sub {
		my ( $X, $state ) = @_;
		$X->GetRPCMethods();
	});
};

=head2 SetParameterValues

B<not implemented>

=head2 GetParameterValues

  $method->GetParameterValues( $state, $ParameterNames );

=cut

sub GetParameterValues {
	my $self = shift;
	my $state = shift;
	my @ParameterNames = @_;
	confess "need ParameterNames" unless @ParameterNames;
	warn "# GetParameterValues", dump( @ParameterNames ), "\n" if $self->debug;

	$self->xml( $state, sub {
		my ( $X, $state ) = @_;

		$X->GetParameterValues( $cwmp,
			$X->ParameterNames( $cwmp,
				map {
					$X->string( $xsd, $_ )
				} @ParameterNames
			)
		);
	});
}

=head2 GetParameterNames

  $method->GetParameterNames( $state, $ParameterPath, $NextLevel );

=cut

sub GetParameterNames {
	my ( $self, $state, $ParameterPath, $NextLevel ) = @_;
	$ParameterPath ||= '';	# all
	$NextLevel ||= 0;		# all
	warn "# GetParameterNames( '$ParameterPath', $NextLevel )\n" if $self->debug;
	$self->xml( $state, sub {
		my ( $X, $state ) = @_;

		$X->GetParameterNames( $cwmp,
			$X->ParameterPath( $cwmp, $ParameterPath ),
			$X->NextLevel( $cwmp, $NextLevel ),
		);
	});
}

=head2 Reboot

  $method->Reboot( $state );

=cut

sub Reboot {
	my ( $self, $state ) = @_;
	$self->xml( $state, sub {
		my ( $X, $state ) = @_;
		$X->Reboot();
	});
}


=head1 Server methods


=head2 InformResponse

  $method->InformResponse( $state );

=cut

sub InformResponse {
	my ( $self, $state ) = @_;
	$self->xml( $state, sub {
		my ( $X, $state ) = @_;
		$X->InformResponse( $cwmp,
			$X->MaxEnvelopes( $cwmp, 1 )
		);
	});
}

=head1 BUGS

All other methods are unimplemented.

=cut

1;
