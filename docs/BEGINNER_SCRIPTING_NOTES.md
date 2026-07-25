# Notes détaillées — Roblox Beginners Scripting Tutorial (18 parties)

Notes techniques complètes de la playlist YouTube **"Roblox Beginners Scripting Tutorial (2025)"** de la chaîne Balddev (18 vidéos), basées sur les sous-titres de chaque vidéo. Ce cours part de zéro (aucune connaissance en programmation supposée) et construit progressivement le vocabulaire Lua/Luau de base, jusqu'à un petit jeu complet à la fin qui combine toutes les notions.

Contrairement à `docs/FPS_TUTORIAL_NOTES.md` (qui documente des *patterns* de systèmes de jeu avancés), ce document est structuré comme un **cours ordonné** : chaque partie dépend des précédentes. Chaque section ci-dessous couvre : le concept enseigné, la syntaxe exacte, et le ou les exemples pratiques utilisés pour l'illustrer.

Convention observée dans toute la série : à chaque épisode, l'ancien script est désactivé (case "Enabled" décochée dans les Properties) plutôt que supprimé, et un nouveau `Script` est inséré dans `Workspace` et renommé d'après le sujet du jour.

---

## Part 1 — Prise en main de Roblox Studio

Aucune ligne de code. Mise en jambe avec l'interface :
- **Navigation caméra** : Z/Q/S/D (WASD) pour se déplacer, clic droit + glisser pour orienter la vue, E/Q molette pour monter/descendre, molette pour zoomer.
- **Le ruban (ribbon)** en haut change selon l'onglet (Home, Model, Avatar, Test, View, Plugins...).
- **L'Explorer** (panneau de droite) affiche l'arborescence du jeu — chaque objet Roblox appartient à un dossier de service précis (`Workspace`, `Players`, `Lighting`, etc.), et cette hiérarchie parent/enfant est la structure fondamentale de tout jeu Roblox.
- **Le panneau Properties** affiche/modifie les propriétés de l'objet sélectionné dans l'Explorer (ex. `BrickColor`, `Transparency`, `CastShadow`).
- **Outils de manipulation** : Select, Move (flèches d'axe), Scale, Rotate — insérés via Home → Insert → Part.
- **Sauvegarde** : File → Save to File (ou Ctrl+S).

## Part 2 — Premier script, `print()`

- Un script s'insère via le `+` à côté d'un service dans l'Explorer (ex. `Workspace`), en cherchant "Script" — trois types existent (Script, LocalScript, ModuleScript), ce cours utilise le `Script` classique (exécuté côté serveur) presque partout.
- Le script par défaut contient `print("Hello world!")`.
- **`print(...)`** écrit un message dans la fenêtre **Output** (View → Output) — visible uniquement quand le jeu tourne (Test → Play).
- Lua est **sensible à la casse** : `Print` ≠ `print`.
- Plusieurs `print(...)` s'exécutent dans l'ordre du script, de haut en bas.
- Test → Play lance le jeu ; Stop l'arrête.

## Part 3 — Types de données (Data Types)

Trois types de base introduits, chacun visible aussi dans le panneau Properties (ex. une case à cocher = un booléen, un slider 0→1 = un nombre) :
- **Boolean** : `true` / `false` uniquement (en minuscules).
- **Number** : entiers ou décimaux (`100`, `-100`, `100.5`) — pas de limite pratique de taille.
- **String** : texte entre guillemets doubles `"..."` ou simples `'...'` (les deux fonctionnent).

## Part 4 — Variables

- Déclaration : `local nomDeVariable = valeur`.
- Une variable est une **référence nommée** vers une valeur — modifier la valeur assignée à la variable met à jour partout où cette variable est utilisée, sans toucher au reste du code.
- Convention de nommage recommandée : **camelCase** (`maVariable`, pas `ma_variable`).
- Exemple donné : remplacer trois `print(100)` identiques par une seule variable `local myVariable = 100` réutilisée trois fois, puis ne changer la valeur qu'à un seul endroit.
- Autocomplétion Roblox (Tab) proposée quand on retape le nom d'une variable existante.

## Part 5 — Propriétés (accès via script)

- Contrairement au panneau Properties (modifiable seulement hors exécution), un script peut changer une propriété **pendant que le jeu tourne**.
- Chemin d'accès à un objet : `game.Workspace.NomDeLObjet.NomDeLaPropriete`, chaque `.` descend d'un niveau dans la hiérarchie (parent → enfant).
  ```lua
  game.Workspace.Baseplate.Transparency = 1
  game.Workspace.Baseplate.Material = "Brick"
  ```
- Bonne pratique : stocker la référence dans une variable pour éviter de répéter le chemin complet :
  ```lua
  local baseplate = game.Workspace.Baseplate
  baseplate.Transparency = 0.25
  baseplate.CastShadow = false -- propriété booléenne
  ```

## Part 6 — Fonctions

- Une fonction regroupe plusieurs lignes de code réutilisables en un seul appel.
- Déclaration : `local function nomDeLaFonction() ... end`.
- **Appel** = nom de la fonction suivi de parenthèses : `nomDeLaFonction()` — sans l'appel, la fonction est définie mais ne s'exécute jamais.
- Exemple : au lieu de copier-coller 3 lignes qui changent la transparence d'une part à chaque fois qu'on veut répéter l'effet, on les met dans une fonction `changeTransparency()` et on appelle juste cette fonction autant de fois que nécessaire — bien plus lisible et maintenable qu'un copier-coller répété.

## Part 7 — Maths, Paramètres, Arguments, Return

- **Opérations de base** : `+ - * /` entre deux nombres, éventuellement stockées dans une variable : `local addition = 2 + 2`.
- **Paramètres** : noms de valeurs déclarés entre les parenthèses d'une fonction, qui devient réutilisable avec des données différentes à chaque appel :
  ```lua
  local function addition(number1, number2)
      local result = number1 + number2
      return result
  end
  ```
- **Arguments** : les valeurs réellement passées à l'appel — `addition(5, 2)` retourne 7, `addition(3, 2)` retourne 5, etc. La différence clé : les *paramètres* sont les noms utilisés dans la déclaration, les *arguments* sont les valeurs concrètes fournies à l'appel.
- **`return`** renvoie une valeur calculée à l'endroit où la fonction a été appelée, permettant de la stocker dans une variable :
  ```lua
  local printResult = addition(8, 2)
  print(printResult) -- 10
  ```
  Sans `return`, la fonction peut agir (ex. `print` en interne) mais ne transmet aucune valeur en arrière à l'appelant.

## Part 8 — If / Elseif / Else

- Comparaison d'égalité : **`==`** (double égal), pas `=` (qui sert à l'assignation de variable).
  ```lua
  if 2 + 2 == 4 then
      print("2 + 2 does equal to 4")
  end
  ```
