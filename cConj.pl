#! /usr/bin/env perl

use strict;
use warnings;
use IPC::Run3;
use Config::General;

#Récupère la configuration
my $conf = Config::General->new("config.conf");
my %config = $conf->getall;

my $file = $ARGV[0];

open ( my $in , '<', $file) or die( "Impossible d'ouvrir $file");

my @cmd = $config{"TreeTagger"};

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
