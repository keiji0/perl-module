package Format::HTML;

# use strict;
# use warnings;
use utf8;
use base qw(Exporter);
use vars qw{$VERSION @ISA @EXPORT %EXPORT_TAGS};
@EXPORT = qw(
  escape div span img must note aux message emessage hidden
  checkbox css_code javascript_code javascript_src radio select
  trim zebra opacity tobr button meta_data
);

sub escape {
  my $s = shift || return undef;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/>/&gt;/g;
  $s =~ s/\"/&quot;/g;
  $s =~ s/\'/&#39;/g;
  $s;
}

sub template {
  use Util::Fun qw(farray);
  my (%o) = @_;
  $o{charset} ||= 'utf-8';
  '<?xml version="1.0" encoding="'.$o{charset}.'"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset='.$o{charset}.'" />
    <meta http-equiv="Content-Script-Type" content="text/javascript" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <title>'.escape($o{title}).'</title>'."\n".
    ($o{keywords} ? '    <meta name="keywords" content="'.escape($o{keywords}).'" />'."\n":'').
    ($o{description} ? '    <meta name="description" content="'.escape($o{description}).'" />'."\n":'').
    ($o{next} ? '    <link rel="next" href="'.escape($o{next}).'" />'."\n":'').
    ($o{prev} ? '    <link rel="prev" href="'.escape($o{prev}).'" />'."\n":'').
    (join "", map{ '    <link rel="stylesheet" href="'.$_.'" type="text/css" />'."\n" } reverse farray($o{css_src})).
    (join "\n", map{ '    '.css_code($_)."\n" } reverse farray($o{css_code})).
    (join "\n", map{ '    <script src="'.$_.'" type="text/javascript"></script>' } farray($o{javascript})).
    (join "\n", map{ '    '.javascript_code($_)."\n" } reverse farray($o{javascript_code})).
    (join "\n", map{ '    '.$_."\n" } farray($o{head})).
'  </head>
  <body'.(defined $o{class} ? ' class="'.$o{class}.'"' : '').($o{onload} ? ' onload="'.$o{onload}.'"' : '').'>
'.$o{body}.'
  </body>
</html>';
}

sub mtemplate {
  my (%o) = @_;
<<END
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=sjis">
    <title>@{[ $o{title} ]}</title>
  </head>
  <body@{[ defined $o{bodyattr} ? ' '.$o{bodyattr} : '' ]}>
    @{[ $o{body} ]}
  </body>
</html>
END
}

sub span { '<span class="'.$_[0].'">'.$_[1].'</span>' }
sub img { '<img src="'.$_[0].'" alt="'.$_[1].'" />' }
sub must() {' <span class="must">※</span> '}
sub aux { span('aux', shift) }
sub message { div('message',shift) }
sub emessage { div('emessage',shift) }

sub hidden {
  my (%x) = @_;
  '<div class="hidden">'.join('', map{'<input type="hidden" name="'.$_.'" value="'.escape($x{$_}).'"'.' />'."\n"}keys(%x)).'</div>'
}

sub checkbox {
  my ($n, $v, $c, $l) = @_;
  '<input type="checkbox" name="'.$n.'" id="'.$n.$v.'" value="'.$v.'"'.($c ? 'checked="checked"' : '').' />'.($l && '<label for="'.$n.$v.'">'.$l.'</label>');
}

sub css_code {
  '<style type="text/css">
'.(shift).'
</style>'
}

sub javascript_code {
  '<script type="text/javascript">
//<![CDATA[
'.(shift).'
//]]>
</script>'
}

sub javascript_src {
  '<script type="text/javascript" language="javascript" src="'.(shift).'"></script>'
}

sub radio {
  # $nはパラメータ名, $vはパラメータ
  my ($n, $v, @s) = @_;
  my $x = ''; my $i = 0;
  for (@s) {
    $x .= '<input type="radio" name="'.$n.'" value="'.$_->{value}.'" id="_'.$n.$i.'"'.($v eq $_->{value} && ' checked="checked"').' />'.
      ' <label for="_'.$n.$i.'">'.$_->{label}.'</label> ';
    $i++;
  }
  $x;
}

sub select {
  # $v: 入力データ, 一致するとselected属性を付ける
  # $n: 名前, name属性に入れる
  # $a: その他の属性
  my ($v, $n, $a, @kv) = @_;
  my $x = '';
  for (@kv) {
    $x .= '<option value="'.$_->[1].'"'.' '.($v eq $_->[1] ? ' selected="selected"' : '').'>'.$_->[0].'</option>';
  }
  '<select name="'.$n.'" id="'.$n.'"'.($a && ' '.$a).'>'.$x.'</select>';
}

sub tobr {
  my $b = br;
  $_[0] =~ s/\n/$b/g;
  $_[0];
}

{
  my $c = 0;
  sub zebra {
    ($c = not $c) ? '' : ' zebra';
  }
}

{
  my @m = map{[$_,$_]}('',1..12);
  my @d = map{[$_,$_]}('',1..31);
  sub date_select {
    my ($n, $md, $dd) = @_;
    Format::HTML::select($md, $n.'_month', '', @m).' 月'.
    Format::HTML::select($dd, $n.'_day', '', @d).' 日';
  }
}

sub list {
  # $typeにolかulを入れる
  # 属性は$typeに一つ空白入れ、その後の文字列が属性になる
  my ($type, @items) = @_;
  my ($elem, $attr);
  $_ = $type;
  if (m|^([^ ]+)(.*)|) {
    $elem = $1;
    $attr = $2;
  } else {
    $elem = $type;
    $attr = ''
  }
  my $r = '';
  $r .= '<'.$elem.$attr.'>';
  $_ and $r .= '<li class="'.zebra.'">'.$_.'</li>' for @items;
  $r .= '</'.$elem.'>';
  $r;
}

sub trim {
  my $x = shift;
  my $d;
  for (split /\r|\n/, $x) {
    s/^ +//g;
    s/ +$//g;
    $d .= $_;
  }
  $d
}

sub dl {
  my $r;
  my $status = 0;
  my $attr = '';
  if ($_[0] =~ '^\w+=') {
    $attr = ' '.shift(@_);
  }
  for (@_) {
    $r .= ($status = !$status) ?
      '<tr><th>'.$_.'</th>' :
      '<td>'.$_.'</td></tr>';
  }
  '<table'.$attr.'>'.$r.'</table>';
}

sub opacity {
  my $num = shift;
  'filter:alpha(opacity='.$num.'); /*IE*/
-moz-opacity:'.($num == 1 ? 1 : '0.'.$num).'; /*FF*/
opacity:'.($num == 1 ? 1 : '0.'.$num)
}

sub tobr {
  $_ = shift;
  s|\n|\<br /\>|g;
  $_;
}

sub button {
  my (%o) = @_;
  '<button onclick="'.$o{onclick}.'; return false;">'.$o{label}.'</button>';
}

sub meta_data {
  my ($name, $val) = @_;
  '<span class="'.$name.' meta">'.escape($val).'</span>'
}

sub center {
  '<div class="center-wrap"><div class="center">'.(shift).'</div></div>'
}

1
