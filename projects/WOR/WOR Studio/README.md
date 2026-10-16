# WOR Studio

Studio local Words of Rizdom : thumbnails, Stories, Spotify, retours visuels et pretests.
Depot prive : code et trois workflows WOR uniquement. Aucun chat ni historique ChatGPT/Codex n'est exporte.

## Demarrer

Installer Node.js 20 ou plus, puis executer `npm install --package-lock=false --ignore-scripts` et `npm start`.
Ouvrir http://127.0.0.1:8765. Les analyses utilisent le compte Codex connecte sur cet ordinateur.
Le studio utilise un serveur local : ce depot ne deploie pas le site sur Internet.

## Donnees locales

Les sessions, annotations, images importees, rapports et journaux restent dans les fichiers locaux et le navigateur.
Le gros fichier `dist/seed.js`, les captures et les images de reference ne sont pas synchronises.
Sur une nouvelle installation, `npm start` cree un seed vide. Les references et miniatures voisines YouTube doivent etre restaurees separement.
Le dossier existant conserve ses fichiers locaux ; la synchronisation ne les efface pas.
GitHub sauvegarde le code, pas les donnees de production.

## Synchronisation

Apres une modification terminee et verifiee, Codex enregistre une version et l'envoie au depot.
Commande manuelle : `powershell -ExecutionPolicy Bypass -File .\Sync-WOR.ps1 -Message "Description du changement"`.
Le script controle le depot cible, la branche main et la liste explicite des fichiers avant commit/push.
Aucune tache en arriere-plan n'exporte les conversations. Les nouvelles inclusions doivent etre autorisees explicitement.
Les decisions durables sont conservees ici sous forme de documentation technique, sans transcript de conversation.

## Etat initial

Version 09 du studio local : atelier, pretest A/B, pretest des titres et grille YouTube.
Grain final de 3 %, portraits originaux et versions conservees. Spotify sans microphones.
Les pretests sont des evaluations heuristiques, pas des mesures de CTR ou des votes de spectateurs.

## Rapports PDF en anglais

Le bouton **Rapport PDF - EN** est disponible dans le pretest des miniatures et la grille YouTube. Il propose la selection courante ou, a defaut, le top 3/top 5. Choisir une a cinq variantes puis creer le PDF.

Le document contient la synthese, le classement complet, les scores et observations detailles de chaque variante retenue, les grilles YouTube et la methode avec les sources visuelles. Les scores ne sont pas recalcules : Codex traduit uniquement les textes existants. La traduction est reutilisee pour la meme selection. Les images sont assemblees localement avec pdf-lib.

L'export exige un rapport recent correspondant aux donnees actuelles et aux empreintes des images analysees. Une traduction incomplete, une image modifiee ou une reference absente produit une erreur explicite, jamais un PDF avec des notes inventees. Les apercus sont toujours au format ordinateur, avec les memes huit voisins et la meme position pour toutes les variantes.

La dependance pdf-lib est fixee a la version 1.17.1. Le lanceur Windows l'installe si elle manque. Les PDF, traductions, sessions, images et donnees restent hors de Git ; la liste de synchronisation n'a pas ete elargie.


V09 — WOR, CF ET PFT
Le sélecteur de projet en haut à gauche ouvre Words of Rizdom, ChartFanatics ou Prop Firm Trader.
Les anciens épisodes et leurs rapports restent dans WOR. CF et PFT commencent avec un espace vide : créer le premier épisode. Aucun dossier de production externe n’est importé automatiquement.
Chaque projet dispose du même atelier, des prétests de miniatures et de titres, de la grille YouTube et du rapport PDF en anglais. Les épisodes, sélections et profils d’audience sont propres à chaque projet. Les noms de chaîne, briefs et exports suivent le projet actif.

Dans Nouvel épisode ou Brief : renseigner jusqu’à trois liens HTTPS Frame.io (hôte/Riz, invité, écran). Les anciens liens sont conservés dans le premier champ. Les liens servent au travail de collecte avec Codex ; aucun téléchargement de vidéo n’est déclenché.
Le bouton Inspirations de l’atelier rouvre ce formulaire. Importer plusieurs PNG, JPEG, WebP ou PDF, puis ajouter une note par fichier sur ce qu’il faut reprendre. Limites : 12 fichiers, 20 Mo par fichier, 30 Mo cumulés par épisode ; session complète limitée à 100 Mo. Enregistrer pour joindre les références à l’épisode. Annuler conserve la version enregistrée.
Le bouton Brief IA + fichiers exporte un ZIP avec le transcript, les trois points de vue, les retours et les vrais fichiers d’inspiration accompagnés de leurs notes. La création et la retouche d’images se reprennent dans Codex ; l’import d’une inspiration ne lance aucune analyse payante ni génération automatique.
Les fichiers sont aussi matérialisés sur cet ordinateur sous data/inspirations/ avec des noms SHA256. Le manifeste associe les originaux à leurs épisodes, projets et notes. Les anciennes copies restent locales ; seul le manifeste courant indique les pièces jointes actives. Aucun de ces fichiers n’est servi publiquement ni synchronisé sur GitHub. Les originaux ne sont pas modifiés ni grainés.
Les formats Story/Spotify utilisent le nom du projet et un habillage typographique local à examiner ; les inspirations servent à la reprise créative dans Codex. Grain final de 3 % conservé.
