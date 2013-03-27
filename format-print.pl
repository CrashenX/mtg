#!/user/bin/perl -w
use strict;
use warnings FATAL => 'all';
use Switch;
use Getopt::Long;
use File::Slurp;

my $FIRST_WANTS  = 'Primary';
my $SECOND_WANTS = 'Secondary';
my $THIRD_WANTS  = 'Tertiary';
my $FOURTH_WANTS = 'Cube';

GetOptions("h|have" => \(my $print_have)
          ,"w|want" => \(my $print_want)
          ,"m|motl" => \(my $format_motl)
          ,"d|dbox" => \(my $format_dbox)
          ,"p|puca" => \(my $format_puca)
          );

my %wants_sort_order = ( $FIRST_WANTS   => 0
                       , $SECOND_WANTS  => 1
                       , $THIRD_WANTS   => 2
                       , $FOURTH_WANTS  => 3
                       );

my %sets = ( "LEA" => 'Limited Edition Alpha'
           , "LEB" => 'Limited Edition Beta'
           , "2ED" => 'Unlimited Edition'
           , "3ED" => 'Revised Edition'
           , "4ED" => 'Fourth Edition'
           , "5ED" => 'Fifth Edition'
           , "6ED" => 'Classic (Sixth Edition)'
           , "7ED" => 'Seventh Edition'
           , "8ED" => 'Eighth Edition'
           , "9ED" => 'Ninth Edition'
           , "10E" => 'Tenth Edition'
           , "M10" => 'Magic 2010'
           , "M11" => 'Magic 2011'
           , "M12" => 'Magic 2012'
           , "M13" => 'Magic 2013'
           , "ARN" => 'Arabian Nights'
           , "ATQ" => 'Antiquities'
           , "LEG" => 'Legends'
           , "DRK" => 'The Dark'
           , "FEM" => 'Fallen Empires'
           , "HML" => 'Homelands'
           , "ICE" => 'Ice Age'
           , "ALL" => 'Alliances'
           , "CSP" => 'Coldsnap'
           , "MIR" => 'Mirage'
           , "VIS" => 'Visions'
           , "WTH" => 'Weatherlight'
           , "TMP" => 'Tempest'
           , "STH" => 'Stronghold'
           , "EXO" => 'Exodus'
           , "USG" => 'Urza\'s Saga'
           , "ULG" => 'Urza\'s Legacy'
           , "UDS" => 'Urza\'s Destiny'
           , "MMQ" => 'Mercadian Masques'
           , "NMS" => 'Nemesis'
           , "PCY" => 'Prophecy'
           , "INV" => 'Invasion'
           , "PLS" => 'Planeshift'
           , "APC" => 'Apocalypse'
           , "ODY" => 'Odyssey'
           , "TOR" => 'Torment'
           , "JUD" => 'Judgment'
           , "ONS" => 'Onslaught'
           , "LGN" => 'Legion'
           , "SCG" => 'Scourge'
           , "MRD" => 'Mirrodin'
           , "DST" => 'Darksteel'
           , "5DN" => 'Fifth Dawn'
           , "CHK" => 'Champions of Kamigawa'
           , "BOK" => 'Betrayers of Kamigawa'
           , "SOK" => 'Saviors of Kamigawa'
           , "RAV" => 'Ravnica: City of Guilds'
           , "GPT" => 'Guildpact'
           , "DIS" => 'Dissension'
           , "TSP" => 'Time Spiral'
           , "PLC" => 'Planar Chaos'
           , "FUT" => 'Future Sight'
           , "LRW" => 'Lorwyn'
           , "MOR" => 'Morningtide'
           , "SHM" => 'Shadowmoor'
           , "EVE" => 'Eventide'
           , "ALA" => 'Shards of Alara'
           , "CON" => 'Conflux'
           , "ARB" => 'Alara Reborn'
           , "ZEN" => 'Zendikar'
           , "WWK" => 'Worldwake'
           , "ROE" => 'Rise of the Eldrazi'
           , "SOM" => 'Scars of Mirrodin'
           , "MBS" => 'Mirrodin Besieged'
           , "NPH" => 'New Phyrexia'
           , "ISD" => 'Innistrad'
           , "DKA" => 'Dark Ascension'
           , "AVR" => 'Avacyn Restored'
           , "RTR" => 'Return to Ravnica'
           , "GTC" => 'Gatecrash'
           , "DGM" => 'Dragon\'s Maze'
           , "CHR" => 'Chronicles'
           , "ATH" => 'Anthologies'
           , "BRB" => 'Battle Royale Box Set'
           , "BTD" => 'Beatdown'
           , "DKM" => 'Deckmasters: Garfield vs. Finkel'
           , "DPA" => 'Duels of the Planeswalkers'
           , "ARC" => 'Archenemy'
           , "MMA" => 'Modern Masters'
           , "EVG" => 'Duel Decks: Elves vs. Goblins'
           , "DD2" => 'Duel Decks: Jace vs. Chandra'
           , "DDC" => 'Duel Decks: Divine vs. Demonic'
           , "DDD" => 'Duel Decks: Garruk vs. Liliana'
           , "DDE" => 'Duel Decks: Phyrexia vs. the Coalition'
           , "DDF" => 'Duel Decks: Elspeth vs. Tezzeret'
           , "DDG" => 'Duel Decks: Knights vs. Dragons'
           , "DDH" => 'Duel Decks: Ajani vs. Nicol Bolas'
           , "DDI" => 'Duel Decks: Venser vs. Koth'
           , "DDJ" => 'Duel Decks: Izzet vs. Golgari'
           , "DDK" => 'Duel Decks: Sorin vs. Tibalt'
           , "DRB" => 'From the Vault: Dragons Wings of a Dragon'
           , "V09" => 'From the Vault: Exiled'
           , "V10" => 'From the Vault: Relics'
           , "V11" => 'From the Vault: Legends'
           , "V12" => 'From the Vault: Realms'
           , "HOP" => 'Planechase'
           , "PC2" => 'Planechase (2012 Edition)'
           , "H09" => 'Premium Deck Series: Slivers'
           , "PD2" => 'Premium Deck Series: Fire and Lightning'
           , "PD3" => 'Premium Deck Series: Graveborn'
           , "CMD" => 'Commander'
           , "CMA" => 'Commander\'s Arsenal'
           , "POR" => 'Portal'
           , "P02" => 'Portal Second Age'
           , "PTK" => 'Portal Three Kingdoms'
           , "S99" => 'Starter 1999'
           , "S00" => 'Starter 2000'
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

sub get_set_name()
{
    my $set_code = shift;
    if(exists $sets{$set_code}) {
        return $sets{$set_code};
    }
    else {
        printf STDERR "Warning: Set code ($set_code) not found.\n";
        return "";
    }
}

sub motl_format_card()
{
    my $quantity = shift;
    my $name     = shift;
    my $rarity   = shift;
    my $foil     = shift;
    my $promo    = shift;
    my $set      = shift;
    my $output   = $name;

    if(1 == $promo) {
        $output = "$output (Promo)";
    }

    switch($rarity) {
        case 'C' { $output = '[small]' . "$output" . '[/small]' }
        case ['M','R'] { $output = '[b]' . "$output" . '[/b]' }
    }

    if(1 == $foil) {
        $output = sprintf("%02d [FOIL]%s[/FOIL]", abs($quantity), $output);
    }
    else {
        $output = sprintf("%02d %s", abs($quantity), $output);
    }

    if(0 < $quantity) {
        $output = sprintf("%s (%s)", $output, $set);
    }

    return $output;
}

sub puca_format_card()
{
    my $quantity = shift;
    my $name     = shift;
    my $rarity   = shift;
    my $foil     = shift;
    my $promo    = shift;
    my $output   = "";

    unless($foil || $promo) {
        $output = sprintf("%02d %s", abs($quantity), $name);
    }

    return $output;
}

sub dbox_format_card()
{
    my $quantity = shift;
    my $name     = shift;
    my $rarity   = shift;
    my $foil     = shift;
    my $promo    = shift;
    my $set      = shift;
    my $output   = sprintf("%d", abs($quantity)); #count
    my $set_name = &get_set_name($set);
    $set_name = "\"$set_name\"" unless("" eq $set_name);

    if(0 > $quantity) {
        $output = sprintf("%s,%d", $output, abs($quantity)); # ,trading
    }

    # ,name,foil,textless,promo,signed,edition,condition,language
    return sprintf( "%s,\"%s\",%s,%s,%s,%s,%s,%s,%s"
                  , $output
                  , $name
                  , $foil ? "foil" : ""
                  , ""
                  , $promo ? "promo" : ""
                  , ""
                  , $set_name
                  , ""
                  , "English"
                  );
}

sub print_have()
{
    if($format_dbox) {
        print "Count,Tradelist Count,Name,Foil,Textless," .
              "Promo,Signed,Edition,Condition,Language\n";
    }
    my $list = shift;
    foreach(sort(keys $list->{'have'})) {
        print '[u]' . &get_set_name($_) . '[/u]' . "\n" if($format_motl);
        foreach(@{$list->{'have'}->{$_}}) {
            print "$_\n";
        }
        print "\n" if($format_motl);
    }
}

sub print_want()
{
    if($format_dbox) {
        print "Count,Name,Foil,Textless," .
              "Promo,Signed,Edition,Condition,Language\n";
    }
    my $list = shift;
    foreach(sort want_sort (keys $list->{'want'})) {
        print '[u]' . $_ . ' Wants[/u]' . "\n" if($format_motl);
        foreach(@{$list->{'want'}->{$_}}) {
            print "$_\n";
        }
        print "\n" if($format_motl);
    }
}

unless($format_motl xor ($format_dbox xor $format_puca)) {
    print "Specify EITHER '-m|--motl', '-d|--dbox', OR '-p|--puca'\n";
    exit 1;
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
    my @fields    = split(/\|/,$card);
    my $use       = $fields[1];
    my $rarity    = $fields[2];
    my $foil      = $fields[3] =~ m/FOIL|PROM/ ? 1 : 0;
    my $promo     = $fields[3] =~ m/PROM/ ? 1 : 0;
    my $have      = $fields[4];
    my $want      = $fields[5];
    my $incoming  = $fields[6];
    my $set       = $fields[7];
    my $card_name = $fields[8];
    chomp($card_name);

    my $num_wanted = $want - $have - $incoming;

    next if(0 == $num_wanted);

    my $c = "";
    if($format_motl) {
        $c = &motl_format_card( $num_wanted
                              , $card_name
                              , $rarity
                              , $foil
                              , $promo
                              , $set
                              );
    }
    elsif($format_dbox) {
        $c = &dbox_format_card( $num_wanted
                              , $card_name
                              , $rarity
                              , $foil
                              , $promo
                              , $set
                              );
    }
    elsif($format_puca) {
        $c = &puca_format_card( $num_wanted
                              , $card_name
                              , $rarity
                              , $foil
                              , $promo
                              );
    }

    next if("" eq $c);

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
        push(@{$trade_list{'want'}->{$u}}  , $c);
    }
    else {
        push(@{$trade_list{'have'}->{$set}}, $c);
    }
}

if(!$print_have && !$print_want) {
    print "Specify '-h|--have' to print haves, '-w|--want' to print wants\n";
}
&print_have(\%trade_list) if $print_have;
&print_want(\%trade_list) if $print_want;

