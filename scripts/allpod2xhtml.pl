#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use Pod::Xhtml;
use Pod::Usage;
use Getopt::Long;
use File::Find;
use File::Slurp;

# Default options
my %opt = (index => 1, toplink => 'Top');
GetOptions(\%opt, qw(css=s toplink|backlink=s help index! infile:s outfile:s existing! frames:s))
    || pod2usage();
pod2usage(-verbose => 2) if $opt{help};

my ($in,$out) = @ARGV;

pod2usage() unless ($in && $out);

my $toplink = $opt{toplink} ?
    sprintf '<p><a href="#TOP" class="toplink">%s</a></p>', $opt{toplink} : '';

$opt{css} ||= 'pod.css';

my $link_parser = new LinkResolver( $opt{css} );
my $parser = new Pod::Xhtml(StringMode => 1, LinkParser => $link_parser);

my $parser = new Pod::Xhtml(
    MakeIndex  => $opt{index},
    TopLinks   => $toplink,
	LinkParser => $link_parser,
);
if ($opt{css}) {
    $parser->addHeadText(qq[<link rel="stylesheet" href="$opt{css}"/>]);
}

my @navigation;

# collect existing files
find({
	wanted => sub {
		return unless (-f && -s && m/.html*$/i);
		push @navigation, $_;
	},
	no_chdir => 1,
}, $out) if ($opt{existing});

# find all files to convert to pod
find({
	wanted => sub {
		return unless (-f && -s && m/\.(pl|pm|pod)$/i);

		my $in_pod = $_;
		my $out_html = $_;
	
		# strip all up to filename
#		$out_html =~ s#^.*/([^/]+)$#$1#;

		# strip common prefix
		$out_html =~ s#.*$in/*##;
		$out_html =~ s#/+#-#g;

		# rename to .html
		$out_html =~ s#\.(pl|pm|pod)$#.html#;
		my $nav = $out_html;
		$out_html = $out . '/' . $out_html;

		print "$in_pod -> $out_html\n";

		$parser->parse_from_file($in_pod, $out_html);

		$nav =~ s#\.html$##i;
		push @navigation, $nav;
	},
	no_chdir => 1,
}, $in);

my $css_file = $out . '/' . $opt{css};
if (! -e $css_file) {
	open(my $css, '>', $css_file) || die "can't open $css_file: $!";
	while(<DATA>) {
		print $css $_;
	}
	close($css);
}

exit unless ($opt{frames});

# dump navigation html

my $nav = qq(
<html>
<head>
<link rel="stylesheet" href="pod.css"/>
</head>
<body>
<p>
);

my $first;

foreach my $f (sort @navigation) {

	$first ||= $f;

	$f =~ s#^$out/##;
	$f =~ s#\.html*$##;
	my $text = $f;
	$text =~ s#-#::#g;

	warn "+nav $f -> $text\n";

	$nav .= qq{ <br/><a href="${f}.html" target="pod">$text</a>\n};
}

$nav .= qq{
</p>
</html>
};

write_file( "$out/toc.html", $nav );

my $frameset = qq(
<html>
<head>
<title>$opt{frames}</title>
</head>
<FRAMESET COLS="*, 250">
    <FRAME src="./${first}.html" name="pod">
    <FRAME src="./toc.html" name="toc">
    <NOFRAMES>
        <a style="display: none" href="./toc.html">Table of Contents</a>
    </NOFRAMES>
</FRAMESET>
</html>
);

write_file( "$out/index.html", $frameset );

#
# Subclass Pod::Hyperlink to create self-referring links
#

package LinkResolver;
use Pod::ParseUtils;
use base qw(Pod::Hyperlink);

sub new
{
	my $class = shift;
	my $css = shift;
	my $self = $class->SUPER::new();
	$self->{css} = $css;
	return $self;
}

sub node
{
	my $self = shift;
	if($self->SUPER::type() eq 'page')
	{
		my $url = $self->SUPER::page();
		$url =~ s/::/-/g;
		$url .= '.html';
		return $url;
	}
	$self->SUPER::node(@_);
}

sub text
{
	my $self = shift;
	return $self->SUPER::page() if($self->SUPER::type() eq 'page');
	$self->SUPER::text(@_);
}

sub type
{
	my $self = shift;
	return "hyperlink" if($self->SUPER::type() eq 'page');
	$self->SUPER::type(@_);
}

1;

package main;

=pod

=head1 NAME

allpod2xhtml - convert .pod files to .xhtml files

=head1 SYNOPSIS

    allpod2xhtml [--help] [OPTIONS] source_dir dest_dir

=head1 DESCRIPTION

Converts files from pod format (see L<perlpod>) to XHTML format.

=head1 OPTIONS

=over 4

=item --help 

display help

=item --infile FILENAME

the input filename. STDIN is used otherwise

=item --outfile FILENAME

the output filename. STDOUT is used otherwise

=item --css URL

Stylesheet URL

=item --index/--noindex

generate an index, or not. The default is to create an index.

=item --toplink LINK TEXT

set text for "back to top" links. The default is 'Top'.

=item --frames TITLE OF FRAMESET

create C<index.html> and C<toc.html> with frameset for all converted douments

=item --existing

include existing html files in C<dest_dir> in navigation

=back

=head1 BUGS

See L<Pod::Xhtml> for a list of known bugs in the translator.

=head1 AUTHOR

P Kent E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

Dobrica Pavlinusic C<< <dpavlin@rot13.org> >>

=head1 COPYRIGHT

(c) BBC 2004. This program is free software; you can redistribute it and/or
modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=head1 SEE ALSO

L<perlpod>, L<Pod::Xhtml>

=cut

__DATA__
BODY {
	color: black;
	font-family: arial,sans-serif;
	margin: 0;
	padding: 1ex;
}

TABLE {
	border-collapse: collapse;
	border-spacing: 0;
	border-width: 0;
	color: inherit;
}

IMG { border: 0; }
FORM { margin: 0; }
input { margin: 2px; }

A:link, A:visited {
	background: transparent;
	color: #006699;
}

A[href="#POD_ERRORS"] {
	background: transparent;
	color: #FF0000;
}

TD {
	margin: 0;
	padding: 0;
}

DIV {
	border-width: 0;
}

DT {
	margin-top: 1em;
}

TH {
	background: #bbbbbb;
	color: inherit;
	padding: 0.4ex 1ex;
	text-align: left;
}

TH A:link, TH A:visited {
	background: transparent;
	color: black;
}

.pod PRE     {
	background: #eeeeee;
	border: 1px solid #888888;
	color: black;
	padding: 1em;
	padding-bottom: 0;
	white-space: pre;
}

.pod H1      {
	background: transparent;
	color: #006699;
	font-size: large;
}

.pod H2      {
	background: transparent;
	color: #006699;
	font-size: medium;
}

.pod IMG     {
	vertical-align: top;
}

.pod .toc A  {
	text-decoration: none;
}

.pod .toc LI {
	line-height: 1.2em;
	list-style-type: none;
}

.faq DT {
	font-size: 1.4em;
	font-weight: bold;
}

.toplink {
	margin: 0;
	padding: 0;
	float: right;
	font-size: 80%;
}
