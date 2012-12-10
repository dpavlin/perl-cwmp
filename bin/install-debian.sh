#!/bin/sh -x

sudo apt-get install libmodule-install-perl libdata-dump-perl \
	libclass-accessor-perl libfile-slurp-perl libhash-merge-perl libyaml-syck-perl \
	libyaml-perl build-essential \
	libtest-simple-perl libtest-expect-perl libnet-telnet-perl \
	libpod-xhtml-perl libtest-pod-coverage-perl \
	libxml-bare-perl libpod-xhtml-perl libwww-mechanize-perl \
	libxml-generator-perl dh-make-perl

test -f libipc-dirqueue-perl*.deb || cpan2deb IPC::DirQueue
sudo dpkg -i libipc-dirqueue-perl*.deb
