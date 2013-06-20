#!/user/bin/perl -w
use strict;
use warnings FATAL => 'all';
use Switch;
use Getopt::Long;
use File::Slurp;

my $HAVES = "cards.db";
my $WANTS = "wants";

my $HNORM = 0;
my $HFOIL = 1;
my $HPRMO = 2;
my $HTEXT = 3;
my $HMCUT = 4;
my $HEXPN = 5;
my $HRARE = 6;
my $HNAME = 7;

my $WNORM = 0;
my $WEXPN = 1;
my $WNAME = 2;

GetOptions("h|have" => \(my $print_have)
          ,"w|want" => \(my $print_want)
          ,"m|motl" => \(my $format_motl)
          ,"d|dbox" => \(my $format_dbox)
          ,"p|puca" => \(my $format_puca)
          );

my %sets = ( "LEA" => { order => 199308,
                        name => 'Limited Edition Alpha'
                      }
           , "LEB" => { order => 199310,
                        name => 'Limited Edition Beta'
                      }
           , "2ED" => { order => 199312,
                        name => 'Unlimited Edition'
                      }
           , "3ED" => { order => 199404,
                        name => 'Revised Edition'
                      }
           , "4ED" => { order => 199504,
                        name => 'Fourth Edition'
                      }
           , "5ED" => { order => 199703,
                        name => 'Fifth Edition'
                      }
           , "6ED" => { order => 199904,
                        name => 'Classic (Sixth Edition)'
                      }
           , "7ED" => { order => 200104,
                        name => 'Seventh Edition'
                      }
           , "8ED" => { order => 200307,
                        name => 'Eighth Edition'
                      }
           , "9ED" => { order => 200507,
                        name => 'Ninth Edition'
                      }
           , "10E" => { order => 200707,
                        name => 'Tenth Edition'
                      }
           , "M10" => { order => 200907,
                        name => 'Magic 2010'
                      }
           , "M11" => { order => 201007,
                        name => 'Magic 2011'
                      }
           , "M12" => { order => 201107,
                        name => 'Magic 2012'
                      }
           , "M13" => { order => 201207,
                        name => 'Magic 2013'
                      }
           , "M14" => { order => 201307,
                        name => 'Magic 2014'
                      }
           , "ARN" => { order => 199312,
                        name => 'Arabian Nights'
                      }
           , "ATQ" => { order => 199403,
                        name => 'Antiquities'
                      }
           , "LEG" => { order => 199406,
                        name => 'Legends'
                      }
           , "DRK" => { order => 199408,
                        name => 'The Dark'
                      }
           , "FEM" => { order => 199411,
                        name => 'Fallen Empires'
                      }
           , "HML" => { order => 199510,
                        name => 'Homelands'
                      }
           , "ICE" => { order => 199506,
                        name => 'Ice Age'
                      }
           , "ALL" => { order => 199606,
                        name => 'Alliances'
                      }
           , "CSP" => { order => 200607,
                        name => 'Coldsnap'
                      }
           , "MIR" => { order => 199610,
                        name => 'Mirage'
                      }
           , "VIS" => { order => 199702,
                        name => 'Visions'
                      }
           , "WTH" => { order => 199706,
                        name => 'Weatherlight'
                      }
           , "TMP" => { order => 199710,
                        name => 'Tempest'
                      }
           , "STH" => { order => 199803,
                        name => 'Stronghold'
                      }
           , "EXO" => { order => 199806,
                        name => 'Exodus'
                      }
           , "USG" => { order => 199810,
                        name => 'Urza\'s Saga'
                      }
           , "ULG" => { order => 199902,
                        name => 'Urza\'s Legacy'
                      }
           , "UDS" => { order => 199906,
                        name => 'Urza\'s Destiny'
                      }
           , "MMQ" => { order => 199910,
                        name => 'Mercadian Masques'
                      }
           , "NMS" => { order => 200002,
                        name => 'Nemesis'
                      }
           , "PCY" => { order => 200006,
                        name => 'Prophecy'
                      }
           , "INV" => { order => 200010,
                        name => 'Invasion'
                      }
           , "PLS" => { order => 200102,
                        name => 'Planeshift'
                      }
           , "APC" => { order => 200106,
                        name => 'Apocalypse'
                      }
           , "ODY" => { order => 200110,
                        name => 'Odyssey'
                      }
           , "TOR" => { order => 200202,
                        name => 'Torment'
                      }
           , "JUD" => { order => 200205,
                        name => 'Judgment'
                      }
           , "ONS" => { order => 200210,
                        name => 'Onslaught'
                      }
           , "LGN" => { order => 200302,
                        name => 'Legions'
                      }
           , "SCG" => { order => 200305,
                        name => 'Scourge'
                      }
           , "MRD" => { order => 200310,
                        name => 'Mirrodin'
                      }
           , "DST" => { order => 200402,
                        name => 'Darksteel'
                      }
           , "5DN" => { order => 200406,
                        name => 'Fifth Dawn'
                      }
           , "CHK" => { order => 200410,
                        name => 'Champions of Kamigawa'
                      }
           , "BOK" => { order => 200502,
                        name => 'Betrayers of Kamigawa'
                      }
           , "SOK" => { order => 200506,
                        name => 'Saviors of Kamigawa'
                      }
           , "RAV" => { order => 200510,
                        name => 'Ravnica: City of Guilds'
                      }
           , "GPT" => { order => 200602,
                        name => 'Guildpact'
                      }
           , "DIS" => { order => 200605,
                        name => 'Dissension'
                      }
           , "TSB" => { order => 200610,
                        name => 'Time Spiral'
                      }
           , "TSP" => { order => 200610,
                        name => 'Time Spiral'
                      }
           , "PLC" => { order => 200702,
                        name => 'Planar Chaos'
                      }
           , "FUT" => { order => 200705,
                        name => 'Future Sight'
                      }
           , "LRW" => { order => 200710,
                        name => 'Lorwyn'
                      }
           , "MOR" => { order => 200802,
                        name => 'Morningtide'
                      }
           , "SHM" => { order => 200805,
                        name => 'Shadowmoor'
                      }
           , "EVE" => { order => 200807,
                        name => 'Eventide'
                      }
           , "ALA" => { order => 200810,
                        name => 'Shards of Alara'
                      }
           , "CON" => { order => 200902,
                        name => 'Conflux'
                      }
           , "ARB" => { order => 200904,
                        name => 'Alara Reborn'
                      }
           , "ZEN" => { order => 200910,
                        name => 'Zendikar'
                      }
           , "WWK" => { order => 201002,
                        name => 'Worldwake'
                      }
           , "ROE" => { order => 201004,
                        name => 'Rise of the Eldrazi'
                      }
           , "SOM" => { order => 201010,
                        name => 'Scars of Mirrodin'
                      }
           , "MBS" => { order => 201102,
                        name => 'Mirrodin Besieged'
                      }
           , "NPH" => { order => 201105,
                        name => 'New Phyrexia'
                      }
           , "ISD" => { order => 201109,
                        name => 'Innistrad'
                      }
           , "DKA" => { order => 201202,
                        name => 'Dark Ascension'
                      }
           , "AVR" => { order => 201204,
                        name => 'Avacyn Restored'
                      }
           , "RTR" => { order => 201210,
                        name => 'Return to Ravnica'
                      }
           , "GTC" => { order => 201302,
                        name => 'Gatecrash'
                      }
           , "DGM" => { order => 201305,
                        name => 'Dragon\'s Maze'
                      }
           , "CHR" => { order => 199507,
                        name => 'Chronicles'
                      }
           , "ATH" => { order => 199811,
                        name => 'Anthologies'
                      }
           , "BRB" => { order => 199911,
                        name => 'Battle Royale Box Set'
                      }
           , "BTD" => { order => 200012,
                        name => 'Beatdown Box Set'
                      }
           , "DKM" => { order => 200112,
                        name => 'Deckmasters: Garfield vs. Finkel'
                      }
           , "DPA" => { order => 201006,
                        name => 'Duels of the Planeswalkers'
                      }
           , "ARC" => { order => 201006,
                        name => 'Archenemy'
                      }
           , "MMA" => { order => 201306,
                        name => 'Modern Masters'
                      }
           , "EVG" => { order => 200711,
                        name => 'Duel Decks: Elves vs. Goblins'
                      }
           , "DD2" => { order => 200811,
                        name => 'Duel Decks: Jace vs. Chandra'
                      }
           , "DDC" => { order => 200904,
                        name => 'Duel Decks: Divine vs. Demonic'
                      }
           , "DDD" => { order => 200910,
                        name => 'Duel Decks: Garruk vs. Liliana'
                      }
           , "DDE" => { order => 201003,
                        name => 'Duel Decks: Phyrexia vs. the Coalition'
                      }
           , "DDF" => { order => 201009,
                        name => 'Duel Decks: Elspeth vs. Tezzeret'
                      }
           , "DDG" => { order => 201104,
                        name => 'Duel Decks: Knights vs. Dragons'
                      }
           , "DDH" => { order => 201109,
                        name => 'Duel Decks: Ajani vs. Nicol Bolas'
                      }
           , "DDI" => { order => 201203,
                        name => 'Duel Decks: Venser vs. Koth'
                      }
           , "DDJ" => { order => 201209,
                        name => 'Duel Decks: Izzet vs. Golgari'
                      }
           , "DDK" => { order => 201303,
                        name => 'Duel Decks: Sorin vs. Tibalt'
                      }
           , "DRB" => { order => 200808,
                        name => 'From the Vault: Dragons Wings of a Dragon'
                      }
           , "V09" => { order => 200908,
                        name => 'From the Vault: Exiled'
                      }
           , "V10" => { order => 201008,
                        name => 'From the Vault: Relics'
                      }
           , "V11" => { order => 201108,
                        name => 'From the Vault: Legends'
                      }
           , "V12" => { order => 201208,
                        name => 'From the Vault: Realms'
                      }
           , "HOP" => { order => 200909,
                        name => 'Planechase'
                      }
           , "PC2" => { order => 201206,
                        name => 'Planechase (2012 Edition)'
                      }
           , "H09" => { order => 200911,
                        name => 'Premium Deck Series: Slivers'
                      }
           , "PD2" => { order => 201011,
                        name => 'Premium Deck Series: Fire and Lightning'
                      }
           , "PD3" => { order => 201111,
                        name => 'Premium Deck Series: Graveborn'
                      }
           , "CMD" => { order => 201106,
                        name => 'Commander'
                      }
           , "CMA" => { order => 201211,
                        name => 'Commander\'s Arsenal'
                      }
           , "POR" => { order => 199706,
                        name => 'Portal'
                      }
           , "P02" => { order => 199806,
                        name => 'Portal Second Age'
                      }
           , "PTK" => { order => 199905,
                        name => 'Portal Three Kingdoms'
                      }
           , "S99" => { order => 199907,
                        name => 'Starter 1999'
                      }
           , "S00" => { order => 200007,
                        name => 'Starter 2000'
                      }
           );

