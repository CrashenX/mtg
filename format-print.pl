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
           , "LGN" => 'Legions'
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
           , "TSB" => 'Time Spiral'
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
           , "BTD" => 'Beatdown Box Set'
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
    print "$have"
        . "," . "$trade"
        . "," . "\"$name\""
        . "," . "$foil"
        . "," . "$textless"
        . "," . "$promo"
        . "," . ""
        . "," . "$set"
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
        for my $set (sort keys $cards->{$name}{set}) {
            for my $type (sort keys $cards->{$name}{set}{$set}) {
                my $foil = "foil" eq $type ? "foil" : "";
                my $prmo = "prmo" eq $type ? "promo" : "";
                my $text = "text" eq $type ? "textless" : "";
                my $cond = "mcut" eq $type ? "Damaged" : "";
                my $h = $cards->{$name}{set}{$set}{$type};
                my $have = $h->{have};
                my $want = $h->{want};
                if(0 != $have) {
                    my $trade = $have - $want;
                    $trade = 0 > $trade ? 0 : $trade;
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

        my $norm = $fields[$HNORM];
        my $foil = $fields[$HFOIL];
        my $prmo = $fields[$HPRMO];
        my $text = $fields[$HTEXT];
        my $mcut = $fields[$HMCUT];
        my $expn = $fields[$HEXPN];
        my $rare = $fields[$HRARE];
        my $name = $fields[$HNAME];
        chomp($name);

        my $set_name = &get_set_name($expn);
        $set_name = "\"$set_name\"" unless("" eq $set_name);

        $cards{$name}{count} += 0 + $norm + $foil + $prmo + $text + $mcut;
        $cards{$name}{set}{$set_name}{norm}{have} = $norm;
        $cards{$name}{set}{$set_name}{foil}{have} = $foil;
        $cards{$name}{set}{$set_name}{prmo}{have} = $prmo;
        $cards{$name}{set}{$set_name}{text}{have} = $text;
        $cards{$name}{set}{$set_name}{mcut}{have} = $mcut;
        $cards{$name}{set}{$set_name}{norm}{want} = 0;
        $cards{$name}{set}{$set_name}{foil}{want} = 0;
        $cards{$name}{set}{$set_name}{prmo}{want} = 0;
        $cards{$name}{set}{$set_name}{text}{want} = 0;
        $cards{$name}{set}{$set_name}{mcut}{want} = 0;
    }
    return \%cards;
}

sub set_wants()
{
    my $wants = shift;

    my @lines = read_file($WANTS);
    for my $card (@lines) {
        next if($card =~ /^#/);
        my @fields = split(/\|/,$card);
        my $want = $fields[$WNORM];
        my $expn = $fields[$WEXPN];
        my $name = $fields[$WNAME];
        chomp($name);

        my $set_name = &get_set_name($expn);
        $set_name = "\"$set_name\"" unless("" eq $set_name);

        $wants->{$name}{set}{$set_name}{norm}{want} = $want;
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
    &print_dbox_haves($cards)
}

&main();
