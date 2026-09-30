# PlateThreatNumber

Addon autonome pour **WoW Forever**, interface **16001**. Affiche à droite des
nameplates Blizzard votre avance ou votre retard de menace par rapport au
meilleur autre participant de votre groupe ou raid, familiers compris.

## Installation

1. Fermez WoW.
2. Extrayez l’archive de distribution dans :
   `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. Vérifiez la structure :
   `Interface/AddOns/PlateThreatNumber/PlateThreatNumber.toc`.
4. Activez **PlateThreatNumber** dans la liste des addons et connectez-vous.
5. Entrez **`/ptn`** pour ouvrir les réglages natifs du jeu.

Pour installer depuis les sources, copiez les fichiers `.lua`, le fichier `.toc`
et ce README dans le dossier `PlateThreatNumber`. Les dossiers `tests`, `scripts`,
`.tools` et `dist` ne sont pas nécessaires en jeu. Aucune bibliothèque externe.
L’addon ne change pas les options du jeu : les nameplates ennemies doivent déjà
être activées.

## Affichage

`Écart = votre rawThreat − le plus grand rawThreat des autres participants`

Exemple : `1116 − 1000 = +116`. Les valeurs sont utilisées dans l’unité native de
l’API, sans division par 100 et sans conversion en pourcentage. L’écart est
arrondi à l’entier le plus proche ; les demi-entiers sont arrondis en s’éloignant
de zéro. Le signe et la couleur suivent cet entier affiché.

| Écart affiché | Tank | DPS / soigneur |
| --- | --- | --- |
| Positif | Vert | Rouge |
| Nul ou négatif | Rouge | Vert |

- Le joueur doit être en combat, vivant et présent dans la table de menace d’un
  PNJ vivant, attaquable et en combat dont la nameplate est visible.
- Les concurrents sont les autres membres du groupe/raid et leurs familiers,
  y compris votre propre familier. Les joueurs extérieurs au groupe et les
  invocations sans identifiant de familier accessible ne sont pas recensés.
- Sans concurrent vivant et connecté ayant une menace strictement positive,
  rien ne s’affiche. En solo, un familier peut donc permettre l’affichage.
- La menace du familier n’est pas fusionnée avec celle de son propriétaire.
- L’avance brute n’est pas une garantie de tenir l’aggro : les seuils de reprise,
  provocations et mécaniques particulières ne sont pas représentés.
- Une valeur protégée, invalide ou une erreur de lecture masque le nombre. Une
  absence de participation renvoyée par l’API exclut seulement ce concurrent.
  Une donnée protégée d’un concurrent ne permet pas de supposer sa menace nulle.

## Réglages

`/ptn` ouvre **Options → AddOns → PlateThreatNumber**.

| Réglage | Valeur initiale |
| --- | --- |
| Activation | Activé |
| Rôle | Automatique |
| Taille du texte | 16 |
| Décalage horizontal / vertical | 0 / 0 |

En mode automatique, le rôle déclaré dans le groupe est utilisé. Sans rôle
déclaré, les couleurs DPS / soigneur s’appliquent. Vous pouvez forcer **Tank** ou
**DPS / soigneur**. Le rôle est enregistré par personnage ; les autres réglages
sont partagés entre les personnages. Le texte utilise la police native avec
contour et une marge initiale de 8 pixels après le bord droit de la plaque et
son indicateur de niveau. Les décalages sont ajoutés à cette marge.

Locales : anglais US/GB, français, allemand, espagnol ES/MX, italien, portugais
BR, russe, coréen, chinois simplifié et traditionnel. Repli anglais pour une
locale inconnue.

## Performances et compatibilité

Le suivi des plaques est événementiel. Les événements de menace regroupent les
actualisations sur 200 ms. Seules les plaques invalidées sont recalculées ; un
changement de groupe ou un événement de membre sans ennemi identifié peut
invalider toutes les plaques visibles. Les changements de vie ordinaires ne
déclenchent pas de lecture de menace ; les morts invalident l’affichage.

Aucune lecture de menace hors combat ou lorsque l’addon est désactivé. Aucun
`OnUpdate`, journal de combat, échange réseau ou parcours des unités du monde.
Le minuteur ponctuel est annulé à la sortie du combat. Les éléments de texte
sont réutilisés lors du recyclage des nameplates.

L’addon ajoute son propre texte et utilise des hooks après les fonctions
Blizzard. Il ne modifie ni les noms, ni les couleurs des noms, ni les icônes de
faction : il est conçu pour coexister avec **PlateFaction**. Les remplacements
complets de nameplates ne sont pas pris en charge dans cette version.

## État des vérifications

- Installation locale identifiée pendant la préparation : **1.60.1.70124**.
- Un test utilisateur de `UnitDetailedThreatSituation("player", "target")` a
  renvoyé une valeur numérique. Cela ne prouve pas l’accès aux autres joueurs
  ni aux plaques non ciblées dans tous les types de combat.
- Tests automatisés sous Lua 5.1 avec API WoW simulées : calculs, couleurs,
  filtrage, restrictions, événements, recyclage, réglages et traductions.
- **Affichage réel, accès aux menaces de groupe en donjon et coexistence visuelle
  avec PlateFaction : à valider en jeu.** Les tests simulés ne valident pas les
  restrictions de sécurité, le rendu ou les événements d’un client réel.

### Vérification en jeu

1. Avec PlateFaction activé, ouvrez `/ptn` et vérifiez les textes et les réglages.
2. Hors combat : aucun nombre. En solo sans familier : aucun nombre.
3. En groupe, attaquez un ennemi à deux : testez une avance, un retard, puis un
   changement de rôle manuel. Vérifiez les couleurs du tableau ci-dessus.
4. Combattez plusieurs ennemis : vérifiez les plaques ciblées et non ciblées,
   ainsi qu’un ennemi voisin combattant seulement un autre groupe.
5. Faites prendre l’aggro à un familier, puis retirez-le ; testez une mort,
   un départ du groupe et un changement de rôle de groupe.
6. Éloignez-vous puis revenez pour recycler les plaques : aucun ancien nombre
   ne doit apparaître sur une autre unité. Vérifiez l’espacement après le niveau
   et l’absence de chevauchement avec PlateFaction.
7. Répétez en donjon et, si possible, en raid. Les valeurs protégées doivent
   faire disparaître le nombre sans produire d’erreur Lua.
8. Sortez du combat : disparition immédiate. Faites `/reload`, puis reconnectez
   le personnage pour contrôler la persistance des réglages et l’absence
   d’erreurs dans BugSack si cet addon est activé.

Diagnostic facultatif sur votre cible pendant le combat :

```lua
/run local _,_,_,_,v=UnitDetailedThreatSituation("player","target"); if issecretvalue and issecretvalue(v) then print("PTN: secret") else print("PTN:",type(v),v) end
```

## Développement

Python et le paquet de test `lupa` sont nécessaires seulement pour les tests :

```text
python -m pip install --target .tools/lua lupa==2.8
python tests/run.py
python scripts/package.py
```

Les tests utilisent le moteur **Lua 5.1** de Lupa et chargent les mêmes fichiers
que le client, y compris le panneau de réglages. Le script de distribution crée
`dist/PlateThreatNumber-1.0.0.zip` avec uniquement les fichiers utiles à l’addon.

## English quick start

Extract the release ZIP into `_classic_beta_/Interface/AddOns/`, preserving the
`PlateThreatNumber` folder. Enable the addon, enable enemy nameplates, then use
`/ptn` for localized settings. It displays your raw threat minus the highest raw
threat of another group/raid member or pet. No rival with positive threat means
no number. Tank: positive green, zero/negative red; other roles: reversed.
Automatic mode uses the assigned group role, defaulting to non-tank. The role
override is saved per character. Restricted or unavailable data hides the text.
Live group/dungeon behavior and visual coexistence still require in-game testing.
