# Quarantine Regen — Design Document

Spécification complète fournie par l'auteur du projet, conservée ici comme référence de vérité pour l'implémentation. Ce document reflète l'intention de design ; il fait autorité en cas de doute sur une mécanique.

## 1. Concept général

- Mode infection : Humains armés contre Infectés en mêlée
- Pilier central : les Infectés régénèrent leur HP s'ils restent immobiles → pousse à chasser activement plutôt que camper
- Vue première personne pour tout le monde
- Style proche de Phantom Forces / Arsenal (hitscan, viewmodel FPS)

## 2. Structure d'une partie

- 4 joueurs minimum pour lancer, 16 maximum par serveur
- Une partie = 5 rounds consécutifs sur la même map
- Join possible tant que le Round 3 n'a pas commencé
- Nombre d'infectés recalculé à chaque round : 9+ joueurs = 2 infectés, 8 ou moins = 1
- Patient zéro : tirage au sort sans remise
- Flow d'un round : RoundStart → PreRound (30s) → InfectedSelection → InProgress (180s) → RoundEnd
- Victoire round : timer écoulé OU tous infectés éliminés (humains gagnent) ; tous humains infectés (infectés gagnent)
- Sous-effectif (<4) : partie continue normalement. 1 seul joueur restant : fin immédiate, retour Hub
- Infecté tué = mort définitive pour le round, spectateur (son camp seulement) jusqu'au round suivant
- Transition humain→infecté : délai 0.5s après la griffe

## 3. Scoring (classement fin de partie — DISTINCT de la monnaie de progression)

| Action | Points |
|---|---|
| Survivre le round entier (humain) | +100 |
| Kill infecté (coup final) | +50 |
| Assist infecté | +10 |
| Infection — 1ère du round | +50 |
| Infection — 2e du round | +40 |
| Infection — 3e du round | +30 |
| Infection — 4e++ | +25 |
| Par tranche de 20s survécu (humain) | +10 |

Assist : ≥20% des dégâts bruts cumulés, fenêtre glissante de 12s depuis le dernier coup de CET attaquant. Le killer touche toujours ses points peu importe sa propre fenêtre. Classement final = somme du score sur les 5 rounds.

## 4. Stats de base

| Stat | Humain | Infecté (base) |
|---|---|---|
| HP | 100 | 250 |
| Vitesse marche | 16 | 19.2 (×1.20) |
| Vitesse sprint | 22.4 (×1.4) | ~25 (×1.3) |
| Stamina max | 100 | 120 |
| Drain sprint | 20/s (5s max) | 15/s (8s max) |
| Régén stamina | 15/s | 20/s |

- 0 stamina = coupe simple du sprint
- Impossible de tirer/griffer/couteau en sprint
- Saut : coûte 10 stamina fixe, Humains seulement, impossible si stamina < 10 (JumpPower = 0)
- Crouch (touche C, maintenir) : vitesse à 35% de la normale, bloque le sprint, caméra abaissée ~2 studs avec transition fluide (lerp, pas de saut brusque)

## 5. Régénération (Infecté)

10% du HP max toutes les 3s d'immobilité. Seuil de mouvement toléré : 0.5 studs. Reset sur mouvement/dégâts reçus/tentative de griffe (même ratée). Mutagène Rapide : 15% au lieu de 10%.

## 6. Infection (griffe)

Action active (pas un contact passif). Portée 5 studs, cône de 45° devant l'infecté. Cooldown 1s entre attaques. Windup 0.25s avant vérification du hit. Impossible en sprint. Chaque tentative reset le minuteur de régén. Transition vers infecté : 0.5s après le coup.

## 7. Mutagènes (2 au lancement, GamePass Robux)

| Stat | Base | Rapide | Tank |
|---|---|---|---|
| HP | 250 | 200 | 400 |
| Vitesse marche | 19.2 | 22 (+15%) | 19.2 (inchangé) |
| Hitbox | Standard | Standard | +15% |
| Régén HP | 10%/3s | 15%/3s | 10%/3s |
| Stamina max | 120 | 120 | 100 |
| Régén stamina | 20/s | 25/s | 18/s |

Toujours un compromis (jamais un pur upgrade). Sélection en loadout pré-partie, appliquée automatiquement dès qu'infecté.

## 8. Armes humaines (5 au lancement, toutes gratuites)

Slots : 1=principale (AssaultRifle/Shotgun/MachineGun), 2=secondaire (Pistol/SMG), 3=couteau (toujours dispo), 4=explosif.

