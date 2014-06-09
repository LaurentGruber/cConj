#! /usr/bin/env perl
#==============================================================================
# Auteur : Laurent Gruber
# Licence : GNU GPL v3
# For the full copyright and license information, please view the LICENSE file
# that was distributed with this source code.
#==============================================================================

use strict;
use warnings;
use utf8;
use IPC::Run3;
use YAML::XS qw/LoadFile/;
use DBI;

#Récupère la configuration
my $conf = LoadFile('config/config.yml');
my $TaggerBin = $conf->{TaggerBin};
my $TaggerSeparator = $conf->{TaggerSeparator};
my $TagFile = $conf->{TagFile};
my $db = $conf->{db};
my $serveur = $conf->{serveur};
my $login = $conf->{login};
my $pass = $conf->{pass};
my $port = $conf->{port};

#Connect to SQLite database
my $dbcon = DBI->connect("dbi:mysql:database=$db;host=$serveur;port=$port",$login,$pass) or die "Could not connect to db";
$dbcon->{'mysql_enable_utf8'} = 1;
$dbcon->do('set names utf8');

#Récupère la structure des tags
my $Tag = LoadFile($TagFile);


#Récupère le fichier passé en argument et l'ouvre
my $file = $ARGV[0];
open ( my $in , '<', $file) or die( "Impossible d'ouvrir $file");

my $titreTexte = $ARGV[1];

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
my $nbVerbePhrase = 0;
my $verbe;
my $temps;
my $reponse;

foreach my $ligne (@lignes) {
    my @exp = split (/$TaggerSeparator/, $ligne);
    if ( $exp[1] ne "SENT") {
        if ($exp[1] eq "PUN" or $mots eq ""){
            $mots .= $exp[0];
        }
        elsif ($exp[1] =~ /^VER:/){
            $nbVerbePhrase++ ;
            chomp($exp[1]);
            $verbe .= $exp[2].",";
            $temps .= $Tag->{Verbe}->{$exp[1]}.",";
            $reponse .= $exp[0].",";
            $mots .= " [Verbe] ";

        }
        else {
		    $mots .= " ".$exp[0];
        }
    }
    else {
		$phrase = $mots.".";
		print $phrase." -> ".$verbe." -> ".$temps." -> ".$reponse." -> ".$nbVerbePhrase."\n"; # split sur , ensuite boucle selon nbVerbePhrase pour choper les diff verbe
        my $req = qq(INSERT INTO PhraseEx(Phrase, Verbe, Temps, Reponse, TitreTexte) VALUES("$phrase", "$verbe", "$temps", "$reponse", "$titreTexte"));
        $dbcon->do($req) or die "Echec requete $req : $DBI::errstr";
        $mots = "";
        $verbe = "";
        $temps = "";
        $reponse = "";
        $nbVerbePhrase = 0;
    }

#$dbcon->disconnect();
}
