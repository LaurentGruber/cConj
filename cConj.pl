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
my $claco = $conf->{claco};
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

#Récupère l'exercice (Claco) auquel associer la question
my $exerciceId = 1;

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
my $req;

foreach my $ligne (@lignes) {
    my @exp = split (/$TaggerSeparator/, $ligne);
    if ( $exp[1] ne "SENT") {
        if ($exp[1] eq "PUN" or $mots eq ""){
            $mots .= $exp[0];
        }
        elsif ($exp[1] =~ /^VER:/){
            if ($Tag->{Verbe}->{$exp[1]} =~ /^subjonctif/){
                $mots .= " ".$exp[0];
            }
            else {
                $nbVerbePhrase++ ;
                chomp($exp[1]);
                $verbe .= $exp[2].",";
                $temps .= $Tag->{Verbe}->{$exp[1]}.",";
                $reponse .= $exp[0].",";
                if ($claco == 1){
                    $mots .= qq( <input id="1" class="blank" name="blank_1" size="25" type="text" value="[REPONSE]" /> [$exp[2] - $Tag->{Verbe}->{$exp[1]}] );
                }
                else{ $mots .= " [Verbe] ";}
            }

        }
        else {
		    $mots .= " ".$exp[0];
        }
    }
    else {
		$phrase = $mots.".";
        if ($claco == 1){
            #Crée une question
            $req = qq(INSERT INTO ujm_question(user_id, category_id, title, locked, model, date_create) VALUES (1, 1, "$titreTexte", 0, 0, NOW()));
            $dbcon->do($req) or die "Echec requete $req : $DBI::errstr";
            my $question_id = $dbcon->{mysql_insertid};
            #Associe une question avec un exercice
            $req = qq(INSERT INTO ujm_exercise_question(exercise_id, question_id, ordre) VALUES ($exerciceId, $question_id, $question_id));
            $dbcon->do($req) or die "Echec requete $req : $DBI::errstr";
            #Crée une interaction
            $req = qq(INSERT INTO ujm_interaction(question_id, type, invite) VALUES ("$question_id", "InteractionHole", "<p>compl&egrave;te le texte</p>"));
            $dbcon->do($req) or die "Echec requete $req : $DBI::errstr";
            my $interaction_id = $dbcon->{mysql_insertid};
            #Crée le contenu de la question
            my @reponses = split (/,/, $reponse);
            my $phrasehtml = "<p>".$phrase."</p>";
            foreach $verbe (@reponses){
                $phrasehtml =~ s/\[REPONSE\]/$verbe/;
            }
            my $phrasehtmlw = "<p>".$phrase."</p>";
            $phrasehtmlw =~ s/\[REPONSE\]//g;
            $req = $dbcon->prepare(qq(INSERT INTO ujm_interaction_hole(interaction_id, html, htmlWithoutValue) VALUES ($interaction_id, ?, ?)));
            $req->execute($phrasehtml, $phrasehtmlw);
            my $interaction_hole_id = $dbcon->{mysql_insertid};
            #Crée les réponses
            my $rep ="";
            foreach $verbe (@reponses){
                $rep = $verbe;
                $req = qq(INSERT INTO ujm_hole (interaction_hole_id, size, position, orthography, selector) VALUES ($interaction_hole_id, 25, 1, 0, 0));
                $dbcon->do($req) or die "Echec requete $req : $DBI::errstr";
                my $hole_id = $dbcon->{mysql_insertid};
                $req = qq(INSERT INTO ujm_word_response(hole_id, response, score) VALUES ($hole_id, "$rep", 1));
                $dbcon->do($req) or die "Echec requete $req : $DBI::errstr";
            }
        }
        else {
            #Insert dans la base de donnée
            $req = qq(INSERT INTO PhraseEx(Phrase, Verbe, Temps, Reponse, TitreTexte) VALUES("$phrase", "$verbe", "$temps", "$reponse", "$titreTexte"));
            $dbcon->do($req) or die "Echec requete $req : $DBI::errstr";
        }
		print " Ajout du/des verbe(s) ".$verbe." à conjuguer au(x) temps suivant :".$temps."\n";
        $mots = "";
        $verbe = "";
        $temps = "";
        $reponse = "";
        $nbVerbePhrase = 0;
    }

#$dbcon->disconnect();
}
