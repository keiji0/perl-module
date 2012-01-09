package Template::Perl;

use strict;
use warnings;
use Util::Fun qw(merge);
use base qw(Exporter);

our @EXPORT;
our @EXPORT_OK = qw(extend with context);

our $context = {};

sub with (&) {
  local $context = merge {}, $context;
  (shift)->(@_);
}

sub context () { $context }
sub extend {
  my ($name, $fun) = @_;
  no strict 'refs';
  *{ 'Template::Perl::'.$name } = $fun;
  push @EXPORT, $name;
}

1
