#! /usr/bin/env perl

use strict;
use warnings;
use IPC::Run3;
use YAML::XS qw/LoadFile/;

#Récupère la configuration
my $conf = LoadFile('config.yml');
my $TreeTaggerBin = $conf->{TreeTagger};

my $file = $ARGV[0];

open ( my $in , '<', $file) or die( "Impossible d'ouvrir $file");

my @cmd = $TreeTaggerBin;

my $out;

run3 (\@cmd, \*$in, \$out);

close ($in);

my @lignes = split(/\n/, $out);

my $mots = "";
my $phrase = "";
my $texte ="";

#print @lignes;
#print "\n";

foreach my $ligne (@lignes) {
    my @exp = split (/\t/, $ligne);
    if ( $exp[1] ne "SENT") {
        if ($exp[1] eq "PUN" or $mots eq ""){
            $mots .= $exp[0];
        }
        elsif ($exp[1] =~ /^VER:/){
            $mots .= " [".$exp[2]."]";
        }
        else {
		    $mots .= " ".$exp[0];
        }
    }
    else {
		$phrase = $mots.". \n";
        $mots = "";
		print $phrase;
    }

}
