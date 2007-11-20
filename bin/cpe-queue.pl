#!/usr/bin/perl -w

# cpe-queue.pl
#
# 11/12/2007 10:03:53 PM CET  <>

use strict;

use lib './lib';
use CWMP::Queue;
use Getopt::Long;
use File::Slurp;

my $debug = 1;
my $protocol_dump = 0;
my $list = 0;

GetOptions(
	'debug+' => \$debug,
	'protocol-dump!' => \$protocol_dump,
	'list!' => \$list,
);

die "usage: $0 CPE_id [--protocol-dump]\n" unless @ARGV;

foreach my $id ( @ARGV ) {

	$id =~ s!^.*queue/+!!;
	$id =~ s!/+$!!;	#!

	die "ID isn't valid: $id\n" unless $id =~ m/^\w+$/;

	my $q = CWMP::Queue->new({ id => $id, debug => $debug });


	if ( $protocol_dump ) {

		warn "generating dump of xml protocol with CPE\n";

		$q->enqueue( 'GetRPCMethods' );

		$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.DeviceInfo.SerialNumber', 0 ] );
		$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.DeviceInfo.', 1 ] );

		$q->enqueue( 'GetParameterValues', [
			'InternetGatewayDevice.DeviceInfo.SerialNumber',
			'InternetGatewayDevice.DeviceInfo.VendorConfigFile.',
			'InternetGatewayDevice.DeviceInfo.X_000E50_Country',
		] );
		$q->enqueue( 'SetParameterValues', {
			'InternetGatewayDevice.DeviceInfo.ProvisioningCode' => 'test provision',
	#		'InternetGatewayDevice.DeviceInfo.X_000E50_Country' => 1,
		});

		$q->enqueue( 'Reboot' );

	}

	if ( $list ) {

		warn "list all jobs for $id\n";

		my @active = ();
		my @queued = ();
		my $hostname = $q->dq->gethostname();

		sub wanted {
		  my ($visitcontext, $job) = @_;

		  my $data = $job->get_data_path();
		  my $nbytes = $job->get_data_size_bytes();
		  my $timet = $job->get_time_submitted_secs();
		  my $hname = $job->get_hostname_submitted();
		  my $jobid = $job->{jobid};

		  my $text = sprintf (
					"%s (%d bytes)\n  Submitted: %s on %s\n",
					$jobid, $nbytes, scalar localtime $timet, $hname);

			$text .= read_file( $data ) || die "can't open $data: $!";

		  if ($job->{active_pid})
		  {
			if ($hostname eq $job->{active_host}
				&& !kill (0, $job->{active_pid}))
			{
			  $text = sprintf (
					"(dead lockfile)\n  %s",
					$text);
			}
			else {
			  $text = sprintf (
					"(pid: %d\@%s)\n  %s",
					$job->{active_pid}, $job->{active_host}, $text);
			}

			push (@active, $text);
		  }
		  else {
			push (@queued, $text);
		  }

		  $job->finish();
		}

		$q->dq->visit_all_jobs(\&wanted, undef);
		printf "Jobs: active: %d  queued: %d\n",
				scalar @active, scalar @queued;
		
		print "Active jobs [", scalar @active, "]\n",join("\n\n", @active) if @active;
		print "Queued jobs [", scalar @queued, "]\n",join("\n\n", @queued) if @queued;

	} else {

		warn "injecting some tests commands\n";

		$q->enqueue( 'GetRPCMethods' );

	#	$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.LANDevice.', 1 ] );

	#	$q->enqueue( 'GetParameterValues', [
	#		'InternetGatewayDevice.',
	#	]);

	#	$q->enqueue( 'GetParameterNames', [ '.ExternalIPAddress', 1 ] );

	#	$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.', 1 ] );
	#	$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.DeviceInfo.', 1 ] );
	#	$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.DeviceConfig.', 1 ] );
	#	$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.ManagementServer.', 1 ] );
	#	$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.Services.', 1 ] );
	#	$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.LANDevice.', 1 ] );

		$q->enqueue( 'GetParameterNames', [ 'InternetGatewayDevice.', 0 ] );
		$q->enqueue( 'GetParameterValues', [
			'InternetGatewayDevice.',
		]);
	}

}
