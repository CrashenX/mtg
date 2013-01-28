#!/user/bin/perl
use strict;
use warnings FATAL => 'all';
use File::Slurp;

sub sort_func()
{
    my @fields1 = split(/\|/,$a);
    my @fields2 = split(/\|/,$b);
    return $fields1[6] cmp $fields2[6];
}

my @cards = read_file('jesse.cards');
@cards = sort sort_func  @cards;

for my $card (@cards) {
    my @fields = split(/\|/,$card);

    next if(0 == $fields[4] || 'C' eq $fields[2]);

    chomp($fields[6]);

    print "$fields[4]x ";

    if($card =~ m/FOIL/) {
        print '[FOIL]' . $fields[6]. '[/FOIL]';
    }
    else {
        print $fields[6];
    }

    if($card =~ m/DECK/) {
        print ' [b](in deck)[/b]'
    }
    if($card =~ m/SIDE/) {
        print ' [b](in sideboard)[/b]'
    }

    print "\n";
}
