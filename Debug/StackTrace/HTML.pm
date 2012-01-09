package Debug::StackTrace::HTML;

use strict;
use warnings;
use Format::HTML;
use Data::Dumper;

our $mime_type = 'text/html; charset=utf-8;';
our $css_code =  '
* {	margin: 0; padding: 0; }
table { border-collapse: collapse;border-spacing: 0; }
address,caption, cite, code, dfn, h1, h2, h3, h4, th, var {	font-style: normal;	font-weight: normal; }
fieldset, img, abbr{ border: 0; }
caption, th { text-align: left; }
q:before, q:after{ content: ""; }
a { text-decoration: none; }
img { border: none;	vertical-align: bottom; }
html { overflow-y: scroll; }
body, x:-moz-broken { margin-left:-1px; }

body {
  font-size:0.8em;
}
h1 {
  background:#000;
  color:#fff;
  padding:0.3em 0.7em;
}
#body {
  margin:1em;
}
.item {
  margin:1em 0;
}
.head .file {
  color:#0066CC;
}
.src .here {
  color:#f00;
  background:#eee;
}
.src .line {
  color:#999;
  padding-right:0.5em;
  text-align:right;
  width:2em;
}
.dieval {
  margin:1em 0;
  background:#FFFFCC;
  padding:0.5em;
  -moz-border-radius:3px;
}
';

sub format {
  my ($val, $trace) = @_;
  my $title = 'Debug: Perl Stack Trace';

  local $Data::Dumper::Sortkeys = 1;    # ハッシュのキーをソートする
  local $Data::Dumper::Indent = 1;      # インデントを縮める
  local $Data::Dumper::Terse = 1;       # $VAR数字要らない

  Format::HTML::template
    title => $title,
    css_code => $css_code,
    body => '<h1>'.$title.'</h1>'.
      '<div id="body"><pre class="dieval">'.(ref \$val eq 'SCALAR' ? $val : Dumper($val)).'</pre>'.
      '<div class="trace">'.join('', map{
        my $item = $_;
        '<div class="item">'.
          '<div class="head"><span class="file">'.$item->{file}.'</span></div>'.
          '<pre class="src"><table>'.
            join('', map{
              '<tr'.($_->{here} ? ' class="here"' : '').'><td class="line">'.$_->{line}.'</td><td class="code">'.$_->{text}.'</td></tr>'."\n"
            }@{$item->{context}}).
          '</table></pre>'.
        '</div>';
      }@$trace).'</div></div>'

}

1
