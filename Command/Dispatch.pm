package Command::Dispatch;

use strict;
use warnings;
use Util::Hook;
use Util::Param;

my $hook = new Util::Hook;
sub hook() { $hook }
hook->(display => sub { print $_[0] || '' });

sub split_path {
  my $path_info = shift || $ARGV[0] || $ENV{PATH_INFO} || '/';
  my @path = grep(!/^\.\.$/, split(m|/|, $path_info));
  shift @path;
  \@path;
}

sub new {
  my ($class, %param) = @_;
  my $self = bless \%param, $class;
  $self->{path} = split_path;
  $self->{application_name} ||= 'contents';
  $hook->call(init => $self);
  $self;
}

sub run {
  shift->dispatch;
}

sub dispatch {
  my $self = shift;
  my $content;
  my $application_name = $self->{application_name};
  # 上から順に辿っていく
  # /hoge/foo だと hoge.pm 読み込み foo.pmを読み込み
  my @last_path; {
    my @down_path;
    for my $element ($application_name, @{$self->{path}}) {
      push @down_path, $element;
      if (-r (my $file = join('/', @down_path).'.pm')) {
        @last_path = @down_path;
        require $file;
      }}}
  # コンテンツを生成する前にフックを実行
  hook->call('dispatch_before', $self);
  # 末端モジュールのmain関数を実行
  {
    no strict 'refs';
    $content = join('::', @last_path, 'main')->($self->{path}, $self);
  }
  # 上位モジュールのwrapを適用していく
  do {
    if (my $module = join('::', @last_path)) {
      my $wrap = \&{$module.'::wrap'};
      $content = defined &{$wrap} ?
        $wrap->($content, $self) :
          $content;
    }
  } while (pop @last_path);
  $content;
}

1
