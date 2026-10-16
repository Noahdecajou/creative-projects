# Production et décisions approuvées

La V04 du 13 octobre 2026 contient sept images 1080 × 1440.
Le carrousel est photographique, sombre, avec un éclairage de plateau chaud, du texte blanc,
des accents rouges et des cartouches verts pour les résultats financiers. Les cartes sont anthracite.
Le footer et la navigation font partie des visuels approuvés.

## Composition par slide

1. Portrait calme de trois-quarts, bouche fermée ; chiffre $5 MILLION. recomposé avec Poppins Bold, sans déformation horizontale.
2. Portrait presque frontal en conversation ; le texte reste celui de la deuxième slide.
3. Sampsa vu de sa gauche, nez orienté vers la droite du canevas ; copie sur le backtesting.
4. Portrait et démonstration sur la conviction nécessaire pour augmenter les tailles.
5. Plan par-dessus l'épaule de Riz, Sampsa parlant en face ; référence de cadrage dans references/angle.
6. Visuel technique sans personne : illustration du drawdown de 46 %, pas une série réelle.
7. Deux personnes, annonce de l'épisode, CTA « SAMPSA ».

Le nom SAMPSA JEPPEZ est placé à x=52, y=31 (boîte visible), en Poppins SemiBold 26 px, sur toutes les slides.
Pour la V04, la zone CTA de la slide 7 a été limitée à x=30, y=1150, largeur=1020, hauteur=200.
Les portraits de cette slide restent ceux de la V02. Les slides 3–6 n'ont changé que par le nom avant grain.
Les retouches de portrait 1 et 2 sont génératives, guidées par les photographies originales.

## Grain

Bruit uniforme monochrome ±3 % de 255, soit ±7,65 niveaux avant arrondi.
La même valeur est ajoutée aux trois canaux RGB ; arrondi au plus proche, demi-valeurs éloignées de zéro,
puis bornage entre 0 et 255. L'écart maximal après quantification est de 8 niveaux.
Une seule passe, après composition à la taille finale. Seeds 20261014 à 20261020, une par slide.
L'algorithme utilise la séquence compatible avec System.Random(seed) de la production d'origine.
Les JPEG originaux ont été exportés à qualité 96 avec System.Drawing.

## Sources et limites

Les PNG livrés sont aplatis. Les fontes de l'ensemble du raster généré sont des approximations visuelles ;
seuls le nom et le chiffre de couverture ont été recomposés avec les fontes Poppins fournies.
Les sorties imagegen natives et les bases nécessaires sont incluses pour reprendre la méthode.
La génération IA ne permet pas de garantir une reproduction identique depuis un prompt.

La connaissance détaillée du design provient de l'analyse de 62 références initiales.
Ce dépôt en fournit les six qui ont été sélectionnées pour ce carrousel, pas l'atlas complet ni les autres séries.
Les mentions d'atlas, d'inventaire et de mesures dans le document historique renvoient au projet d'analyse d'origine.

La transcription de l'épisode accompagne le texte approuvé :
- Introduction : départ autour de $12K, puis plus de $5M ; deux premières années de pertes.
- Vers 1:36 : premières pertes autour de $10K, breakouts puis swing trading.
- Vers 4:12 : drawdown mensuel de 46 %.
- Vers 9:38 : travail avec un quant et automatisation.
- Vers 11:52 : plus de $3M pendant les trois premiers mois à pleine taille (juillet–septembre 2025), puis drawdown.
- Vers 12:36 : analyse des causes et taille des positions ; éviter de modifier une stratégie par réaction à une période courte.

Ce sont les déclarations de l'invité, sans audit indépendant joint. Ne pas transformer ces résultats en promesse.
Le CTA final et la formulation exacte à utiliser se trouvent dans copy/Texte_final.txt.
