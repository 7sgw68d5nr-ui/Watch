# Notes techniques — Roblox Studio FPS Shooter Tutorial (22 parties)

Résumé technique complet de la playlist YouTube "Roblox Studio FPS Shooter Tutorial" (22 vidéos), regardée et analysée intégralement (transcript + frames vidéo) pour servir de référence lors de la construction de **Quarantine Regen** ou de tout autre FPS Roblox. Voir `docs/GAME_DESIGN.md` pour la spec du jeu lui-même ; ce document couvre les *techniques et patterns de code* observés dans la série tutoriel, pas le design de Quarantine Regen.

Le tutoriel construit un jeu nommé "Zara FPS Tutorial" avec une architecture client/serveur classique : un `framework` (table Lua) répliqué entre `StarterPlayerScripts` (client) et `ServerScriptService` (serveur), un dossier `ReplicatedStorage.Modules` avec un ModuleScript par arme/item (`Settings` exporté), et des `RemoteEvent` dans `ReplicatedStorage.Events` pour la communication client→serveur→autres clients.

⚠️ Le code du tutoriel n'est **jamais parfaitement propre** — le créateur débogue en direct, corrige des fautes de frappe, revient sur ses choix. Ces notes retiennent le *pattern final qui fonctionne*, pas le cheminement de débogage.

---

## Part 1 — Viewmodel FPS, rig, framework de base, changement d'arme

