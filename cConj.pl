#! /usr/bin/env perl

use strict;
use warnings;
use IPC::Run3;
use YAML::XS qw/LoadFile/;

#Récupère la configuration
my $conf = LoadFile('config/config.yml');
my $TaggerBin = $conf->{TaggerBin};
my $TaggerSeparator = $conf->{TaggerSeparator};
my $TagFile = $conf->{TagFile};

#Récupère la structure des tags
my $Tag = LoadFile($TagFile);


#Récupère le fichier passé en argument et l'ouvre
my $file = $ARGV[0];
open ( my $in , '<', $file) or die( "Impossible d'ouvrir $file");

#Fait passer le Tagger sur le fichier
my @cmd = $TaggerBin;
my $out;
run3 (\@cmd, \*$in, \$out);
close ($in);

#Sépare ligne par ligne
my @lignes = split(/\n/, $out);

#Traitement des lignes
my $mots = "";
my $phrase = "";
my $texte ="";

foreach my $ligne (@lignes) {
    my @exp = split (/$TaggerSeparator/, $ligne);
    if ( $exp[1] ne "SENT") {
        if ($exp[1] eq "PUN" or $mots eq ""){
            $mots .= $exp[0];
        }
        elsif ($exp[1] =~ /^VER:/){
            chomp($exp[1]);
            my $temps = $Tag->{Verbe}->{$exp[1]};
            #my $temps = $exp[1];
            $mots .= " [ ".$exp[2]." ".$temps."-> Rep: ".$exp[0]." ]";
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
