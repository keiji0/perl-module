package CGI::Simple::Next::Session;

=head1

CGI::Simple::Nextにセッション機能を組込むモジュール、

=head1 使い方

use CGI::Simple::Next::Session;

# オブジェクト生成時にパラメーターを与える
new CGI::Simple::Next session_args => {
  type => 'driver:File',
  Directory => 'data/session'
};

=cut

{
  package CGI::Simple::Next;
  
  use CGI::Session;
  
  sub SESSION_ID_NAME() { 'SID' }

  sub session {
    my ($self, $key, $val) = @_;
    $self->session_init;
    defined $val ?
      $self->{session}->param($key, $val) && $val :
      $self->{session}->param($key);
  }

  sub session_init {
    my $self = shift;
    if (my $args = $self->{session_args} and
               not $self->{session}) {
      my $sid = $self->cookie(SESSION_ID_NAME) || $self->param(SESSION_ID_NAME) || undef;
      $sid or $self->{session_first} = 1; # セッションが始めて発行されるなら{session_first}を設定
      $self->{session} = new CGI::Session(
        $args->{type},
        $sid,
        $args
      );
      # セッションヘッダーを設定
      $self->session_header_set;
    }
  }

  sub session_header_set {
    my $self = shift;
    if ($self->{session}) {
      $self->{http_header}->(
        -cookie => $self->cookie(
          -name => SESSION_ID_NAME,
          -value => $self->{session}->id
        )
      );
    }
  }

  sub session_delete {
    # セッションを片づける、ついでにクッキーも削除
    my $self = shift;
    $self->{session} and $self->{session}->delete();
    $self->{http_header}->(
      -cookie => $self->cookie(
        -name => SESSION_ID_NAME,
        -value => '',
        -expires => 'Thu, 01-Jan-1970 00:00:00 GMT'
      ));
    $self->{session} = undef;
  }
}

 1
