use inc::Module::Install;

name		'CWMP';
version		'0.04';
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
requires	'Term::Shelly'	=>	'0.03';

auto_install;

WriteAll;
