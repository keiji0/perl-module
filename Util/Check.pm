package Util::Check;

use strict;
use warnings;

sub number {
  $_[0] =~ /^\d+$/;
}

sub integer {
  $_[0] =~ /^[-+]?\d+$/;
}

sub string {
  not integer $_[0];
}

sub name {
  $_[0] =~ /^[a-zA-Z](\w|-)*$/;
}

sub email {
  $_[0] =~ /^[+a-zA-Z0-9_.￥-]+@[a-zA-Z0-9_.￥-]+$/;
}

1
