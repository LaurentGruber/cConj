cConj
=====

Création d'exercice de conjugaison à partir d'un fichier texte

Dépendance
==========

TreeTagger : http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/

Dépendances à des modules Perl
=============================

IPC::Run3

YAML::XS

Installation
============

0. Cloner ce repository

    `git clone https://github.com/LaurentGruber/cConj.git`

1. Installer TreeTagger

> Voir http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/

2. Créer la base de donnée (Facultatif si intégration avec Claroline Connect)

    `CREATE DATABASE cConj;
    GRANT ALL PRIVILEGES ON cConj.* TO 'cconj'@'localhost' IDENTIFIED BY 'cconj';`

3. Mettre les paramètres Database et Tagger dans le fichier config/config.yml

4. Exécuter le script createDB (Facultatif si intégration avec Claroline Connect)

    `perl install/createDB.pl`

5. L'application est prête à être utilisée

Utilisation
===========

cConj.pl PathToTextFile TitreDuTexte
