# Dobrica Pavlinusic, <dpavlin@rot13.org> 10/26/07 14:26:36 CEST
package Module::Install::PRIVATE;

use strict;
use warnings;

use base 'Module::Install::Base';
our $VERSION = '0.01';

=head1 NAME

Module::Install::PRIVATE - Module Install Support

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 my_targets

=cut

sub my_targets {
	my ($self) = @_;

	$self->postamble(<<"END_MAKEFILE");
# --- $self section:

dump: all
	rm dump/* || true
	./bin/acs.pl -d -d -d 2>&1 | tee log

html: \$(MAN1PODS) \$(MAN3PODS)
	test -d html || mkdir html
	allpod2xhtml.pl lib/ html/

END_MAKEFILE

	warn "added my targets: dump\n";

	return $self;
}

1;
