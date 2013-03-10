#!/user/bin/perl -w
use strict;
use warnings FATAL => 'all';
use File::Slurp;

sub sort_func()
{
    my @fields1 = split(/\|/,$a);
    my @fields2 = split(/\|/,$b);
    return $fields1[8] cmp $fields2[8];
}

my @cards = read_file('jesse.cards');
@cards = sort sort_func  @cards;

for my $card (@cards) {
    my @fields = split(/\|/,$card);
    my $num_wanted = $fields[5] - $fields[4] - $fields[6];
    my $card_name = $fields[8];
    my $use = $fields[1];
    my $set = $fields[7];
    chomp($card_name);

    next if(0 == $num_wanted);

    if($num_wanted > 0 && $use =~ m/MAIN/) {
        $card_name = '[big][b]' . $card_name . '[/b][/big]';
    }
    elsif($num_wanted > 0 && $use =~ m/SIDE/) {
        $card_name = '[b]' . $card_name . '[/b]';
    }
    elsif($num_wanted > 0 && $use =~ m/CUBE/) {
        $card_name = '[small]' . $card_name . '[/small]';
    }
    elsif($card =~ m/FOIL/) {
        $card_name = '[FOIL]' . $card_name . '[/FOIL]';
    }

    print "$num_wanted"."x $card_name";
    print " ($set)" unless($set =~ /^\s\s*$/);
    print "\n";
}
