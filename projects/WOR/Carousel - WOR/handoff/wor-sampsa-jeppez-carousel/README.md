# Sampsa Jeppez — Words of Rizdom

Carrousel final **V04**, sept slides **1080 × 1440**, grain monochrome **3 %**.
Ce dépôt privé transmet les visuels et les éléments nécessaires à leur reprise dans Codex.

![Aperçu des sept slides](preview.jpg)

## Reprendre dans Codex

1. Accepter l'invitation GitHub au dépôt avec le compte invité.
2. Cloner ce dépôt, puis ouvrir son dossier comme projet dans Codex.
3. Lire [AGENTS.md](AGENTS.md), ouvrir [Galerie.html](Galerie.html) et utiliser le [prompt de reprise](PROMPT_REPRISE.txt).

Les [PNG finaux](final/PNG) sont prêts à utiliser. Les [JPEG](final/JPEG) sont également fournis.
Les [masters sans grain](masters/clean) constituent le point de départ des retouches.
Les images sont aplaties : aucun PSD, calque de texte ou fichier Figma n'a été créé.
La reconstruction complète par IA n'est pas déterministe. Les pixels de la V04 livrée font référence.

## Contenu

| Dossier | Usage |
| --- | --- |
| `final/` | Sept PNG et sept JPEG approuvés, grain déjà appliqué |
| `masters/clean/` | Sept visuels avant la passe finale de grain |
| `masters/native/` | Trois sorties imagegen retenues pour les retouches V04 |
| `references/photos/` | Photos originales de Sampsa et Riz pour préserver leur identité |
| `references/angle/` | Inspiration de cadrage par-dessus l'épaule |
| `references/design/` | Six références visuelles de style sélectionnées |
| `history/` | Bases V01/V02 nécessaires pour comprendre ou reconstruire les retouches |
| `copy/` | Texte anglais final approuvé |
| `prompts/` | Prompts des retouches V02 et V04, avec références locales relatives |
| `docs/` | Direction artistique, méthode, décisions et connaissance du style |
| `sources/` | Transcription de l'épisode, source des affirmations éditoriales |
| `fonts/` | Poppins Bold et SemiBold avec leur licence OFL |
| `tools/` | Vérification et export ; reconstruction typographique Windows en complément |

## Vérifier ou exporter

Python 3.10+ :

```sh
python -m pip install -r requirements.txt
python tools/verify.py
python tools/export.py --output build/V04-reexport
```

L'export portable reproduit les pixels RGB des PNG V04 à partir des masters fournis,
avec le même générateur pseudo-aléatoire et les mêmes seeds. Les octets PNG et le rendu
JPEG peuvent différer selon l'encodeur. La vérification compare les pixels aux PNG approuvés.
L'export refuse un dossier de sortie existant et conserve tous les masters.

Pour une nouvelle version, fournir un dossier contenant les sept fichiers
`Slide-01-before-grain.png` à `Slide-07-before-grain.png` :

```sh
python tools/export.py --masters chemin/vers/masters --output build/V05
```

La reconstruction typographique originale est disponible sous Windows avec PowerShell 7 :

```powershell
pwsh -File tools/windows/rebuild.ps1
```

Elle reconstruit les masters à partir des bases archivées et des sorties imagegen déjà incluses,
sans nouvelle génération, dans `build/windows-rebuilt`. Son résultat dépend du moteur de rendu
Windows ; utiliser les masters approuvés pour conserver exactement la V04.

## Ouvrir la galerie

Ouvrir `Galerie.html` directement dans un navigateur, ou lancer :

```sh
python -m http.server 8000 --bind 127.0.0.1
```

Puis ouvrir `http://127.0.0.1:8000/Galerie.html`.
Le dépôt n'est pas un site public et ne publie pas automatiquement les images.

Les photos, textes, créations et références sont fournis pour cette collaboration privée.
La licence des fontes est distincte, dans [fonts/OFL.txt](fonts/OFL.txt).
