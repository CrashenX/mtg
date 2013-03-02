#!/user/bin/perl -w
use strict;
use warnings FATAL => 'all';
use File::Slurp;

sub sort_func()
{
    my @fields1 = split(/\|/,$a);
    my @fields2 = split(/\|/,$b);
    return $fields1[7] cmp $fields2[7];
}

my @cards = read_file('jesse.cards');
@cards = sort sort_func  @cards;

for my $card (@cards) {
    my @fields = split(/\|/,$card);
    my $num_wanted = $fields[5] - $fields[4];

    next if(0 == $num_wanted);

    chomp($fields[7]);

    print "$num_wanted"."x ";

    if($num_wanted > 0 && $fields[1] =~ m/MAIN/) {
        print '[big][b]' . $fields[7] . '[/b][/big] ' . $fields[6];
    }
    elsif($num_wanted > 0 && $fields[1] =~ m/SIDE/) {
        print '[b]' . $fields[7] . '[/b] ' . $fields[6];
    }
    elsif($num_wanted > 0 && $fields[1] =~ m/CUBE/) {
        print '[small]' . $fields[7] . '[/small] ' . $fields[6];
    }
    elsif($card =~ m/FOIL/) {
        print '[FOIL]' . $fields[7] . '[/FOIL] ' . $fields[6];
    }
    else {
        print $fields[7] . ' ' . $fields[6];
    }

    print "\n";
}
