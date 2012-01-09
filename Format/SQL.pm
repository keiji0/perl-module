use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw(sqlmakewhere);

sub makewhere {
  my ($db, @k) = @_;
  @k = grep { defined $_->[1] } @k;
  if (@k) {
    my $c = 0;
    return ' WHERE '.join('', map { (($c++ && $_->[1]) ? ' '.$_->[0].' ' : '').$_->[1] } @k);
  }
  '';
}

1
