use lib './lib';

use inc::Module::Install;

name		'CWMP';
version		'0.14';
license		'GPL';
requires	'Net::Server::Fork';
requires	'HTTP::Daemon';
requires	'XML::Rules';
requires	'XML::Generator';
requires	'Data::Dump';
requires	'Carp';
requires	'Class::Accessor';
requires	'Net::HTTP';
requires	'Cwd';
requires	'File::Slurp';
requires	'Getopt::Long';
#requires	'Term::Shelly'	=>	'0.03';
requires	'Module::Pluggable';
requires	'Hash::Merge';
requires	'IPC::DirQueue';
requires	'File::Spec';
requires	'File::Path';
requires	'Class::Trigger';
requires	'File::Find';

build_requires 'Test::More';

features(
	'CWMP::Store::YAML' => [
		-default => 1,
		recommends('YAML::Syck' => 0.91),
	],
	'CWMP::Store::JSON' => [
		-default => 1,
		recommends('JSON::XS'),
	],
	'Command-line access to modems (tcli.pl)' => [
		-default => 1,
		recommends('Expect'),
		recommends('Net::Telnet'),
	],
	'HTML documentation (make html)' => [
		-default => 0,
		recommends('Pod::Xhtml'),
	],
	'Pod coverage tests (for developers)' => [
		-default => 0,
		recommends('Test::Pod::Coverage'),
	],
#	'Memory leak detection (for developers)' => [
#		-default => 0,
#		recommends('Devel::LeakTrace::Fast' => 0.11),
#	],
);

my_targets();

clean_files('dump/* yaml state.db html t/var/* queue');

auto_install;

WriteAll;