| Arme | Dégât/tir | Cadence | Chargeur | Rechargement | Calibre | Poids | Switch |
|---|---|---|---|---|---|---|---|
| Pistolet | 32 | 240 RPM | 12 | 1.5s | Petit | -5% | 0.3s |
| SMG | 26 | 600 RPM | 30 | 2s | Petit | -8% | 0.35s |
| Fusil d'assaut | 25 | 420 RPM | 30 | 2.5s | Petit | -12% | 0.45s |
| Fusil à pompe | 12.5 (bout portant, falloff) | 60 RPM | 6 | 3s | Gros | -15% | 0.5s |
| Mitrailleuse | 22.5 | 480 RPM | 75 | 4s | Gros | -30% | 0.7s |
| Couteau | 25 (PLACEHOLDER, jamais verrouillé) | mêlée (logique proche de la griffe) | — | — | Mêlée | 0% | 0.2s |

Headshot ×2. Falloff Fusil à pompe : 100% dégâts sous 10 studs → 20% à 40+ studs (dégradation linéaire entre les deux), pas implémenté sur les autres armes. Petit calibre = stoppe/ralentit l'infecté (10% vitesse pendant 0.3s). Gros calibre = knockback (2 studs Shotgun, 1 stud Mitrailleuse). TTK volontairement long (×4 vs premier jet) pour forcer le jeu en groupe. Impossible de tirer/recharger/griffer en sprint.

## 9. Attachments

- **Grips (4)** — spécialisation, jamais de malus : Vertical (-40% recul vertical), Angled (-40% recul horizontal + stabilisation plus rapide), Tactique (-25%/-25% + 20% supplémentaire accroupi), Léger (-25% vertical ET horizontal).
- **Magasines (3)** : Standard, Étendu (+50% capacité/+40% temps recharge), Rapide (-30% capacité/-40% temps recharge).
- **Skins** : cosmétique pur, débloqués via progression, aucun effet stats.

⚠️ Ces systèmes existent côté serveur (AttachmentSystem, SkinSystem) mais ne sont PAS exposés dans une UI — un joueur ne peut actuellement pas choisir de grip, magasine, ou skin.

## 10. Recul

Système client (kick de caméra), config par arme (RecoilConfig.lua), valeurs de départ jamais vraiment playtestées, à ajuster.

## 11. Explosifs (slot 4, un type choisi par joueur)

| Type | Qté/round | Dégâts | Déclenchement | Portée |
|---|---|---|---|---|
| Grenade | 2 | 60 | Lancée, explose après 2.5s (PLACEHOLDER) | — |
| Mine classique | 3 | 40 (cumulable si plusieurs explosent) | Automatique | 5 studs (proximité) |
| Claymore | 1 | 80 | Manuel (joueur déclenche) | 40 studs |

Recul 3 studs pour les trois types. Rayon d'explosion 10 studs (PLACEHOLDER, jamais verrouillé précisément). Auto-dégâts actifs (le poseur peut se blesser/tuer). Aucun tir ami. Stock reset à chaque round.

## 12. Chute (fall damage, Humains seulement)

0-50 studs (~4 étages) : aucun dégât. 50-130 studs : progressif (linéaire). 130+ studs : 100+ dégâts (mort quasi garantie). Infectés immunisés.

## 13. Safe Room

3 emplacements de clé prédéfinis (1 choisi aléatoirement par round). Activable (clé + porte) 90s après le début du round. La clé est un point d'interaction permanent — jamais retiré, chaque humain ne peut l'obtenir qu'une fois mais elle reste dispo pour tous les autres (anti-troll). Ouverture de porte : canal de 20s fixe et non-interruptible une fois lancé (continue même si le lanceur meurt/s'éloigne). Notification globale (Humains ET Infectés) au lancement. Reste ouverte après.

## 14. Vote de map

20s, couvre toute la partie (5 rounds sur la même map, pas un vote par round). Compteur de votes en temps réel. Changement de vote autorisé tant que le timer tourne. Égalité → tirage au sort. 2-3 maps prévues au lancement (actuellement noms placeholder : Map_Alpha/Beta/Gamma).

## 15. Matchmaking / Architecture Hub + Game

Architecture cible : Hub cherche une partie existante avec assez de place → sinon file d'attente MemoryStoreQueue → 4 joueurs min, 20s pour grossir le groupe (sauf si 16 atteint) → réserve un nouveau serveur Game, téléporte le groupe. C'est l'architecture retenue pour l'implémentation (voir plan de build), construite proprement depuis zéro plutôt que via un hack temporaire.