- **Viewmodel FPS classique** : rig R6 vide (humanoid/head/legs/torso supprimés, seuls les bras gardés), armes attachées aux bras (dupliquées depuis un kit d'armes du Toolbox), tout renommé/soudé à la main via le plugin **Rig Edit Light**. Une part invisible `Main` (0.1×0.1×0.1, transparence 1, ancrée) sert de point de rotation pour l'animation.
- **Fake camera** : une part "FakeCamera" (transparence 1) + plugin **Auto Camera Lock** pour prévisualiser le point de vue FPS directement dans Studio sans lancer le jeu.
- **Structure du framework** (`StarterPlayerScripts` client) :
  ```lua
  local framework = {
    inventory = {"M4A1", "M9", "Knife", "Frag"},  -- slot 1..4
    module = nil,       -- ModuleScript.Settings actuellement équipé
    viewModel = nil,    -- modèle du viewmodel actif
    currentSlot = 1,
  }
  function loadSlot(item)
    framework.module = require(modulesFolder:FindFirstChild(item))
    framework.viewModel = viewModelsFolder:FindFirstChild(item):Clone()
    framework.viewModel.Parent = camera
  end
  ```
- **Attache du viewmodel à la caméra** : dans `RunService.RenderStepped`, pour chaque `Model` enfant de la caméra, `model:SetPrimaryPartCFrame(camera.CFrame)`.
- **Changement de slot** (touches 1/2/3) : détruire l'ancien modèle viewmodel avant de charger le nouveau, sinon plusieurs armes restent affichées en même temps (bug classique).
- Chaque arme a son propre `ModuleScript` sous `ReplicatedStorage.Modules`, retournant une table `Settings` — **pattern répété pour toute la série**.
- Une part "End" (position épaule/corps) sert de référence pour la visée (ADS), préparée pour l'épisode suivant.

## Part 2 — Visée (ADS), sprint, sway d'arme, tête qui bob

- **ADS (aim down sights)** : lerp entre deux `CFrame` (`mcf = mcf:Lerp(goalCFrame, aimSmooth)`), `aimSmooth` étant une valeur par arme dans le `ModuleScript` (armes lourdes = lerp plus lent). Un flag `canAim` par arme permet de désactiver l'ADS (ex. futur couteau).
- **Sway d'arme (weapon sway)** : capte la rotation delta de la caméra entre deux frames (`camera.CFrame:ToObjectSpace(lastCameraCF)`), applique un léger `CFrame.Angles` inversé au viewmodel — donne l'impression que l'arme "traîne" derrière le regard. Inversé (signe négatif) en visée pour un effet plus resserré.
- **Sprint** : script séparé dans `StarterCharacterScripts`, `Humanoid.WalkSpeed` changé au press/release de Shift.
- **Head bob** : `math.sin(tick() * frequency) * amplitude` appliqué à `Humanoid.CameraOffset`, actif seulement si `Humanoid.MoveDirection.Magnitude > 0`. Fréquence/amplitude différentes selon marche/sprint/crouch (détection par la valeur de `WalkSpeed`).
- Le viewmodel reçoit le même bob (divisé, inversé) via `Humanoid.CameraOffset` pour rester synchronisé avec la caméra sans bouger exactement pareil.

## Part 3 — UI HUD, tir semi/full-auto répliqué, son 3D

- **HUD** : `ScreenGui` "Hood" avec nom d'arme, compteur ammo/maxAmmo, texte "Semi"/"Full Auto" — mis à jour dans `RenderStepped` depuis `framework.module`.
- **Tir animé** : animation "Fire" jouée via `AnimationController` + `Animator` sur le viewmodel (clé Roblox uploadée séparément par arme).
- **Son de tir répliqué** : `Sound` parenté à `Character.UpperTorso` (pas au viewmodel, qui n'existe que côté client), `SoundId`/`Volume` lus depuis le module de l'arme.
- **Fire modes** : `canSemi`/`canFullAuto` + `fireMode` ("semi"/"full auto") par arme ; full auto = boucle `while isShooting do ... task.wait(module.fireRate) end` déclenchée par `mouse.Button1Down`/`Button1Up`.
- Base de `ammo`/`maxAmmo` par arme, décrémenté au tir, plus de tir si `ammo == 0`.

## Part 4 — Réplication serveur du tir, ammo UI, reload basique, fix bugs de transition

- **Bug critique corrigé** : le son de tir et les futures actions étaient gérées **côté client uniquement** → invisibles/inaudibles pour les autres joueurs. Fix : script serveur (`ServerScriptService.Framework_Server`) qui écoute un `RemoteEvent` "Shoot" (`OnServerEvent`) et crée le son sur le `Character.UpperTorso` du tireur — répliqué automatiquement à tout le monde.
- `RemoteEvent "PlayerAdded"` (`FireClient`) : envoie player+character du serveur vers le client au moment du spawn, pattern de base pour toute synchro serveur→client individuelle.
- **Reload basique** : touche R → `isReloading = true`, bloque le tir (`canShoot = false`), attend `module.reloadTime`, remet `ammo = maxAmmo`, débloque.
- **Debounce anti-spam-clic** : `debounce` bool + `task.wait(fireRate)` empêche les clics plus rapides que la cadence de l'arme (protection anti auto-clicker basique).
- Fix de la "téléportation" de l'arme entre marche/sprint/idle : lerp du CFrame de sprint au lieu d'un switch instantané.

## Part 4.5 — Import d'animations Blender (hors-code)

Épisode 100% outils, sans code : export du rig viewmodel vers Blender via le plugin **Blender Animations**, `Clean Mesh Parts`, animation dans Blender, réimport + upload vers Roblox. Optionnel — la Roblox Animation Editor native suffit pour suivre le reste de la série.

## Part 5 — Camera shake, fix reload/sprint/mort

- **Camera shake générique** : fonction `updateCameraShake()` qui compare le `CFrame` du viewmodel (relatif à `FakeCamera`) entre deux frames et applique la différence à la vraie caméra (`camera.CFrame *= newCamCF:ToObjectSpace(oldCamCF)`) — permet à n'importe quelle animation du viewmodel (recul, etc.) de "secouer" la caméra sans code dédié par animation.
- Fix : impossible de changer d'arme pendant le reload (`isReloading` check dans `loadSlot`).
- Fix : impossible de sprinter en visant (`isAiming and isSprinting` mutuellement exclusifs).
- **Bug de mort/reset** (long débogage en direct) : après la mort, `player`/`character`/`humanoid` pointaient vers l'ancien (mort) personnage. Fix : réassigner ces variables dans `Player.CharacterAdded` (pas dans `Humanoid.Died`) pour capter le tout nouveau personnage à chaque spawn. **Pattern récurrent dans toute la série** : ce bug de "framework qui référence l'ancien personnage" revient plusieurs fois (refixé plus radicalement en Part 8.5 en déplaçant le script client vers `StarterCharacterScripts`).
- `UserInputService.MouseIconEnabled = false` + désactivation de `MouseLockOption`/`AutoJump` dans `StarterPlayer`, caméra en mode **LockFirstPerson**.

## Part 5.5 — Système de tir "physique" (bullet part + BodyVelocity), dégâts, headshot

- **Bullets physiques** plutôt que raycast : une `Part` (petite, `CanCollide=false`, `Anchored=false` après spawn) instanciée à la position du canon (`Muzzle`, part dédiée soudée sur le canon de chaque arme), orientée vers le point visé (`CFrame.new(muzzlePos, mouse.Hit.Position)`), propulsée via `BodyVelocity` (`MaxForce = Vector3.new(math.huge, math.huge, math.huge)`, `Velocity = bullet.CFrame.LookVector * speed`).
- **Dégâts** : `bullet.Touched` → si `hit.Parent:FindFirstChild("Humanoid")`, appliquer `damage` (×2 si `hit.Name == "Head"` → headshot).
- **Anti self-damage** : `if hit.Parent ~= player.Character then ...`.
- **Fix de latence de collision** : `bullet:SetNetworkOwner(player)` — sans ça, un léger délai apparaît avant que le hit soit détecté.
- `Mouse.TargetFilter = framework.viewModel` pour empêcher le viewmodel de bloquer le raycast du curseur.
- Nettoyage : `task.wait(20)` puis `bullet:Destroy()` pour éviter l'accumulation de parts (lag).
- Ce système de "bullet physique" sera **entièrement remplacé par FastCast Redux en Part 10.5** (voir plus bas) — c'est une étape intermédiaire pédagogique, pas le système final.

## Part 6 — Animations complètes (equip/reload/inspect/idle), nouvelles armes, polish visuel

- Nouvelles armes ajoutées hors-caméra : AK-74, M45A1 (le créateur explique le processus mais ne le filme pas en détail — "regardez les tutos précédents").
- **Pipeline d'animation complet par arme**, chaque animation étant un simple champ `AnimationId` dans le `ModuleScript.Settings`, jouée via `AnimationTrack:Play()`/`:Stop()` :
  - `equipAnim` / `deequipAnim` — au changement de slot.
  - `reloadAnim` + `emptyReloadAnim` (variante différente si on recharge à sec).
  - `idleAnim` + `emptyIdleAnim` (variante "arme vide", jouée en boucle après une balle à 0, arrêtée au reload).
  - `inspectAnim` — déclenché par une touche dédiée (V dans le tutoriel), bloque tir/reload pendant qu'elle joue (`canInspect`/`isInspecting`).
- **Anti-superposition d'animations** : condition géante qui vérifie qu'*aucune* autre animation (`fireAnim`, `emptyFireAnim`, `reloadAnim`, `inspectAnim`, `equipAnim`, `deequipAnim`, `idleAnim`...) n'est `.IsPlaying` avant d'en lancer une nouvelle — pattern qui deviendra plus propre en Part 8.5 (regroupement en tables `firstPerson`/`thirdPerson` + fonction "stop all").
- **Depth of field au inspect** : effet de flou d'arrière-plan (`DepthOfFieldEffect`) activé pendant l'inspection pour un effet cinématique.
- Polish visuel : ciel/soleil (plugin de positionnement solaire), nuages (`Terrain.Clouds`), dummies de test (rig R15 avatar, non-ancré).
- Fix du bug de reload multiple (double-appui).
- **Les loadouts, teasés en intro, sont explicitement repoussés à Part 6.5** ("this is part six, we're gonna go into part 6.5 now").

## Part 6.5 — Menu de sélection de Loadout (première UI de jeu)

- Nouveau `ScreenGui` "Menu" avec un panneau `LoadoutMenu` : deux boutons **Loadout1**/**Loadout2**, chacun listant Primary/Secondary/Melee/Throwable, plus boutons **Customize** et **Select**. Plugin **Auto Scale Lite** pour convertir Offset→Scale (UI adaptative).
- **Curseur dynamique** : boucle sur `menu:GetChildren()` chaque frame — `UserInputService.MouseIconEnabled = true` si un `Frame` du menu est visible, sinon verrouillé en FPS.
- **Verrouillage des actions pendant le menu** : `canShoot`/`canReload`/`canInspect = false` tant que le menu est affiché.
- Sélection de loadout : `framework.inventory[1] = framework.loadouts["loadout" .. currentLoadout][1]`, appliqué au spawn.
- Bug fixes en multijoueur live : tir juste après la mort, viewmodel "cassé" si mort pendant le tir, menu qui se ré-affiche après un respawn non désiré.
- Conseil de production : laisser le menu de loadout visible par défaut au premier spawn (pas caché) pour forcer un choix d'équipement.

## Part 7 — Armes visibles en troisième personne

- Un vrai modèle d'arme (pas le viewmodel FPS) est attaché à la main du personnage via un `Motor6D` : `joint.Part0 = character.RightHand`, `joint.Part1 = gunModel.PrimaryPart`, `joint.Parent = gunPart`.
- Dossier séparé `ReplicatedStorage.Weapons` (modèles pleine échelle, distincts des `ViewModels` FPS).
- Chaque modèle d'arme "third person" a sa propre part `Root`/`Main` (équivalent du `Main` du viewmodel) pour permettre l'animation en synchronisation avec les animations FPS.
- Ce système reste minimal dans cet épisode (attache statique) — les vraies animations troisième personne synchronisées arrivent en Part 8.5.

## Part 7.5 — Interface "Customize" (base du futur menu d'attachements)

- Ajout d'un bouton **Customize** dans le menu de loadout qui ouvre un nouveau panneau `CustomizeMenu` (remplace `LoadoutMenu`, toggle de visibilité).
- Le créateur admet explicitement vouloir refaire proprement le code de loadout ("I don't like the way it's coded, I think I can do a lot better") — **le code de loadout n'est jamais considéré "fini"** dans la série, retouché à plusieurs reprises.
- Ce panneau vide (juste la structure UI) sera rempli avec le système d'attachements dès Part 8.

## Part 8 — Système d'attachements (optiques/sights)

- Nouvelle table par arme : `Settings.Attachments.Sights = {"RedDotSight", ...}` (liste de noms), plus `currentSight` (nil = "iron sights" par défaut).
- **Modèle physique d'attachement** : ex. Red Dot Sight positionné/soudé sur le rail de l'arme dans le viewmodel, `Transparency` gérée par code (1 = caché, 0 = visible) plutôt que parenté/déparenté dynamiquement — évite les soudures à refaire.
- **UI `CustomizeMenu`** : sous-panneau "Sites" listant les sights disponibles pour l'arme sélectionnée (`AttachmentSelect`, cloné dynamiquement par entrée de la table `Attachments.Sights`), sélection → met à jour `currentSight` et bascule les transparences.
- **Pattern générique et extensible** : ce système (`attachmentType` + table de noms + boucle qui clone les entrées de menu) est **directement réutilisé et étendu** dans les épisodes suivants pour les canons (Part 8.5 : Suppressor/Flash Hider) et les types de munitions (Part 14 : `AmmoTypes`) — c'est le système d'attachements central de toute la série.

## Part 8.5 — Fix du bug de mort définitif, refonte animations/son, 2e catégorie d'attachements

- **Vrai fix du bug de mort récurrent** : le script client du framework tournait dans `StarterPlayerScripts` (persiste à travers les morts, se retrouvait dans un état cassé). Déplacé vers `StarterCharacterScripts` → se réinitialise proprement à chaque nouveau personnage. **C'est le fix définitif** — les tentatives précédentes (Part 5, Part 6.5) n'étaient que des rustines.
- Réorganisation en tables `framework.animations.firstPerson` / `framework.animations.thirdPerson` + fonction utilitaire "stop all" — nettoie l'anti-superposition bricolée en Part 6.
- Animations troisième personne complétées (les autres joueurs voient enfin tir/reload correctement).
- **Refonte son** : nouveau `RemoteEvent "ItemVolley"` dédié, sons parentés à `Character.UpperTorso` de façon cohérente.
- **Attachements canon** (2e catégorie, réutilise le pattern de Part 8) : Suppressor, Flash Hider — `attachmentType` variable pour que le même code de menu gère plusieurs catégories.

## Part 9 — Suppresseur fonctionnel, viseur Red Dot réellement fonctionnel, level design

- Son de tir contextuel : `currentBarrelDevice` lu au moment de tirer pour choisir entre son normal et son étouffé.
- **Sprint en tirant** : `Humanoid.WalkSpeed` mis à une valeur "marche" (pas 0) pendant le tir plutôt que bloqué complètement.
- **Premier viseur vraiment fonctionnel** : image "reticle" positionnée en overlay GUI exactement sur le point rouge du viewmodel, visible seulement quand le sight équipé a `Transparency == 0` (boucle sur `viewModel.Attachments:GetDescendants()`).
- **Début du level design** : conseils donnés sur la structure en grille de chemins (central=risqué/sniper, latéraux=push, hauteur=multi-étages), greybox avant décoration, éviter le Toolbox pour un vrai jeu, dimensionner selon le nombre de joueurs visé.

## Part 10 — Couteau, grenades, impacts visuels

- Deux nouveaux flags d'item : `isMelee`, `isGrenade`.
- **Mêlée** : `melee(isLightStab)` → animation puis raycast ~10 studs (`RaycastParams` Exclude sur le personnage) → `Events.Melee:FireServer(isLightStab, damage, criticalDamage, origin, direction)` → dégâts appliqués serveur.
- **Impacts (bullet holes)** : part fine + decal, orientée via `CFrame.new(ray.Position, ray.Position - ray.Normal)`, auto-détruite après 10s (`Debris:AddItem`). Pas de trou si la cible a un `Humanoid` (juste dégâts).
- **Grenades** : `grenade()` joue une anim de lancer, attend un `AnimationEvent` sur une keyframe pour déclencher le vrai lancer, `Events.Grenade:FireServer(type, origin, direction)` → clone + vélocité + `task.wait(5)` → `Explosion` (blast radius). Un seul type ("Frag") mais structure extensible (`GrenadeType`).

## Part 10.5 — FastCast Redux, shotguns, flash/douilles en particules

- **Remplacement complet du système de "bullet physique" (Part 5.5)** par le module **FastCast Redux** (Toolbox) : `Caster = FastCast.new()`, `CasterBehavior` avec `RaycastParams` Exclude, `AutoIgnoreContainer = true`. Gère le temps de trajet réel et la chute de balle (`Acceleration = Vector3.new(0, -Workspace.Gravity/2, 0)`).
- Détection d'impact généralisée à **toutes les armes** (boucle sur les `ModuleScript` du dossier Weapons) au lieu d'être codée en dur par arme.
- **Shotguns** (`isShotgun`) : 6 pellets par clic, direction aléatoire par pellet (offset divisé par ~25-30 pour calibrer la dispersion).
- Tentative de douilles/flash au canon — laissée buguée volontairement, corrigée en Part 11.

## Part 11 — Fix orientation flash/douilles, système de recul

- **Root cause du bug de Part 10.5** : `Position`/`LookVector` ne peuvent pas être assignés directement à un `CFrame` — il faut passer par `CFrame.new(origin, direction)`. Une valeur `muzzleCFrame` du viewmodel est propagée client→serveur pour orienter correctement flash et douilles.
- Douilles avec vraie vélocité latérale + rotation aléatoire 3 axes.
- **Recul par pattern** (méthode recommandée) : table `Recoil = {Vector3.new(...), ...}` par arme (angles en `math.rad`), `currentRecoilCycle` incrémenté à chaque tir et bouclé (`% #module.Recoil + 1`), appliqué via `camera.CFrame *= CFrame.Angles(...)`. Alternative "aléatoire" mentionnée mais non détaillée.

## Part 12 — Modes de jeu (architecture OOP), HUD de match, teams

- **Fix frame-rate independent** (bug critique remonté par la communauté) : tout lerp calibré pour 60 FPS doit utiliser `1 - (1 - factor)^deltaTime` avec le `deltaTime` de `RenderStepped`, sinon casse à haut framerate (recoil/aim/head-bob).
- **Pattern OOP maison** (Roblox n'a pas de vraies classes) : `Module.__index = Module`, `Module.new(...)` retourne `setmetatable({}, Module)` avec des champs par défaut, méthodes définies sur la table du module. Utilisé pour `GameModeSystem` (name, limits, map) et `MapSystem`.
- 3 modes définis (Team Deathmatch, Capture the Flag, un 3e similaire), sélection aléatoire pondérée.
- **Boucle de match** : `Intermission` (~20s) → sélection mode/carte → `Starting...` (countdown) → match actif, en `while true do`.
- HUD "Gamemode" (état, scores, timer, kill feed) broadcast via boucle sur `Players:GetChildren()`.
- Teams Roblox réelles (Red/Blue) + `SpawnLocation` par couleur ; `leaderstats` (Kills/Deaths/Score).
- **Tracking kills/assists** : tag `Owner`/`Assist` posé sur le `PrimaryPart` de la victime à chaque coup ; à la mort, `Owner` +50 score/1 kill, `Assist` +25 score.

## Part 12.5 — Conditions de victoire, écran de victoire, kill feed

- `CheckWinners()` compare les totaux d'équipe aux limites du mode actif, retourne 0/1/2 — appelé à chaque tick du timer.
- Écran de victoire (`WinScreenRed`/`WinScreenBlue`) togglé pour tous, 5s avant de relancer le cycle.
- Kill feed via `RemoteEvent "Killed"` (`FireAllClients`), texte formaté selon 3 cas (kill simple / kill+assist / mort environnementale), auto-détruit après 5s.

## Part 13 — Hit markers, indicateur de dégâts, flash en particules, munitions

- **Hit markers** : module `HitMarker_System`, image "X" centrée, brève, rouge si headshot (sinon blanc), appelé server-side directement par chaque script d'arme.
- Indicateur de dégâts textuel (contour blanc pour lisibilité), affiché brièvement à chaque tir touché.
- **Refonte flash de canon en `ParticleEmitter`** (remplace le flash Part 10.5/11) : calibré, émis manuellement (`v:Emit(1)` sur chaque `ParticleEmitter`), nettoyé via sa propre `Lifetime` plutôt qu'un délai fixe.
- **Balle chambrée** (`isChambered`) : +1 balle si le chargeur était plein avant de vider (31 au lieu de 30).
- **Munitions de réserve** (`reserveAmmo`, distinct du chargeur `maxAmmo`) : recharge transfère un plein chargeur de la réserve, ou ce qu'il en reste si insuffisant — permet de vraiment tomber à sec.

## Part 14 — Fusil à pompe complet, crouch, types de munitions

- **M590 avec animations Blender custom** : 3 animations de rechargement distinctes (`ReloadEnter`, `ReloadShell` en boucle via `AnimationEvent`, `ReloadEnd`), calcul `ammoNeeded = maxAmmo - ammo` (+1 si chambré).
- Douille spécifique fusil à pompe (modèle différent, vélocité/rotation calibrées séparément).
- **Crouch** : animation dédiée, `RemoteEvent "CrouchToggle"`, `WalkSpeed` réduit, sprint désactivé, table `crouchTracks` pour centraliser les `AnimationTrack`.
- **Types de munitions** (`ammoType`) façon Call of Duty : réutilise le pattern générique d'attachements (Part 8) avec `attachmentType = "AmmoTypes"`, redéfinit dynamiquement les dégâts au tir.

## Part 15 — Viseur dynamique, traces de balles, fin des modes de jeu, changement de carte

⚠️ **Dernière vidéo de la playlist fournie, mais pas le dernier épisode de la série du créateur** — une vidéo finale (refonte OOP complète du framework, méthode `Destroy`) est annoncée mais n'est pas dans cette playlist.

- **Viseur dynamique** : intégration du module Toolbox "Dynamic Crosshair" (`Crosshair.new(hud):Enable()/:Disable()`), désactivé en ADS, spread min/max + vitesse d'augmentation/diminution par seconde, `crosshairSpread`/`crosshairAimSpread` par arme.
- Traces de balles implémentées (peu de détail capturé).
- **Modes de jeu finalisés** : cycle round complet testé en conditions réelles.
- **Changement de carte automatique** entre rounds : clone `ReplicatedStorage.Maps[gamemode.Map]`, parenté à `Workspace`, ancienne carte détruite.

---

## Patterns transversaux (valables sur toute la série)

- **`framework` = une seule grosse table Lua**, dupliquée en esprit entre client (`StarterPlayerScripts`/`StarterCharacterScripts`) et serveur (`ServerScriptService`), jamais un vrai objet partagé — toute donnée sensible (dégâts, ammo réelle) doit être validée côté serveur, le client n'est qu'affichage + intention.
- **Un `ModuleScript` par item** (arme, couteau, grenade) sous `ReplicatedStorage.Modules`, retournant une table `Settings` — c'est la config de l'item (animations, sons, dégâts, ammo, attachements...).
- **`RemoteEvent` par action** (Shoot, Melee, Grenade, CrouchToggle, Killed...) plutôt qu'un seul remote générique — plus simple à débugger mais plus verbeux.
- **Le système d'attachements générique** (table de noms + `attachmentType` + menu qui clone dynamiquement) introduit en Part 8 est réutilisé 3 fois (sights, barrel devices, ammo types) — c'est le pattern d'extensibilité le plus important de la série.
- **Le bug de "référence à l'ancien personnage après la mort" revient 3 fois** (Part 5, Part 6.5, fix définitif Part 8.5) — la leçon retenue : le script client doit vivre dans `StarterCharacterScripts` (pas `StarterPlayerScripts`) pour se réinitialiser proprement à chaque spawn.
- **Frame-rate independence** (Part 12) : tout lerp/smoothing doit utiliser `deltaTime`, jamais un facteur fixe — sinon ça casse dès que le framerate change (recoil, aim smoothing, head bob, crosshair).
- **FastCast Redux** (Part 10.5+) remplace le raycast/bullet-physique naïf dès que le jeu a besoin de plusieurs armes cohérentes, de chute de balle, ou de temps de trajet réaliste.
- **Pattern OOP maison** (Part 12) : `Module.__index = Module` + `.new()` — seule façon d'avoir de vraies "instances" en Luau sans framework externe.

---

*Vidéos analysées via transcript (captions YouTube natifs, ou Whisper/Groq en fallback pour Part 3) + échantillonnage de frames vidéo (Roblox Studio, code et gameplay) pour confirmation visuelle. Playlist : `PLWNYI4_6C0wthAguFMjzcPnXGvqwcTwbL`.*
