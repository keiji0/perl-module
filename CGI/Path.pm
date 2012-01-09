package CGI::Path;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw(cgipath);

{
  my $path = $ENV{PATH_INFO};
  sub cgipath { $path }
}

1
