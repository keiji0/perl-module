package Util::Hook;

=head1 DESCRIPTION

指定の位置に関数を実行する

=head1 METHODS

=item call

指定のフックを実行する。実行順序は配列の先頭から

=item filter

指定のフックを引数をフィルタリングしながら実行していく

=begin testing

use strict;
use warnings;
use lib qw(.);
use Util::Hook;

use_ok 'M::Hook';
require_ok 'M::Hook';

my $hook = new Util::Hook;

my $c = '';
$hook->push('inc', sub { $c.='a' });
ok $hook->call('inc') eq 'a', 'callが実行されているか';
$hook->push('inc', sub { $c.='b' });
$c = '';
ok $hook->call('inc') eq 'ab', '実行順番の確認';

$hook->push('arg', sub { my $x = shift; $x+2 });
ok $hook->call('arg', 8) == 10, '引数を受けとる';

$hook->push('[...]', sub { '['.(shift).']' });
$hook->push('[...]', sub { '('.(shift).')' });
ok $hook->filter('[...]', '*') eq '([*])', 'フィルタを実行する';

=end testing
=cut

use strict;
use warnings;
use Carp qw(croak);
use base qw(Util::Param);

sub call {
  my ($self, $key, @param) = @_;
  my $result;
  for my $code ($self->array($key)) {
    ref $code eq 'CODE' ?
      $result = $code->(@param) :
        croak(__PACKAGE__.'::call('.$key.'): ['.$code.'] 関数じゃありません');
  }
  $result;
}

sub filter {
  my ($self, $key, @param) = @_;
  for my $code ($self->array($key)) {
    if (ref $code eq 'CODE') {
      @param = $code->(@param);
    } else {
      croak(__PACKAGE__.'::call('.$key.'): ['.$code.'] 関数じゃありません');
    }
  }
  $param[0]
}

1;
