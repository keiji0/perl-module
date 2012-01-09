package Util::Fun;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw(
  once curry hash_copy farray memq select_hash
  merge compose andcal andcheckcal fold
);

sub hash_copy {
  my $ht = shift;
  my %new_ht = %{$ht};
  \%new_ht;
}

sub once {
  # 一度だけ実行する関数を作る
  # once(sub { 8 });
  my ($fun) = @_;
  my $once_flag = 0;
  my $result;
  sub {
    if ($once_flag) {
      $result;
    } else {
      $once_flag = 1;
      $result = $fun->(@_);
    }
  }
}

sub curry {
  my ($fun, @args) = @_;
  sub {
    $fun->(@args, @_)
  }
}

sub farray {
  # 強制的に配列に変換する
  my $x = shift;
  if ($x) {
    if (ref $x eq 'ARRAY') {
      return @{$x};
    } else {
      return ($x);
    }
  } else {
    return ();
  }
}

sub select_hash {
  my ($keys, $hash) = @_;
  my %new_hash;
  defined $hash->{$_} and ($new_hash{$_} = $hash->{$_}) for @{$keys};
  \%new_hash;
}

sub memq {
  my ($item, $array) = @_;
  for (@{$array}) {
    $_ eq $item and return $_;
  }
}

sub merge {
  my ($base, @tables) = @_;
  $base ||= {};
  for my $table (@tables) {
    $base->{$_} = $table->{$_} for keys %{$table};
  }
  $base
}

sub compose {
  my ($funs) = @_;
  if ($#$funs == 0) {
    pop @$funs;
  } elsif ($#$funs == 1) {
    sub { (pop @$funs)->((pop @$funs)->(@_)) }
  } else {
    compose([shift @$funs, compose($funs)]);
  }
}

sub andcal {
  my ($fun, $def, $val) = @_;
  defined $val and return $fun->($val);
  $def;
}

sub andcheckcal {
  my ($check, $fun, $val, $def) = @_;
  defined $val and $check->($val) and return $fun->($val);
  $def;
}

sub fold (&$@) {
  my ($fun, $seed, @list) = @_;
  $seed = $fun->($_, $seed) for @list;
  $seed;
}

1
