use Util::Param;
package Util::Param;
use strict;
use warnings;

sub catch(&&) {
  my ($f, $eh) = @_;
  my $r;
  eval { $r = $f->(); };
  if (my $e = $@) {
    no strict 'refs';
    $r = ref $e eq __PACKAGE__ and return $eh->($e);
    die $@;
  }
  $r;
}

sub error {
  my $p;
  if (ref $_[0] eq __PACKAGE__) {
    $p = CORE::shift;
    my (%p) = @_;
    $p->set(%_);
  } else {
    my (%p) = @_;
    $p = new Util::Param(%p);
  }
  $p->(error => 1);
  die $p;
}

1
