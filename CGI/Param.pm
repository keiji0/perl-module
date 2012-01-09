package CGI::Param;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw(cgiparam cgiparamref);

sub rawparam {
  use Encode;
  $ENV{REQUEST_METHOD} eq 'GET' and return $ENV{QUERY_STRING} || '';
  read STDIN, my $r, $ENV{CONTENT_LENGTH};
  encode_utf8 $r;
}

sub pencode {
  my $s = shift;
  $s =~ tr/+/ /;
  $s =~ s/%(..)/pack("H2", $1)/eg;
  $s
}

sub parseparam {
  my %p;
  for (split /&/, rawparam) {
    my ($k, $v) = split /=/;
    $p{pencode($k)} = pencode $v;
  }
  \%p;
}

{
  my $param = parseparam;
  sub cgiparamref { $param }
  sub cgiparam { $param->{$_[0]} }
}

1