## 16. Party (conçu pour le Hub)

Max 4 joueurs. Invitation via une liste des joueurs du Hub avec bouton "Inviter" à côté de chaque nom (pas de clic direct sur le joueur en jeu — accessibilité mobile). Le leader clique "Jouer", tout le monde suit. Bloc indivisible en matchmaking. Promotion automatique d'un nouveau leader si besoin.

## 17. Progression (monnaie de déblocage, DISTINCTE du score de classement)

Points = 150 + ((17 - position) × 15) + floor(score de partie ÷ 2)

Seuls les joueurs présents à la fin de la partie touchent des points (anti-farming). Sert à débloquer vestes/skins.

## 18. Vestes (4, coûts jamais fixés)

| Veste | Effet |
|---|---|
| Vitesse | +10% vitesse marche et sprint |
| Endurance | +25% stamina max, +20% régén stamina |
| Blindée | +25 HP (125 total) |
| Tactique | -20% temps de rechargement |

Coûts actuellement à 999999 (impossibles à débloquer — placeholder volontaire).

## 19. Inventaire des systèmes (cible d'implémentation)

**Serveur — Systems (25) :** TeamManager, VestSystem, SkinSystem, MutagenSystem, StaminaSystem, CrouchSystem, InfectionSystem, RegenSystem, WeightSystem, DamageTracker, AttachmentSystem, WeaponSystem, SpectatorSystem, FallDamageSystem, ExplosiveSystem, KnifeSystem, ScoringSystem, RoundManager, SafeRoomSystem, MapVoteSystem, GameSessionManager, ProgressionSystem, LoadoutController, ServerRegistry (Hub), SessionRegistration

**Serveur — Data (1) :** DataStoreHandler

**Config partagé (5) :** WeaponConfig, WeaponAttachments, RecoilConfig, ViewmodelConfig, PlaceConfig

**Client (8) :** InputController, RecoilController, ViewmodelController, HUDController, SpectatorController, LoadoutUI, MapVoteUI, LobbyPromptUI

**Hub (8) :** ServerRegistry, PartySystem, MatchmakingQueue, MatchCoordinator, SessionRegistration, HubInit, PartyUI, MatchmakingUI

## 20. Éléments en suspens (placeholders à trancher plus tard)

| Système | Élément en suspens |
|---|---|
| VestSystem | Coûts des 4 vestes (999999) ; **effet/scope jamais décrit dans la spec d'origine — à clarifier** |
| WeaponAttachments (Skins) | Coûts de Camo/Or (999999) |
| WeaponConfig | Dégâts du Couteau (25, jamais verrouillé) |
| ExplosiveSystem | Rayon d'explosion (10 studs), mèche grenade (2.5s) |
| MutagenSystem | GamePass IDs (Rapide/Tank, placeholder 0) |
| PlaceConfig | HUB_PLACE_ID (0 — Hub pas encore publié) |
| SafeRoomSystem | Coordonnées clé/porte — dépendent du greybox/vraie map |
| MapVoteSystem | Liste de maps (noms génériques Alpha/Beta/Gamma) |
| RecoilConfig | Valeurs par arme — point de départ, jamais playtestées |
| WeaponSystem | Falloff seulement sur le Fusil à pompe pour l'instant |
| WeaponSystem | Anti-triche sur la direction de tir client à durcir |
| DataStoreHandler | Retry basique, pas de vrai backoff |

## 21. Idées mentionnées mais jamais construites

- Items de vitesse sur la map — renforcer le "freestyle running" vs jeu en groupe, jamais conçu en détail
- Vraie physique de grenade (roule/rebondit) au lieu d'une boule en ligne droite — piste pour plus tard
- Fusil à pompe multi-pellets (vrai spread) au lieu d'un hitscan unique — simplification volontaire pour le lancement
- Bonus de série / bonus de pression pour infectés — exploré puis abandonné au profit du système à paliers (50/40/30/25)
- Falloff de distance pour toutes les armes (pas juste Shotgun)
- Vraie coordination distribuée du matchmaking au-delà du prototype MemoryStoreQueue

## 22. Hors code

- Vraies maps (un greybox de test sert de référence pour aligner les coordonnées safe room)
- UI stylisée (tout est actuellement généré par code, sans habillage graphique)
- Modèles/animations d'armes complets (viewmodel FPS à faire)

---

*Voir `/root/.claude/plans/expressive-singing-zephyr.md` pour le plan d'implémentation technique (structure Rojo, séquence de phases) dérivé de ce document.*
