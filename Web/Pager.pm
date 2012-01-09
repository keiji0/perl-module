package Web::Pager;

use strict;
use warnings;
use utf8;
use base qw(Exporter);
our @EXPORT = qw(pager);

sub pager {
  use CGI::Query qw(queryjoin);
  use Util::Fun qw(merge);

  my ($query, $pageset, %o) = @_;
  my $pagenavi = '';

  my $set = $pageset->pages_in_set();
  $#$set < 1 and return '';
  foreach my $page (@{$pageset->pages_in_set()}) {
    if ($page == $pageset->current_page()) {
      $pagenavi .= "<strong>$page</strong>";
    } else {
      $pagenavi .= "<a href='?" .
        (queryjoin merge({}, $query, { page => $page })) .
      "'>$page</a>";
    }
  }

  if ($pageset->previous_page) {
    $pagenavi = '<a href="?' .
      (queryjoin merge({}, $query, { page => $pageset->previous_page })).
    '">'.($o{prevtext} || '前へ').'</a>'.$pagenavi;
  }
  if ($pageset->next_page) {
    $pagenavi = $pagenavi.'<a href="?' .
      (queryjoin merge({}, $query, { page => $pageset->next_page })).
    '">'.($o{nexttext} || '次へ').'</a>';
  }
  '<div class="pager">'.$pagenavi.'</div>';
}

1
