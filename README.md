# Creative projects

Depot prive de sauvegarde pour WOR, PFT, CF et les publicites Apex, Tradeify, Tradezella, Ninja Trader, Lucid et Vest.
Le workflow Carousel COPY partage et le code WOR Studio sont inclus.

## Perimetre

Seuls le code, les prompts, workflows, documents texte et configurations non sensibles sont copies depuis les dossiers explicitement listes dans sources.json.
Les images, videos, audio, PDF, documents binaires, ZIP et pages contenant des images en base64 restent locaux.
Les historiques Git existants, conversations ChatGPT/Codex, sessions, memoires, identifiants, fichiers .env, journaux, caches et dossiers de travail sont exclus.
Les sources originales ne sont jamais modifiees.
manifest.json inventorie les fichiers sauvegardes par empreinte SHA256 et donne les totaux des exclusions.
Un projet vide reste represente par PROJECT.md.

## Sauvegarde

Executer Backup.ps1 pour copier les fichiers eligibles, verifier le perimetre et envoyer un commit s'il existe des changements.
Le depot distant est controle comme prive avant chaque envoi. Aucun push force.
Les disparitions de fichiers sont refletees dans la copie ; les versions precedentes restent dans l'historique Git.
Les ecritures en cours sont verifiees avant copie. Une erreur bloque l'envoi.

Watch-Launch.ps1 est lance en arriere-plan a l'ouverture de session Windows via la tache CreativeProjects-Backup-OnChatGPTLaunch.
Il observe uniquement le lancement du processus ChatGPT.exe, sans lire les conversations.
Il sauvegarde quand l'application est deja ouverte au demarrage du surveillant, puis a chaque fermeture/reouverture observee.
Sans changements, aucun commit n'est cree. En cas d'echec, il retente toutes les cinq minutes tant que ChatGPT est ouvert.
Les journaux et le statut du dernier envoi sont dans .local/ et ne sont pas publies.
Les fichiers du depot sont une copie de sauvegarde : les modifications se font dans les projets originaux.
Pour installer ou reparer le declenchement, executer Install-Automation.ps1 sur cet ordinateur.
Pour le suspendre, desactiver la tache CreativeProjects-Backup-OnChatGPTLaunch dans le Planificateur de taches Windows et arreter son execution.

## Restaurer

Les fichiers se trouvent sous projects/WOR, projects/PFT, projects/CF, projects/ADS et projects/Shared.
Ne pas remplacer un dossier original sans examiner les differences.
Les medias ne sont pas sauvegardes par ce depot et necessitent une sauvegarde separee.
