package Util::Context;

use strict;
use warnings;

sub let {
  my (%o) = @_;
  my $name = $o{name};
  eval 'package '.$name.'; use base qw(Exporter); our @EXPORT;';
  no strict 'refs';
  for my $var (keys %{$o{var}}) {
    push @{$name.'::EXPORT'}, $var;
    my $context = $o{var}->{$var};
    my $type = ref $context;
    if ($type eq 'CODE') { *{$name.'::'.$var} = $context }
    elsif ($type eq 'HASH') { *{$name.'::'.$var} = sub {
                                my $key = shift;
                                defined $key ?
                                  $context->{$key} :
                                  $context;
                              } }
    else { *{$name.'::'.$var} = sub {
             my $val = shift;
             defined $val ?
               $context = $val :
               $context;
           } }
  }
  $o{body}->();
}

1
