package Text::Ngram;

use warnings;
use strict;
#use Encode qw/encode decode is_utf8/;

sub parsehex {
  my ($text, $count) = @_;
  my @a = map { sprintf('%x', unpack('U*', $_)) } @{ parse($text, $count) };
  \@a;
}

sub parse {
	my ($text, $count) = @_;

	#$text = decode('utf8', $text) unless is_utf8($text);
	my @chunks = split /[ ,.":;()\[\]\{\}!\?\-\|　。、・☆ ♪：；\d\n\t\/]+/, $text;
  #die join "\n", @chunks;
	my %ngrams;
	for (@chunks){
		next if $_ eq '';
    if ($_ =~ /^[a-zA-Z0-9]+$/) {
      $ngrams{$_} = 1;
		} else {
			#push @ngrams, _make_ngram_fulltext($_, $count );
      for my $i (0 .. length($_) - 1){
        my $str = substr $_, $i, $count;
        #$str = encode 'utf8', $str;
        $ngrams{$str} = length($str);
      }
		}
	}
  my @a = keys %ngrams;
	return \@a;
}

sub _make_ngram_fulltext {
	my ($text, $count) = @_;
	return if !defined $text;
	my @ngrams;
	for my $i (0 .. length($text) - 1){
		my $str = substr $text, $i, $count;
		#$str = encode 'utf8', $str;
		push @ngrams, $str;
	}
	return join(' ', @ngrams);
}

1
