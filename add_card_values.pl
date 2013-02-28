#!usr/bin/perl -w
use strict;

my $file = $ARGV[0];
unless(-e $file) {
    die "Must specify a trade list to add up." ;
}

open FILE, "<$file" or die $!;

my $total = 0;
while(<FILE>) {
    chomp;
    my @fields = split(' ', $_);
    $total += ($fields[0] * $fields[1]);
    for(my $i = 0; $i < @fields; ++$i) {
        print $fields[$i] . " ";
    }
    print "\n";
}
printf("Total: %2.2f\n", $total);
close FILE;
