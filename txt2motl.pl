#!/user/bin/perl -w
use strict;
use warnings FATAL => 'all';
use Getopt::Long;
use File::Slurp;

my $FIRST_WANTS  = 'Primary';
my $SECOND_WANTS = 'Secondary';
my $THIRD_WANTS  = 'Tertiary';
my $FOURTH_WANTS = 'Cube';

GetOptions("h|have" => \(my $print_have)
          ,"w|want" => \(my $print_want)
          );

my %wants_sort_order = ( $FIRST_WANTS   => 0
                       , $SECOND_WANTS  => 1
                       , $THIRD_WANTS   => 2
                       , $FOURTH_WANTS  => 3
                       );

sub card_sort()
{
    my @fields1 = split(/\|/,$a);
    my @fields2 = split(/\|/,$b);
    return $fields1[8] cmp $fields2[8];
}

sub want_sort()
{
    my $x = $wants_sort_order{$a};
    my $y = $wants_sort_order{$b};
    return $x cmp $y;
}

sub motl_format_card()
{
    my $quantity = shift;
    my $name = shift;
    my $foil = shift;
    if(1 == $foil) {
        sprintf("%02d [FOIL]%s[/FOIL]", abs($quantity), $name);
    }
    else {
        sprintf("%02d %s", abs($quantity), $name);
    }
}

sub motl_print_have()
{
    my $list = shift;
    foreach(sort(keys $list->{'have'})) {
        print '[u]' . $_ . '[/u]' . "\n";
        foreach(@{$list->{'have'}->{$_}}) {
            print "$_\n";
        }
        print "\n";
    }
}

sub motl_print_want()
{
    my $list = shift;
    foreach(sort want_sort (keys $list->{'want'})) {
        print '[u]' . $_ . ' Wants[/u]' . "\n";
        foreach(@{$list->{'want'}->{$_}}) {
            print "$_\n";
        }
        print "\n";
    }
}

my %trade_list = ( 'have' => {}
                 , 'want' => { $FIRST_WANTS   => []
                             , $SECOND_WANTS  => []
                             , $THIRD_WANTS   => []
                             , $FOURTH_WANTS  => []
                             }
                 );

my @cards = read_file('jesse.cards');
@cards = sort card_sort @cards;

for my $card (@cards) {
    my @fields = split(/\|/,$card);
    my $use = $fields[1];
    my $have = $fields[4];
    my $foil = $fields[3] =~ m/FOIL/ ? 1 : 0;
    my $want = $fields[5];
    my $incoming = $fields[6];
    my $set = $fields[7];
    my $card_name = $fields[8];
    chomp($card_name);

    my $num_wanted = $want - $have - $incoming;

    next if(0 == $num_wanted);

    if(0 < $num_wanted) {
        my $u = $THIRD_WANTS;
        if('MAIN' eq $use) {
            $u = $FIRST_WANTS;
        }
        elsif('SIDE' eq $use) {
            $u = $SECOND_WANTS;
        }
        elsif('CUBE' eq $use) {
            $u = $FOURTH_WANTS;
        }
        push( @{$trade_list{'want'}->{$u}}
            , &motl_format_card($num_wanted, $card_name, $foil) . " ($set)"
            );
    }
    else {
        push( @{$trade_list{'have'}->{$set}}
            , &motl_format_card($num_wanted, $card_name, $foil)
            );
    }

    #if($num_wanted > 0 && $use =~ m/MAIN/) {
    #    $card_name = '[big][b]' . $card_name . '[/b][/big]';
    #}
    #elsif($num_wanted > 0 && $use =~ m/SIDE/) {
    #    $card_name = '[b]' . $card_name . '[/b]';
    #}
    #elsif($num_wanted > 0 && $use =~ m/CUBE/) {
    #    $card_name = '[small]' . $card_name . '[/small]';
    #}
    #elsif($card =~ m/FOIL/) {
    #    $card_name = '[FOIL]' . $card_name . '[/FOIL]';
    #}

    #print "$num_wanted"."x $card_name";
    #print " ($set)" unless($set =~ /^\s\s*$/);
    #print "\n";
    #foreach( @{$trade_list{'want'}} ) {
    #    print "$_\n";
    #}
}

if(!$print_have && !$print_want) {
    print "Specify '-h|--have' to print haves, '-w|--want' to print wants\n";
}
&motl_print_have(\%trade_list) if $print_have;
&motl_print_want(\%trade_list) if $print_want;
