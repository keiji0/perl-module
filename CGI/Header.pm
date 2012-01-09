package CGI::Header;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw(cgiheader);

sub cgiheader {
  print "Content-Type: text/html; charset=utf-8\n\n";
}

1