sub set_sort()
{
    return $sets{$a}{order} cmp $sets{$b}{order};
}

sub get_set_name()
{
    my $set_code = shift;
    if(exists $sets{$set_code}) {
        return $sets{$set_code}{name};
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
                  , 0 > $quantity ? "" : "Near Mint"
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
        print &get_set_name($_) . "\n" if($format_puca);
        foreach(@{$list->{'have'}->{$_}}) {
            print "$_\n";
        }
        print "\n" if($format_motl || $format_puca);
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

sub print_dbox_have()
{
    my $have = shift;
    my $trade = shift;
    my $name = shift;
    my $foil = shift;
    my $promo = shift;
    my $textless = shift;
    my $set = shift;
    my $condition = shift;
    my $set_name = &get_set_name($set);
    $set_name = "\"$set_name\"" unless("" eq $set_name);

    print "$have"
        . "," . "$trade"
        . "," . "\"$name\""
        . "," . "$foil"
        . "," . "$textless"
        . "," . "$promo"
        . "," . ""
        . "," . "$set_name"
        . "," . "$condition"
        . "," . "English"
        . "\n";
}

sub print_dbox_haves()
{
    my $cards = shift;
    print "Count,Tradelist Count,Name,Foil,Textless," .
          "Promo,Signed,Edition,Condition,Language\n";

    for my $name (sort keys %$cards) {
        for my $set (sort set_sort keys $cards->{$name}{set}) {
            for my $type (sort keys $cards->{$name}{set}{$set}) {
                my $foil = "foil" eq $type ? "foil" : "";
                my $prmo = "prmo" eq $type ? "promo" : "";
                my $text = "text" eq $type ? "textless" : "";
                my $cond = "mcut" eq $type ? "Damaged" : "";
                my $h = $cards->{$name}{set}{$set}{$type};
                my $have = $h->{have};
                if(0 != $have) {
                    my $trade = $h->{trade};
                    &print_dbox_have( $have
                                    , $trade
                                    , $name
                                    , $foil
                                    , $prmo
                                    , $text
                                    , $set
                                    , $cond
                                    );
                }
            }
        }
    }
}


sub get_haves()
{
    my %cards = ();

    my @lines = read_file($HAVES);
    for my $card (@lines) {
        next if($card =~ /^#/);
        my @fields = split(/\|/,$card);

        my $norm = int($fields[$HNORM]);
        my $foil = int($fields[$HFOIL]);
        my $prmo = int($fields[$HPRMO]);
        my $text = int($fields[$HTEXT]);
        my $mcut = int($fields[$HMCUT]);
        my $expn = $fields[$HEXPN];
        my $rare = $fields[$HRARE];
        my $name = $fields[$HNAME];
        chomp($name);

        $cards{$name}{trade} += 0 + $norm + $foil + $prmo + $text + $mcut;
        $cards{$name}{set}{$expn}{norm}{have} = $norm;
        $cards{$name}{set}{$expn}{foil}{have} = $foil;
        $cards{$name}{set}{$expn}{prmo}{have} = $prmo;
        $cards{$name}{set}{$expn}{text}{have} = $text;
        $cards{$name}{set}{$expn}{mcut}{have} = $mcut;
        $cards{$name}{set}{$expn}{norm}{trade} = $norm;
        $cards{$name}{set}{$expn}{foil}{trade} = $foil;
        $cards{$name}{set}{$expn}{prmo}{trade} = $prmo;
        $cards{$name}{set}{$expn}{text}{trade} = $text;
        $cards{$name}{set}{$expn}{mcut}{trade} = $mcut;
        $cards{$name}{set}{$expn}{norm}{want} = 0;
        $cards{$name}{set}{$expn}{foil}{want} = 0;
        $cards{$name}{set}{$expn}{prmo}{want} = 0;
        $cards{$name}{set}{$expn}{text}{want} = 0;
        $cards{$name}{set}{$expn}{mcut}{want} = 0;
    }
    return \%cards;
}

sub set_wants()
{
    my $cards = shift;

    my @lines = read_file($WANTS);
    for my $card (@lines) {
        next if($card =~ /^#/);
        my @fields = split(/\|/,$card);
        my $want = $fields[$WNORM];
        my $expn = $fields[$WEXPN];
        my $name = $fields[$WNAME];
        chomp($name);

        $cards->{$name}{trade} -= $want;
        if(0 > $cards->{$name}{trade}) {
            $cards->{$name}{trade} = 0;
        }
        $cards->{$name}{set}{$expn}{norm}{want} = $want;
        $cards->{$name}{set}{$expn}{norm}{trade} -= $want;
        if(0 > $cards->{$name}{set}{$expn}{norm}{trade}) {
            $cards->{$name}{set}{$expn}{norm}{trade} = 0;
        }
    }
}

sub set_trade_nums()
{
    my $cards = shift;
    my $name = shift;
    my $set = shift;
    my $type = shift;
    my $trades = shift;

    if($cards->{$name}{set}{$set}{$type}{trade} > $trades) {
        $cards->{$name}{set}{$set}{$type}{trade} = $trades;
        $trades = 0;
    }
    else {
        $trades -= $cards->{$name}{set}{$set}{$type}{trade};
    }

    return $trades;
}
sub update_trade_nums()
{
    my $cards = shift;

    for my $name (sort keys %$cards) {
        my $trades = $cards->{$name}{trade};
        for my $set (sort set_sort keys $cards->{$name}{set}) {
            $trades = &set_trade_nums($cards, $name, $set, "mcut", $trades);
            $trades = &set_trade_nums($cards, $name, $set, "foil", $trades);
            $trades = &set_trade_nums($cards, $name, $set, "prmo", $trades);
            $trades = &set_trade_nums($cards, $name, $set, "text", $trades);
        }
        # Normal prints for all sets take priority for keeping vs trading
        for my $set (sort set_sort keys $cards->{$name}{set}) {
            $trades = &set_trade_nums($cards, $name, $set, "norm", $trades);
        }
    }
}


sub main()
{
    unless($format_motl xor ($format_dbox xor $format_puca)) {
        print "Specify EITHER '-m|--motl', '-d|--dbox', OR '-p|--puca'\n";
        exit 1;
    }

    my $cards = &get_haves();
    &set_wants($cards);
    &update_trade_nums($cards);
    &print_dbox_haves($cards)
    #for my $set (sort set_sort keys %sets) {
    #    print "$sets{$set}{name}\n";
    #}
}

&main();
