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

	#warn "state used to generate xml = ", dump( $state ) if $self->debug;

	my $X = XML::Generator->new(':pretty');

	my @header;
	push( @header, $X->ID( $cwmp, { mustUnderstand => 1 }, $state->{ID} )) if $state->{ID};
	push( @header, $X->NoMoreRequests( $cwmp, $state->{NoMoreRequests} || 0 ));

	return $X->Envelope( $soap, { 'soap:encodingStyle' => "http://schemas.xmlsoap.org/soap/encoding/" },
		$X->Header( $soap, @header ),
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
		$X->GetRPCMethods( $cwmp, '' );
	});
};

=head2 SetParameterValues

  $method->SetParameterValues( $state, {
	param1 => 'value1',
	param2 => 'value2',
	...
  });

It doesn't support base64 encoding of values yet.

To preserve data, it does support repeatable parametar names.
Behaviour on this is not defined in protocol.

=cut

sub SetParameterValues {
	my $self = shift;
	my $state = shift;

	confess "SetParameterValues needs parameters" unless @_;

	my $params = shift || return;

	warn "# SetParameterValues = ", dump( $params ), "\n" if $self->debug;

	$self->xml( $state, sub {
		my ( $X, $state ) = @_;

		$X->SetParameterValues( $cwmp,
			$X->ParameterList( [], { 'soap:arrayType' => 'cwmp:ParameterValueStruct['.(scalar keys %$params).']' },
				map {
					$X->ParameterValueStruct( [],
						$X->Name( [], $_ ),
						$X->Value( [], $params->{$_} )
					)
				} sort keys %$params
			),
			$X->ParameterKey( '' ),
		);
	});
}


=head2 GetParameterValues

  $method->GetParameterValues( $state, [ 'ParameterName', ... ] );

=cut

sub _array_param {
	my $v = shift;
	confess "array_mandatory(",dump($v),") isn't ARRAY" unless ref($v) eq 'ARRAY';
	return @$v;
}

sub GetParameterValues {
	my $self = shift;
	my $state = shift;
	my @ParameterNames = _array_param(shift);
	warn "# GetParameterValues", dump( @ParameterNames ), "\n" if $self->debug;

	$self->xml( $state, sub {
		my ( $X, $state ) = @_;

		$X->GetParameterValues( $cwmp,
			$X->ParameterNames( { 'soap:arrayType' => 'xsd:string[' . ( $#ParameterNames + 1 ) . ']' },
				map {
					$X->string( $_ )
				} @ParameterNames
			)
		);
	});
}

=head2 GetParameterNames

  $method->GetParameterNames( $state, [ $ParameterPath, $NextLevel ] );

=cut

sub GetParameterNames {
	my ( $self, $state, $param ) = @_;
	# default: all, all
	my ( $ParameterPath, $NextLevel ) = _array_param( $param );
	$ParameterPath ||= '';
	$NextLevel ||= 0;
	warn "# GetParameterNames( '$ParameterPath', $NextLevel )\n" if $self->debug;
	$self->xml( $state, sub {
		my ( $X, $state ) = @_;

		$X->GetParameterNames( $cwmp,
			$X->ParameterPath( $cwmp, $ParameterPath ),
			$X->NextLevel( $cwmp, $NextLevel ),
		);
	});
}

=head2 GetParameterAttributes

	$method->GetParameterAttributes( $state, [ $ParametarNames, ... ] );

=cut

sub GetParameterAttributes {
	my ( $self, $state, $param ) = @_;
	my @ParameterNames = _array_param($param);

	warn "# GetParameterAttributes", dump( @ParameterNames ), "\n" if $self->debug;

	$self->xml( $state, sub {
		my ( $X, $state ) = @_;

		$X->GetParameterAttributes( $cwmp,
			$X->ParameterNames( $cwmp,
				map {
					$X->string( $xsd, $_ )
				} @ParameterNames
			)
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

=head2 FactoryReset

  $method->FactoryReset( $state );

=cut

sub FactoryReset {
	my ( $self, $state ) = @_;
	$self->xml( $state, sub {
		my ( $X, $state ) = @_;
		$X->FactoryReset();
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
