package DBI::OR;

=head1 使い方

# パッケージ名がテーブル名になる
package Foo;

# DBI::ORクラスを継承する
use base qw(DBI::OR);

# スキーマの定義
sub schema {
  my ($self) = @_;
'CREATE TABLE '.$self->table_name.' (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  created TEXT NOT NULL
)'
}

package main;

# オブジェクトの生成はnewで生成する
new Foo($db, {name => 'hoge'})
# オブジェクトをDBに書込みする
  ->commit($db);

=cut

use strict;
use warnings;
use utf8;
use DBI;
use Carp;
use Util::Fun qw(select_hash);

our %tables;

my $cc = 0;
sub _once_table_init {
  my ($self, $db) = @_;
  my $class_name = ref(\$self) eq 'SCALAR' ? $self : ref $self;
  unless (defined $tables{$class_name}) {
    my $table_name = $class_name;
    $table_name =~ s|^.+::||;
    $tables{$class_name} = {
      table_name => $table_name,
    };
    # テーブル名を設定する
    eval '{ package '.$class_name.'; sub table_name(){"'.$table_name.'"} }';
    # テーブルを定義する
    my $first_p = _create_table($db, $table_name, $self->schema);
    # カラムリストを生成する
    eval '{
      package '.$class_name.';
      my @columns = qw/'.join(' ', _columns($db, $table_name)).'/;
      sub columns(){\@columns}
    }';
    { # プライマリーキーをクラスモジュールに設定する
      my $sth = $db->primary_key_info(undef, undef, $table_name);
      if (my $key_name = $sth->fetchrow_arrayref->[3]) {
        eval '{
          package '.$class_name.';
          my $primary_key_name = "'.$key_name.'";
          sub primary_key { $primary_key_name }
      }';
      } else {
        die 'primary_keyが設定されていません - '.$table_name;
      }
    }
    $first_p and $self->create_table_after($db);
  }
}

sub new {
  my ($class, $db, $param, @options) = @_;
  my $self = bless $param, $class;
  _once_table_init $self, $db;
  $self->init($db, @options);
  $self;
}

sub isdb {
  my ($self) = @_;
  my $kn = $self->primary_key();
  $self->{$kn}
}

sub init { }
# テーブルが作成された後に実行
sub create_table_after { }
# commitするまえに実行される
sub check { }
sub table_name { die 'テーブルが定義されていません' }
sub columns { die 'カラムが定義されていません' }

sub raw_find {
  # キーからオブジェクトを探す
  my ($class, $db, $key, %param) = @_;
  _once_table_init($class, $db);
  $param{key} ||= $class->primary_key;
  my $sql = 'SELECT * FROM '.$class->table_name.' WHERE '.$param{key}.'=?'.(defined $param{sql} ? ' '.$param{sql} : '');
  prepare_select($db, $sql, [$key, @{$param{args}||[]}], sub {
    my $hash = shift->fetchrow_hashref();
    return $hash && $class->new($db, $hash);
  });
}

sub find {
  # %paramを受け取ってオブジェクトを返す
  my ($self, $db, %param) = @_;
  $self->raw_find($db, undef, %param);
}

sub exist {
  # オブジェクトが存在するか確認する
  # findでも確認出来るが新たにオブジェクトを獲得されるので、
  # 確認だけの場合はこの関数を使う
  my ($class, $db) = @_;
}

sub commit {
  # オブジェクトが既に存在している場合はupdateを使う
  # もしまだ存在していなければinsertを使って新たにデータベースに書き込む
  my ($self, $db) = @_;
  # オブジェクトの値が正しいかチェックする
  $self->check($db);
  no strict "refs";
  #if (((ref $self).'::find')->($db, $self)) {
  if ($self->isdb) {
    $self->update($db, $self);
  } else {
    insert($self, $db, $self);
    # 新規に作成した場合にはIDを設定する
    my $pk = $self->primary_key;
    $self->{$pk} = $self->last_insert_id($db);
  }
  $self;
}

sub last_insert_id {
  my ($self, $db) = @_;
  $db->last_insert_id(undef, undef, $self->table_name, $self->primary_key);
}

sub delete {
  # オブジェクトを削除する
  my ($self, $db) = @_;
  my $primary_key_name = $self->primary_key;
  my $sql = 'DELETE FROM '.$self->table_name.' WHERE '.$primary_key_name.'=?';
  prepare_exec($db, $sql, [$self->{$primary_key_name}]);
}

my @date_column_name = qw/created modified/;

{
#   use DateTime;
#   use DateTime::TimeZone;
#   my $tz = DateTime::TimeZone->new(name => 'local');
#   sub now {
#     my $dt = DateTime->now(time_zone => $tz);
#     $dt->ymd('-').' '.$dt->hms(':');
#   }
  sub now {
    time;
  }
}

sub filed_format {
  # データベースに書き込む前に値を変換する
  my ($class, $key, $val) = @_;
  $val;
}

sub insert {
  my ($class, $db, $param) = @_;
  $param->{created} ||= now;
  $param->{modified} ||= now;
  _once_table_init $class, $db;
  $param = select_hash($class->columns, $param);
  my @keys = keys(%{$param});
  my @vals;
  my $sql = 'INSERT INTO '.$class->table_name.'(`'.join('`,`', @keys).'`) VALUES('.join(', ', map{'?'}@keys).')';
  push @vals, $class->filed_format($_, $param->{$_}) for @keys;
  prepare_exec($db, $sql, \@vals);
}

sub update {
  my ($self, $db, $param) = @_;
  $self->{$_} = $param->{$_} for keys %{$param};
  my $primary_key_name = $self->primary_key;
  $self->{modified} = $param->{modified} = now;
  if (my $primary_key = $self->{$primary_key_name}) {
    $param = select_hash($self->columns, $param);
    my @keys = keys(%{$param});
    my $sql = 'UPDATE '.$self->table_name.' SET '.join(', ', map{'`'.$_.'`=?'}@keys).' WHERE '.$primary_key_name.'=?';
    my @vals; push @vals, $self->filed_format($_, $param->{$_}) for (@keys);
    push @vals, $primary_key;
    prepare_exec($db, $sql, \@vals);
  }
}

sub count {
  my ($class, $db, %param) = @_;
  _once_table_init $class, $db;
  my $sql = "SELECT COUNT(*) FROM ".$class->table_name.(defined $param{where} ? $param{where} : '');
  prepare_select($db, $sql, $param{args}, sub { shift->fetchrow_array });
}

sub prepare_select {
  my ($db, $sql, $args, $fun) = @_;
  my $sth;
  $sth = $db->prepare($sql) or die "prepare できません: ".$db->errstr();
  $sth->execute(@{$args}) or die "exec できません: ".$db->errstr;
  
  my $result;
  eval { $result = $fun->($sth); };
  my $emessage = $@;
  $sth->finish();
  undef $sth;
  if ($emessage) { die $emessage }
  $result;
}

sub prepare_exec {
  my ($db, $sql, $args) = @_;
  prepare_select($db, $sql, $args, sub{});
}

sub _create_table {
  my ($db, $table, @sqls) = @_;
  my $r = $db->tables(undef, undef, $table);
  unless ($r) {
    for my $sql (@sqls) {
      $db->do($sql) or die $db->errstr.' '.$sql
    }
  }
  not $r;
}

sub _columns {
  my ($db, $table) = @_;
  my $sth = $db->column_info(undef, undef, $table, '%');
  my @columns;
  for my $a (@{$sth->fetchall_arrayref}) {
    push @columns, $a->[3];
  }
  @columns;
}

1;
