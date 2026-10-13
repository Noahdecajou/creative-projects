# WOR Studio

Studio local Words of Rizdom : thumbnails, Stories, Spotify, retours visuels et pretests.
Depot prive : code et trois workflows WOR uniquement. Aucun chat ni historique ChatGPT/Codex n'est exporte.

## Demarrer

Installer Node.js 20 ou plus, puis executer `npm start`.
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

Version 07 du studio local : atelier, pretest A/B, pretest des titres et grille YouTube.
Grain final de 3 %, portraits originaux et versions conservees. Spotify sans microphones.
Les pretests sont des evaluations heuristiques, pas des mesures de CTR ou des votes de spectateurs.