- **`else`** s'exécute uniquement si la condition du `if` a échoué ; doit être aligné avec le `if` correspondant.
- **`elseif`** ajoute une condition supplémentaire vérifiée seulement si tout ce qui précède a échoué — une seule branche `if/elseif/else` s'exécute au maximum par passage.
- À la différence de plusieurs blocs `if` séparés et indépendants : ceux-là sont **tous** évalués (donc potentiellement plusieurs branches exécutées), alors qu'une chaîne `if/elseif/else` n'en exécute qu'une seule.
- Exemple pratique : une fonction `addition(number1, number2)` qui imprime un message différent selon si `result == 4`, `result == 6`, ou aucun des deux (`else`).

## Part 9 — Scoping (portée des variables)

- Le mot-clé **`local`** limite une variable à son bloc de code (fonction, `if`, boucle...) — elle devient inaccessible (`unknown global`) en dehors de ce bloc.
- Une variable déclarée **sans** `local` devient globale (accessible partout) — **fortement déconseillé** dans ce cours (moins sûr, moins optimisé) ; à noter aussi qu'on ne peut de toute façon pas créer de variable globale à l'intérieur d'une fonction en Luau.
- Une variable ne peut être utilisée **qu'après** sa ligne de déclaration — l'appeler avant provoque une erreur.
- **`nil`** introduit ici : un type de donnée représentant "aucune valeur" / une absence de valeur.
- Exemple : deux variables de même nom (`result1`, `result2`) déclarées dans deux branches différentes d'un `if/else` — chacune n'existe que dans sa propre branche, inaccessible dans l'autre ni en dehors.

## Part 10 — Opérateurs logiques et relationnels

