package Util::Param;

=head1 DESCRIPTION

連想配列をより簡単に使用するためのモジュール

=begin testing

use strict;
use warnings;
use lib qw(.);
use Util::Param;

my $param = new Util::Param;
ok $param, 'インスタンスの生成';
$param->('foo', 'bar');
ok $param->('foo') eq 'bar', '値が設定されているか';
ok not($param->('hoge')), '値が設定されていないか';
ok ref($param->()) eq 'HASH', '引数なしはハッシュデータを返す';
ok $param->()->{foo} eq 'bar', 'ハッシュデータからアクセス出来るか';

$param->push('array', 8);
$param->push('array', 20);
ok $param->pop('array') eq 20, '値をpushできるか';
ok $param->pop('array') eq 8, '値をpushできるか';

$param->unshift('array', 1);
$param->unshift('array', 2);
$param->unshift('array', 3);
ok $param->shift('array') eq 1, '値をshiftできるか1';
ok $param->shift('array') eq 2, '値をshiftできるか2';
ok $param->shift('array') eq 3, '値をshiftできるか3';

$param->push('array', 1);
$param->push('array', 2);
$param->push('array', 3);
ok join('', $param->array('array')) eq '123', '配列を受けとる';

=end testing
=cut

use strict;
use warnings;

our $VERSION = 0.1;

sub new {
  my ($class, %param) = @_;
  bless sub {
    my ($key, $val, @rest_val) = @_;
    if (defined $val) {
      $param{$key} = $val;
    } elsif (defined $key) {
      return $param{$key};
    } else {
      return \%param;
    }
  } => $class;
}

sub push {
  my ($self, $key, @vals) = @_;
  if (defined $self->($key)) {
    my $array = $self->($key);
    CORE::push @{$array}, $_ for @vals;
  } else {
    $self->($key, \@vals);
  }
}

sub unshift {
  my ($self, $key, @vals) = @_;
  if (defined $self->($key)) {
    my $array = $self->($key);
    CORE::push @{$array}, $_ for @vals;
  } else {
    $self->($key, \@vals);
  }
}

sub pop {
  my ($self, $key) = @_;
  if (defined $self->($key)) {
    no strict 'refs';
    CORE::pop @{$self->($key)};
  }
}

sub shift {
  my ($self, $key) = @_;
  if (defined $self->($key)) {
    no strict 'refs';
    CORE::shift @{$self->($key)};
  }
}

sub array {
  my ($self, $key) = @_;
  if (defined $self->($key)) {
    if (ref $self->($key) eq 'ARRAY') {
      return @{$self->($key)};
    } else {
      return $self->($key);
    }
  }
  ();
}

sub set {
  my ($p, %p) = @_;
  $p->push($_, $p{$_}) for keys %p;
}

1
