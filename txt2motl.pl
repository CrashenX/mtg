#!/user/bin/perl
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

    if($fields[1] =~ m/MAIN|SIDE/) {
        print '[b]' . $fields[7] . '[/b]';
    }
    elsif($card =~ m/FOIL/) {
        print '[FOIL]' . $fields[7] . '[/FOIL]';
    }
    else {
        print $fields[7];
    }

    print "\n";
}
