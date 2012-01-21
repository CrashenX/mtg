#!/usr/bin/perl -w
use strict;
use File::Slurp;

my $cards = read_file('magic.cards');

# Key / Value Separator
$cards =~ s/^([^:]+): \t/$1 = /msg;

# Power and Toughness Separation
my $power = '[^{}\/]+|[^{}\/]*{[^}]+}';
my $tough = $power;
$cards =~
    s/^Pow\/Tgh = \(($power)\/($tough)\)[^\n]*/Power = $1\nToughness = $2/msg;
$cards =~ s/^Pow\/Tgh = $/Power =\nToughness =/msg;

# Card Separator
$cards =~ s/^(Set\/Rarity = [^\n]*\n)/$1|/msg;
print "^$cards\n$"