**Opérateurs logiques** (combinent plusieurs conditions) :
- **`and`** — les deux côtés doivent être vrais.
- **`or`** — un seul des deux côtés suffit.
- **`not`** — inverse une condition (attention : nécessite des parenthèses autour de l'expression comparée, ex. `not (2 + 2 == 4)`, sinon Lua tente une opération arithmétique invalide sur un booléen).

**Opérateurs relationnels** (comparent deux valeurs) :
| Symbole | Signification |
|---|---|
| `==` | égal à |
| `~=` | différent de |
| `>` | supérieur à |
| `<` | inférieur à |
| `>=` | supérieur ou égal à |
| `<=` | inférieur ou égal à |

Piège signalé : l'opérateur doit toujours précéder le signe égal (`>=`, jamais `=>`).
On peut chaîner plusieurs opérateurs logiques dans une même condition (`a and b or c and ...`).

## Part 11 — Boucles (Loops)

Motivation : répéter le même bloc de code sans copier-coller manuellement des dizaines de fois.

**Boucle `for`** — nombre d'itérations connu à l'avance :
```lua
for myCounter = 1, 5, 1 do
    print("statement")
end
```
Syntaxe : `valeur de départ, valeur de fin, incrément` (l'incrément vaut `1` par défaut et peut être omis). Un incrément négatif fait décompter la boucle en sens inverse.

**Boucle `while`** — condition inconnue en termes de nombre exact d'itérations, mais un critère d'arrêt est connu :
```lua
local myWhileCounter = 1
while myWhileCounter <= 5 do
    print("statement")
    myWhileCounter = myWhileCounter + 1 -- incrément MANUEL obligatoire
end
```
⚠️ Piège critique signalé explicitement : oublier d'incrémenter le compteur dans une boucle `while` crée une **boucle infinie qui plante le jeu**.

**Boucles imbriquées (nested loops)** : une boucle `for` entière à l'intérieur du corps d'une autre boucle `for`.

**`task.wait(secondes)`** — indispensable dans une boucle qui modifie une propriété visuelle plusieurs fois, sinon tous les changements arrivent dans la même frame et rien n'est visible (ex. faire défiler la couleur d'une part toutes les secondes).

## Part 12 — Break, Continue, Comments

- **`break`** interrompt immédiatement une boucle (`for` ou `while`) dès qu'une condition est remplie — indispensable pour éviter qu'une boucle avec une très grande borne (ex. 100 000 ou 1 000 000 itérations) tourne inutilement longtemps ou plante le script ("script timeout: exhausted allowed execution time" observé en direct dans la vidéo quand le `break` avait été oublié).
- **`continue`** saute uniquement l'itération courante (sans arrêter toute la boucle) si une condition est remplie, puis reprend normalement à l'itération suivante.
- **Commentaires** :
  - Ligne simple : `-- commentaire` (grisé, non exécuté).
  - Bloc multi-lignes : `--[[ ... ]]`.
  - Deux usages : désactiver temporairement du code sans le supprimer, ou documenter ce que fait un bloc de code.
- Rappel important sur l'ordre d'exécution : deux boucles `for`/`while` consécutives (non imbriquées) s'exécutent **l'une après l'autre**, jamais en parallèle — la deuxième attend que la première se termine entièrement.

## Part 13 — Événements (Events)

Deux événements natifs de Roblox couverts :

**`Players.PlayerAdded`** — se déclenche à chaque connexion d'un joueur :
```lua
game.Players.PlayerAdded:Connect(function(player)
    print("A new player has joined the game")
    print(player)
end)
```
Deux façons d'écrire la même chose : fonction anonyme inline (ci-dessus), ou fonction nommée séparément puis passée par référence :
```lua
local function playerAdded(player)
    print("A new player has joined")
end
game.Players.PlayerAdded:Connect(playerAdded)
```

**`BasePart.Touched`** — se déclenche quand une autre part touche la part concernée (y compris les parts du personnage du joueur) :
```lua
local touchPart = game.Workspace.TouchPart
touchPart.Touched:Connect(function(otherPart)
    print(otherPart.Name)
end)
```
Sans protection, cet événement se déclenche en rafale (une fois par part du personnage qui touche). Solution — le **debounce** :
```lua
local partIsTouched = false
touchPart.Touched:Connect(function(otherPart)
    if partIsTouched == false then
        partIsTouched = true
        print("Touched!")
        task.wait(2)
        partIsTouched = false
    end
end)
```

## Part 14 — FindFirstChild & WaitForChild

- Rappel hiérarchie : **parent** (le dossier/objet contenant) et **enfant** (l'objet contenu) — vocabulaire utilisé pour tout le reste du cours.
- **Model** vs **Folder** : un `Model` regroupe des parts pour qu'elles bougent/se sélectionnent comme un seul bloc ; un `Folder` sert juste à organiser (parts, scripts, assets) sans lier leur comportement physique.
- **`script.Parent`** — depuis un script placé à l'intérieur d'un `Model`, référence directement son parent sans repartir de `game.Workspace`.
- **`:FindFirstChild("Nom")`** — cherche un enfant par nom et retourne `nil` s'il n'existe pas (au lieu de lever une erreur comme le ferait `.Nom` direct) :
  ```lua
  local part1 = model:FindFirstChild("Part1")
  if part1 then
      part1.BrickColor = BrickColor.new("Cocoa")
  end
  ```
- **`:WaitForChild("Nom")`** — comme `FindFirstChild`, mais **attend** que l'enfant apparaisse (utile si l'objet est ajouté après coup, ex. dynamiquement) ; produit un avertissement "infinite yield possible" dans l'Output si l'attente traîne trop longtemps.
- **Exemple pratique complet — le "kill brick"** : une part rouge qui tue le joueur au contact.
  ```lua
  local killBrick = script.Parent
  killBrick.Touched:Connect(function(otherPart)
      local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
      if humanoid then
          humanoid.Health = 0
      end
  end)
  ```
  Le `Humanoid` est l'objet qui identifie qu'un personnage de joueur (et pas une part quelconque) touche la brique ; mettre sa propriété `Health` à 0 tue le joueur.

## Part 15 — Random (`math.random`)

- **`math.random(min, max)`** retourne un entier aléatoire dans l'intervalle **inclusif** `[min, max]`.
  ```lua
  local randomNumber = math.random(1, 6) -- dé à 6 faces
  ```
- **`math.random()`** sans arguments retourne un décimal aléatoire entre 0 et 1.
- ⚠️ `min` doit être strictement inférieur à `max`, sinon erreur `"interval is empty"`.
- **Exemple pratique — couleur aléatoire en boucle infinie** :
  ```lua
  local baseplate = game.Workspace.Baseplate
  while true do
      local redValue = math.random(0, 255)
      local greenValue = math.random(0, 255)
      local blueValue = math.random(0, 255)
      baseplate.Color = Color3.fromRGB(redValue, greenValue, blueValue)
      task.wait(2)
  end
  ```
  (`Color` + `Color3.fromRGB(r,g,b)` est présenté comme une alternative à `BrickColor` pour choisir une couleur via trois composantes numériques.)

## Part 16 — Leaderstats (statistiques de joueur)

- **Créer une instance depuis un script** (pas seulement via l'Explorer) :
  ```lua
  local newPart = Instance.new("Part")
  newPart.Name = "NewInstancePart"
  newPart.Parent = game.Workspace
  ```
  Le `.Parent` doit être assigné pour que l'objet apparaisse quelque part dans le jeu.
- Rappel : les valeurs simples (String/Number/BoolValue) existent aussi comme **instances** insérables (pas seulement comme littéraux dans un script).
- **Dossier `Players`** : chaque joueur connecté y a un objet propre contenant `Backpack`, `StarterGear`, `PlayerGui`, `PlayerScripts` — distinct de son **personnage** (`Character`), qui lui vit dans `Workspace`.
- **Recette standard du leaderboard** : un dossier nommé exactement `"leaderstats"` (casse et orthographe strictes) parenté au joueur, contenant une ou plusieurs valeurs qui s'affichent automatiquement en haut à droite de l'écran :
  ```lua
  game.Players.PlayerAdded:Connect(function(player)
      local leaderstats = Instance.new("Folder")
      leaderstats.Name = "leaderstats"
      leaderstats.Parent = player

      local coins = Instance.new("IntValue")
      coins.Name = "Coins"
      coins.Value = 0
      coins.Parent = leaderstats
  end)
  ```
- Incrémenter automatiquement : `coins.Value = coins.Value + 1` (jamais l'instance elle-même, toujours sa propriété `.Value`) — typiquement dans un `while true do ... task.wait(1) end`.

## Part 17 — Tables (Arrays & Dictionaries)

La notion la plus dense du cours : une **table** est une structure qui regroupe plusieurs valeurs (de types différents) dans une seule collection, créée avec des accolades `{}`.

**Array (tableau indexé)** — valeurs accessibles par position numérique, en partant de **1** (pas de 0) :
```lua
local myArray = {10, "string value", true, 500}
print(myArray[1]) -- 10
print(myArray[3]) -- true
```
- **`#myArray`** retourne le nombre d'éléments — évite de coder en dur la borne d'une boucle qui parcourt le tableau :
  ```lua
  for index = 1, #myArray do
      print(myArray[index])
  end
  ```
- `print(myArray)` directement n'affiche pas le contenu (juste une référence de table) — il faut itérer pour voir chaque valeur.
- **`table.insert(myArray, valeur)`** ajoute un élément à la fin.

**Dictionary (dictionnaire clé/valeur)** — valeurs recherchées par une **clé** nommée plutôt qu'une position :
```lua
local menu = {
    ["Cheeseburger"] = 15,
    ["Cola"] = 4,
}
print(menu["Cheeseburger"]) -- 15
```
Syntaxe alternative (équivalente quand la clé est un identifiant simple) :
```lua
local menu = { Cheeseburger = 15, Cola = 4 }
print(menu.Cheeseburger) -- 15
menu.Cheeseburger = 5 -- modification directe
```

**Itération** :
- **`pairs(table)`** — parcourt clés ET valeurs d'un dictionnaire, mais **dans un ordre non garanti** :
  ```lua
  for menuItem, price in pairs(menu) do
      print(menuItem, price)
  end
  ```
- **`ipairs(table)`** — parcourt un array dans l'ordre séquentiel garanti (1, 2, 3...), retourne index + valeur :
  ```lua
  for index, number in ipairs(myArray) do
      print(index, number)
  end
  ```

## Part 18 — Jeu final : parcours d'obstacles chronométré

Synthèse pratique de tout le cours à travers un mini-jeu : un parcours d'obstacles (obby) où chaque étape a une porte qui s'ouvre pendant un temps limité après avoir appuyé sur un bouton, plus des pièces à ramasser.

Systèmes combinés (sans nouveau concept — uniquement l'application de tout ce qui précède) :
- **Pièces aléatoires** : une part touchée (`Touched` + debounce) incrémente `leaderstats.Coins.Value` d'un montant aléatoire (`math.random(1, 5)`), puis devient transparente/désactivée pour ne plus être ramassable.
- **Portes chronométrées par étape** : un bouton (`Touched` + debounce) déclenche l'ouverture d'une porte (ex. déplacement ou distypage d'une part), lance un compte à rebours affiché dans l'Output (boucle `for`/`while` + `task.wait(1)`), puis referme la porte automatiquement à l'expiration du délai — le joueur doit traverser avant la fin du minuteur.
- Le tout repose entièrement sur les briques du cours : variables, fonctions, `if`, boucles, `task.wait`, événements `Touched`, `FindFirstChild`/humanoid, `math.random`, et le leaderboard `leaderstats`.

L'auteur recommande explicitement d'essayer de recréer ce jeu par soi-même *avant* de regarder l'implémentation, comme test final de la compréhension acquise sur les 17 épisodes précédents.

---

## Résumé — vocabulaire Luau couvert (ordre d'introduction)

`print` · types (bool/number/string) · variables (`local`) · propriétés (`objet.Propriete`) · fonctions (`function`) · maths/paramètres/arguments/`return` · `if`/`elseif`/`else` (`==`, pas `=`) · scoping (`local` vs global, `nil`) · opérateurs logiques (`and`/`or`/`not`) et relationnels (`==`,`~=`,`>`,`<`,`>=`,`<=`) · boucles `for`/`while` + `task.wait` · `break`/`continue`/commentaires · événements `PlayerAdded`/`Touched` + debounce · `FindFirstChild`/`WaitForChild` + `Humanoid` · `math.random` · `Instance.new` + `leaderstats` · tables (array/dictionary, `#`, `table.insert`, `pairs`/`ipairs`).

---

*Notes basées sur les sous-titres YouTube de chaque vidéo (auto-générés). Playlist : `PLQ1Qd31Hmi3W_CGDzYOp7enyHlOuO3MtC`.*
