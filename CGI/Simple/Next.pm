package CGI::Simple::Next;

use utf8;
use encoding "utf8"; binmode(STDOUT, ":utf8");
use strict;
use warnings;
use base qw (CGI::Simple);
use Carp qw (croak);
use URI::Escape;
use Util::Param;
use Util::Fun qw(merge);

sub new {
  my ($class, %args) = @_;
  my $self = new CGI::Simple(%{$args{cgi_args}});
  bless $self, $class;
  $self->{http_header} = new Util::Param;
  merge $self, \%args;
  $self;
}

sub finish {
  my ($self, $value) = @_;
  $self->{finish_value} = $value;
  die $self;
}

sub redirect {
  my ($self, $url) = @_;
  print $self->SUPER::redirect(-uri => $url, -nph => 0);
  exit 0;
}

sub handler {
  my ($self, $fun) = @_;
  $self->{handler} = $fun;
}

sub paramref {
  my ($self) = @_;
  defined $self->{_rawparam} and return $self->{_rawparam};
  my %a;
  $a{$_} = $self->param($_) for $self->param();
  \%a;
}

sub http_header {
  my ($self, $key, $val) = @_;
  $self->{http_header}->($key, $val);
}

sub DEFAULT_TYPE_HEADER() { 'text/html; charset=utf-8' }

sub header_string {
  my ($self) = @_;
  $self->header(%{$self->{http_header}->()});
}

sub docroot () {
  my $a = $ENV{REQUEST_URI};
  if ($ENV{PATH_INFO}) {
    defined $ENV{QUERY_STRING} and $a =~ s@\?$ENV{QUERY_STRING}$@@;
    defined $ENV{PATH_INFO} and $a =~ s@$ENV{PATH_INFO}$@@;
    $a =~ s{([^/])$}{$1/};
    $a;
  } else {
    $a;
  }
}

sub query {
  my ($self, $query) = @_;
  my @q;
  while (my ($key, $val) = each %$query) {
    $val = uri_escape_utf8($val);
    push @q, "${key}=${val}";
  }
  (scalar @q ? '?' . join('&', @q) : '');
}

sub path {
  my ($self, $path, $query) = @_;
  docroot . $path . $self->query($query);
}

sub pwd {
  my $pi = $ENV{PATH_INFO};
  $pi =~ s|^/||;
  docroot . $pi  . ($ENV{QUERY_STRING} ? '?' . $ENV{QUERY_STRING} : '')
}

sub url {
  my ($self, $path, $query) = @_;
  join '',
    ('http://'.$ENV{HTTP_HOST},
     #($ENV{SERVER_PORT} eq 80 ? '' : ':'.$ENV{SERVER_PORT}),
     $self->path($path, $query));
}

sub display {
  my ($self, $contents) = @_;
  # HTTPヘッダーを設定
  $self->http_header(-type) or $self->http_header(-type => DEFAULT_TYPE_HEADER);
  # コンテンツを出力
  print $self->header_string();
  print $contents;
}

sub throw {
  my ($self, $val) = @_;
  $self->{throw_val} = $val;
  die $self;
}

sub run {
  my ($self, %o) = @_;
  my $result;
  $self->{throw_val} = 0;
  eval {
    $result = $o{body}->();
  };
  my $throw_value = $@;
  if (ref $throw_value eq __PACKAGE__) {
    if (defined $self->{finish_value}) {
      print $self->{finish_value};
      return;
    } elsif ($self->{throw_val} and $self->{handler}) {
      $self->display($self->{handler}->($self->{throw_val}));
      return;
    } else {
      die $throw_value;
    }
  } elsif ($throw_value) {
    die $@;
  }
  $self->display($result);
}

1
