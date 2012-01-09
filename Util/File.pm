package Util::File;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw(to_string);

sub to_string {
  my $path = shift;
  open my $in, '<', $path or die $!.': '.$path;
  my $out;
  read $in, $out, -s $in;
  close $in;
  $out;
}

1
