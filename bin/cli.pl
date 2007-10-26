#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Term::Shelly;
use CWMP::Store;
use CWMP::Tree;
use DBM::Deep;
use Data::Dump qw/dump/;
use Getopt::Long;
use Carp qw/confess/;

my $debug = 0;
my $store_path = 'state.db';

GetOptions(
	'debug+' => \$debug,
	'store-path=s' => \$store_path,
);

my $sh = Term::Shelly->new();
my $tree = CWMP::Tree->new({ debug => $debug });

our $store = CWMP::Store->new({
	debug => $debug,
	path => $store_path,
});

$sh->out(
"You can issue commenads in form using tab-complete:

CPE_Serial ( parametar [ [=] value ] | command )
"
);

$sh->{"completion_function"} = \&completer;
$sh->{"readline_callback"} = \&command;

my @history = ( 'exit' );
my $pos = $#history;
$sh->{'mappings'}->{'up-history'} = [ sub {
	my $self = shift;
	if ( $pos >= 0 ) {
		$self->{'input_line'} = $history[ $pos ];
		$pos--;
		$self->{'input_position'} = length( $self->{'input_line'} );
		$self->fix_inputline;
	}
} ];
$sh->{'mappings'}->{'down-history'} = [ sub {
	my $self = shift;
	my $line = '';
	if ( $pos < $#history ) {
		$pos++;
		$line = $history[ $pos ];
	}
	$self->{'input_line'} = $line;
	$self->{'input_position'} = length( $self->{'input_line'} );
	$self->fix_inputline;
} ];

$sh->prompt( '> ' );

while (1) {
	$sh->do_one_loop();
}

sub completer {
	my ($line, $bword, $pos, $curword) = @_;

	$sh->out( "line: '$line' [ $bword - $pos ] -> '$curword'" );

	my @matches;

	# do we have list (part) of CPE?
	if ( $line =~ /^(\S*)\s*$/ ) {
		@matches = sort grep { /^\Q$curword\E/ } $store->known_CPE;
		$sh->out( "CPE available: ", join(",", @matches ) );
	} elsif ( $line =~ /^(\w+)\s+(\S+)$/ ) {
		$sh->out("finding completes for '$2'");
		my ( $cpe_uid, $name ) = ( $1, $2 );

		my $beginning = $name;
		my $part = '';
		if ( $beginning =~ s/\.([^\.]+)$// ) {
			$part = $1;
		} elsif ( $beginning =~ s/^(\S+)$// ) {
			$part = $1;
		} else {
			confess "can't extract suffix";
		}

		$sh->out( "## $cpe_uid ## beginning: $beginning -- part: $part" );
		my $perl = "\$store->db->{state}->{'$cpe_uid'}->{ParameterInfo}";
		$perl .= '->' . $tree->name2perl( $beginning ) if ( defined( $beginning ) && $beginning ne '' );
		$sh->out( "## $cpe_uid ## $perl" );

		@matches = eval "keys %{ $perl }";

	}

	return @matches;
}

sub command {
	my ( $line ) = @_;

	return unless ( $line && $line ne '' );

	# just CPE uid
	if ( $line =~ /^(\w+)\s*$/ ) {
		if ( main->can( $1 ) ) {
			$sh->out( "# execute command $1" );
			eval " \&$1( \$line ) ";
		} elsif ( defined ( $store->db->{state}->{$1} ) ) {
			$sh->out(
				join(" ", keys %{ $store->db->{state}->{$1}->{ParameterInfo} })
			);
			push @history, $line;
			$pos = $#history;
		} else {
			$sh->out( "$line: CPE not found" );
		}
	} else {
		$sh->out( "$line: command not recognized" );
	}
}

sub history {
	$sh->out( "history: ", dump ( @history ) );
}

sub exit {
	CORE::exit();
}
