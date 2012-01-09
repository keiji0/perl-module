use DBI;

package DBI;

use strict;
use warnings;
use Util::Check;

sub make_where {
  my ($and_or, @where) = @_;
  my $x = join(' '.$and_or.' ', grep(/.+/, @where));
  $x eq '' ? '' : ' WHERE '.$x;
}

sub make_limit {
  my (%o) = @_;
  my $sql = '';
  if (Util::Check::number($o{limit})) {
    my $limit = $o{limit};
    $sql .= ' LIMIT '.($limit);
    if (Util::Check::number($o{page}) and $o{page} > 0) {
      $sql .= ' OFFSET '.($o{page} * $limit);
    } elsif (Util::Check::number($o{offset}) and $o{offset} > 0) {
      $sql .= ' OFFSET '.$o{offset};
    }
  }
  $sql;
}

sub select_page_gen {
  my ($db, $param) = @_;
  $param->{page} ||= 0;
  $param->{rows} ||= 10;
  my $sql = ' LIMIT '.$db->escape($param->{rows}+1).' OFFSET '.$db->escape(($param->{page}-1)*$param->{rows});
}

# sub prepare_exec {
#   my ($db, $sql, %o) = @_;
#   $o{args} =|| [];
  
#   my $sth;
#   $sth = $db->prepare($sql) or die "prepare できません: ".$db->errstr();
#   $sth->execute(@{$o{args}}) or die "exec できません: ".$db->errstr;

#   if ($o{catch}) {
#     my $result;
#     eval { $result = $fun->($sth); };
#     my $emessage = $@;
#     $sth->finish();
#     undef $sth;
#     $emessage and die $emessage;
#     $result;
#   }
# }

sub prepare_exec {
  my ($db, $sql, $args) = @_;
  prepare_select($db, $sql, $args, sub{});
}

sub select_value_exec {
  my ($db, $sql, $args) = @_;
  prepare_select($db, $sql, $args, sub { shift->fetchrow_hashref; });
}

sub select_map {
  my ($db, $sql, $param, $fun) = @_;
  prepare_select($db, $sql, $param, sub {
                   my $c = shift;
                   my @r;
                   push @r, $_ while $_ = $fun->($c);
                   \@r
                 });
}

# sub select_page {
#   my ($db, $sql, $paging, $args) = @_;
#   #$paging->{page} ||= 0;
#   $paging->{rows} ||= 100;
#   $sql .= ' LIMIT '.($paging->{rows}+1).' OFFSET '.(($paging->{page})*$paging->{rows});
#   my $sth = $db->prepare($sql) or die $db->errstr;
#   $sth->execute(@$args);

#   my @res;
#   if (my $fun = $paging->{fun}) {
#     while (my $row = $sth->fetchrow_hashref) {
#       push @res, $fun->($row);
#     }
#   } else {
#     while (my $row = $sth->fetchrow_hashref) {
#       push @res, $row;
#     }
#   }
#   $sth->finish;
#   undef $sth;

#   my $has_next = 0;
#   if (@res == $paging->{rows} + 1) {
#     pop @res;
#     $has_next++;
#   }
#   return (\@res, {page => $paging->{page}, has_next => $has_next, has_prev => ($paging->{page} > 1) ? 1 : 0})
# }

1
