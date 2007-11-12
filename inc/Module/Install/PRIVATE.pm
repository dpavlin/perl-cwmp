#line 1
# Dobrica Pavlinusic, <dpavlin@rot13.org> 10/26/07 14:26:36 CEST
package Module::Install::PRIVATE;

use strict;
use warnings;

use base 'Module::Install::Base';
our $VERSION = '0.01';

#line 20

sub my_targets {
	my ($self) = @_;

	$self->postamble(<<"END_MAKEFILE");
# --- $self section:

dump: all
	rm dump/* || true
	./bin/acs.pl -d -d -d --protocol-dump 2>&1 | tee log

html: \$(MAN1PODS) \$(MAN3PODS)
	test -d html || mkdir html
	allpod2xhtml.pl --frames="Perl CWMP server" lib/ html/

END_MAKEFILE

	warn "added my targets: dump\n";

	return $self;
}

1;
