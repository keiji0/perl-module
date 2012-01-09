package Util::Require;

use strict;
use warnings;

my %load_files;
sub require_once {
  my $path = shift;
  $load_files{$path} and return 0;
  #do $path; $@ and die $@;
  eval {
    require $path;
  }; $@ and die $@;
  $load_files{$path} = 1;
}

1
