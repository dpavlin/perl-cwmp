use lib './lib';

use inc::Module::Install;

name		'CWMP';
version		'0.09';
license		'GPL';
requires	'Net::Server';
requires	'HTTP::Daemon';
requires	'XML::Rules';
requires	'XML::Generator';
requires	'Data::Dump';
requires	'Carp';
requires	'Class::Accessor';
requires	'Net::HTTP';
requires	'Cwd';
requires	'File::Slurp';
requires	'DBM::Deep';
requires	'Getopt::Long';
#requires	'Term::Shelly'	=>	'0.03';
requires	'Module::Pluggable';
requires	'YAML';
requires	'Hash::Merge';
requires	'IPC::DirQueue';
requires	'File::Spec';
requires	'File::Path';
requires	'Class::Trigger';

build_requires 'Test::More';

features(
	'Command-line access to modems (tcli.pl)' => [
		-default => 1,
		recommends('Expect'),
		recommends('Net::Telnet'),
	],
);

features(
	'HTML documentation (make html)' => [
		-default => 0,
		recommends('Pod::Xhtml'),
	],
);

features(
	'Pod coverage tests (for developers)' => [
		-default => 0,
		recommends('Test::Pod::Coverage'),
	],
);

;

my_targets();

clean_files('dump/* yaml state.db html t/var/* queue');

auto_install;

WriteAll;
