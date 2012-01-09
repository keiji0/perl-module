package Util::Path;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw(ddirlist);

sub ddirlist {
  use Util::Fun qw(fold);
  my ($path, $base) = @_;
  my @a;
  fold {
    my ($item, $seed) = @_;
    $item or return $seed;
    my $r = $seed.'/'.$item;
    push @a, $r;
    $r
  } $base || '', split m|/|, $path;
  \@a;
}

1
