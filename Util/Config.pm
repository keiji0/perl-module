package Util::Config;

use strict;
use warnings;
use Util::Fun qw(merge);
use base qw(Exporter);
our @EXPORT_OK = qw(config load extend);

my $data = { };
sub load { $data = do shift or die $@ }
sub extend { $data = merge $data, do shift or die $@ }
sub config { $data->{(shift)} }
sub get { config shift }
sub set { $data->{($_[0])} = $_[1] }

1
