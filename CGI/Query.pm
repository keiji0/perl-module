package CGI::Query;

use strict;
use warnings;
use utf8;
use base qw(Exporter);
our @EXPORT_OK = qw(queryjoin);

sub queryjoin {
  use URI::Escape;
  my $query = shift;
  my @a;
  push @a, $_.'='.uri_escape $query->{$_} for keys %$query;
  join '&', @a;
}

1
