package Debug::StackTrace;

use strict;
use warnings;

BEGIN {
  sub import {
    my ($class, %o) = @_;
    $SIG{__DIE__} = sub {
      return if $^S;
      my $val = shift;
      my $trace = list();
      my ($mime_type, $body);

      if ($o{format} eq 'html') {
        use Debug::StackTrace::HTML;
        $mime_type = $Debug::StackTrace::HTML::mime_type;
        $body = Debug::StackTrace::HTML::format $val, $trace, %o;
      } else {
        use Debug::StackTrace::Text;
        $mime_type = $Debug::StackTrace::Text::mime_type;
        $body = Debug::StackTrace::Text::format $val, $trace, %o;
      }
      if ($o{type} eq 'cgi') {
        print "Status: 500 Server Error\n";
        print "Content-type: $mime_type;\n";
        print "\n";
      }
      print $body;
      exit 0;
    };
  }
  import();
}

sub list {
  my @trace;
  for (my $i = 1; my ($package, $file, $line) = caller($i); $i++) {
    my $data = {
      index => $i,
      package => $package,
      file => $file,
      line => $line,
      func => undef,
    };
    push @trace, $data;
    $data->{context} = get_context($data->{file}, $data->{line});
    if (my @c = caller($i + 1)) {
      $trace[-1]->{func} = $c[3] if $c[3];
    }
  }
  \@trace;
}

sub get_context {
  # $fileの$linenum付近の情報を返す
  my ($file, $linenum) = @_;
  my @data;
  if (-f $file) {
    my $start = $linenum - 3;
    my $end   = $linenum + 3;
    $start = $start < 1 ? 1 : $start;
    open my $fh, '<:utf8', $file or die "cannot open $file:$!";
    my $cur_line = 0;
    while (my $line = <$fh>) {
      ++$cur_line;
      last if $cur_line > $end;
      next if $cur_line < $start;
      $line =~ s|\t|        |g;
      $line =~ s/\n//;
      push @data, {
        line => $cur_line,
        text => $line,
        here => $cur_line == $linenum
        };
    }
    close $file;
  }
  \@data;
}

sub terminal_format {
  my $context = shift;
  my $r = '';
  for my $item (@{$context}) {
    if ($item->{here}) {
      $r .= sprintf("*%4d: %s%s\n", $item->{line}, $item->{text});
    } else {
      $r .= sprintf("%5d: %s%s\n", $item->{line}, $item->{text});
    }
  }
  $r;
}

1
