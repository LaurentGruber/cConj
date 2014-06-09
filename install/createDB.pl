#! /usr/bin/env perl
#==============================================================================
# Auteur : Laurent Gruber
# Licence : GNU GPL v3
# For the full copyright and license information, please view the LICENSE file
# that was distributed with this source code.
#==============================================================================

use strict;
use warnings;
use YAML::XS qw/LoadFile/;
use DBI;

#Récupère la configuration
my $conf = LoadFile('../config/config.yml');
my $db = $conf->{db};
my $serveur = $conf->{serveur};
my $login = $conf->{login};
my $pass = $conf->{pass};
my $port = $conf->{port};

#Connect to SQLite database
my $dbcon = DBI->connect("dbi:mysql:database=$db;host=$serveur;port=$port",$login,$pass) or die "Could not connect to db";

$dbcon->do("DROP TABLE IF EXISTS PhraseEx");
$dbcon->do("CREATE TABLE PhraseEx(
                Id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                Phrase TEXT,
                Verbe VARCHAR(75),
                Temps VARCHAR(75),
                Reponse VARCHAR(75),
                TitreTexte VARCHAR(75)
                )") or die "Impossible de créer la table PhraseEx";

$dbcon->disconnect();
