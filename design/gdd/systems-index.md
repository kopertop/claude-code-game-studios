# Systems Index: Realms of the Forgotten

> **Status**: Draft
> **Created**: 2026-03-21
> **Last Updated**: 2026-03-21
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Realms of the Forgotten is a solo third-person RPG with WoW-style ability rotation
combat, zone-based quest progression, deep class/mastery systems, unlimited
professions, and Witcher-style consequential choices. The game requires ~40 systems
spanning combat, progression, narrative, economy, persistence, UI, audio, and meta
categories. The core loop (combat rotation on gamepad) is the highest-risk system
and should be prototyped before full GDD authoring. All systems must be
controller-first (Pillar 5) and pausable (Pillar 1).

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Input System | Core | MVP | Designed | design/gdd/input-system.md | -- |
| 2 | Player Controller | Core | MVP | Designed | design/gdd/player-controller.md | Input System |
| 3 | Camera System | Core | MVP | Designed | design/gdd/camera-system.md | Input System, Player Controller |
| 4 | Pause System | Core | MVP | Designed | design/gdd/pause-system.md | -- |
| 5 | Scene/Zone Management | Core | MVP | Not Started | -- | Settings System, Pause System |
| 6 | Ability Rotation Combat | Gameplay | MVP | Not Started | -- | Player Controller, Camera, Health & Resource, Ability Database, Input, SFX |
| 7 | Health & Resource System | Gameplay | MVP | Designed | design/gdd/health-resource-system.md | Character Stats |
| 8 | Damage Calculation | Gameplay | MVP | Not Started | -- | Character Stats, Ability Database, Health & Resource |
| 9 | Status Effects | Gameplay | V.Slice | Not Started | -- | Health & Resource, Ability Database, Damage Calculation |
| 10 | Enemy AI | Gameplay | V.Slice | Not Started | -- | Player Controller, Scene/Zone Mgmt, Health & Resource, Ability Database |
| 11 | Loot & Drop Tables | Gameplay | V.Slice | Not Started | -- | Item Database, Inventory, Enemy AI |
| 12 | Gathering System | Gameplay | V.Slice | Not Started | -- | Item Database, Inventory, Scene/Zone Mgmt, Player Controller |
| 13 | Homestead Building | Gameplay | Full | Not Started | -- | Scene/Zone Mgmt, Item Database, Inventory, Profession & Crafting, Save/Load |
| 14 | Character Stats | Progression | MVP | Designed | design/gdd/character-stats.md | -- |
| 15 | Class & Mastery System | Progression | Alpha | Not Started | -- | Character Stats, Ability Database, Save/Load |
| 16 | Ability Database | Progression | MVP | Designed | design/gdd/ability-database.md | Character Stats, Item Database |
| 17 | Profession & Crafting | Progression | V.Slice | Not Started | -- | Item Database, Inventory, Gathering System |
| 18 | Recipe Discovery | Progression | Alpha | Not Started | -- | Profession & Crafting, Quest System |
| 19 | Item Database | Economy | MVP | Designed | design/gdd/item-database.md | -- |
| 20 | Inventory System | Economy | V.Slice | Not Started | -- | Item Database, Input System |
| 21 | NPC System | Economy | V.Slice | Not Started | -- | Scene/Zone Management, Item Database |
| 22 | Quest System | Narrative | V.Slice | Not Started | -- | Dialogue System, World-State Persistence, NPC System, Save/Load |
| 23 | Dialogue System | Narrative | V.Slice | Not Started | -- | NPC System, Input System |
| 24 | Cutscene System | Narrative | Alpha | Not Started | -- | Camera System, Dialogue System, Pause System, Music System |
| 25 | World-State Persistence | Narrative | V.Slice | Not Started | -- | Scene/Zone Management, NPC System |
| 26 | Save/Load System | Persistence | V.Slice | Not Started | -- | Character Stats, Inventory, World-State Persistence |
| 27 | Settings System | Persistence | Alpha | Not Started | -- | -- |
| 28 | HUD System | UI | V.Slice | Not Started | -- | Health & Resource, Ability Database, Combat, Input |
| 29 | Menu System | UI | Alpha | Not Started | -- | Inventory, Character Stats, Class & Mastery, Profession & Crafting, Settings |
| 30 | Map System | UI | Alpha | Not Started | -- | Scene/Zone Mgmt, Quest System, Travel System |
| 31 | Quest Journal UI | UI | Full | Not Started | -- | Quest System |
| 32 | Notification System | UI | Full | Not Started | -- | Character Stats, Class & Mastery, Profession & Crafting, Quest System |
| 33 | Music System | Audio | Alpha | Not Started | -- | Scene/Zone Management, Settings System |
| 34 | SFX System | Audio | MVP | Designed | design/gdd/sfx-system.md | Settings System |
| 35 | Tutorial/Onboarding | Meta | Full | Not Started | -- | Quest System, Combat, Ability Database, Cutscene System |
| 36 | Friendly NPC AI | Gameplay | Alpha | Not Started | -- | NPC System, Scene/Zone Mgmt, World-State Persistence |
| 37 | Pet System | Gameplay | Alpha | Not Started | -- | Player Controller, Enemy AI, Health & Resource, Save/Load |
| 38 | Collection System | Progression | Full | Not Started | -- | Item Database, Save/Load, Pet System, Travel System |
| 39 | Travel System | Gameplay | Alpha | Not Started | -- | Player Controller, Scene/Zone Management, Input System |
| 40 | Character Creator | Meta | Full | Not Started | -- | Player Controller, Save/Load, Menu System |

---

## Categories

| Category | Description | System Count |
|----------|-------------|-------------|
| **Core** | Foundation systems everything depends on | 5 |
| **Gameplay** | The systems that make the game fun | 9 |
| **Progression** | How the player grows over time | 5 |
| **Economy** | Resource creation and consumption | 3 |
| **Narrative** | Story and dialogue delivery | 4 |
| **Persistence** | Save state and continuity | 2 |
| **UI** | Player-facing information displays | 5 |
| **Audio** | Sound and music systems | 2 |
| **Meta** | Systems outside the core game loop | 5 |

---

## Priority Tiers

| Tier | Definition | System Count | Target Milestone |
|------|------------|-------------|------------------|
| **MVP** | Required for core loop: 1 class, 1 zone, gamepad combat, basic crafting, pause | 12 (+3 partial) | First playable prototype |
| **Vertical Slice** | Complete session experience: quests, dialogue, save/load, full combat | 12 | Playable demo |
| **Alpha** | Multiple zones/classes, pets, travel, cutscenes, mastery trees | 10 | Feature-complete rough |
| **Full Vision** | Homestead, collections, tutorial, character creator, polish | 8 | Ongoing live service |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Input System** -- gamepad mapping is the bedrock; everything reads input
2. **Pause System** -- must be architecturally present from day one
3. **Item Database** -- data definitions referenced by combat, crafting, inventory, loot
4. **Character Stats** -- core attributes that combat, mastery, and scaling derive from
5. **Settings System** -- graphics/audio/controls needed for multi-platform

### Core Layer (depends on Foundation)

1. **Player Controller** -- depends on: Input System
2. **Camera System** -- depends on: Input System, Player Controller
3. **Scene/Zone Management** -- depends on: Settings System, Pause System
4. **Health & Resource System** -- depends on: Character Stats
5. **Ability Database** -- depends on: Character Stats, Item Database
6. **SFX System** -- depends on: Settings System
7. **Music System** -- depends on: Scene/Zone Management, Settings System

### Feature Layer (depends on Core)

1. **Ability Rotation Combat** -- depends on: Player Controller, Camera, Health & Resource, Ability Database, Input, SFX
2. **Damage Calculation** -- depends on: Character Stats, Ability Database, Health & Resource
3. **Status Effects** -- depends on: Health & Resource, Ability Database, Damage Calculation
4. **Enemy AI** -- depends on: Player Controller, Scene/Zone Mgmt, Health & Resource, Ability Database
5. **Inventory System** -- depends on: Item Database, Input System
6. **NPC System** -- depends on: Scene/Zone Management, Item Database
7. **Dialogue System** -- depends on: NPC System, Input System
8. **World-State Persistence** -- depends on: Scene/Zone Management, NPC System
9. **Friendly NPC AI** -- depends on: NPC System, Scene/Zone Mgmt, World-State Persistence
10. **Travel System** -- depends on: Player Controller, Scene/Zone Management, Input System

### Advanced Feature Layer (depends on Feature)

1. **Loot & Drop Tables** -- depends on: Item Database, Inventory, Enemy AI
2. **Gathering System** -- depends on: Item Database, Inventory, Scene/Zone Mgmt, Player Controller
3. **Class & Mastery System** -- depends on: Character Stats, Ability Database, Save/Load
4. **Profession & Crafting** -- depends on: Item Database, Inventory, Gathering System
5. **Recipe Discovery** -- depends on: Profession & Crafting, Quest System
6. **Quest System** -- depends on: Dialogue System, World-State Persistence, NPC System, Save/Load
7. **Cutscene System** -- depends on: Camera System, Dialogue System, Pause System, Music System
8. **Pet System** -- depends on: Player Controller, Enemy AI, Health & Resource, Save/Load
9. **Homestead Building** -- depends on: Scene/Zone Mgmt, Item Database, Inventory, Profession & Crafting, Save/Load
10. **Save/Load System** -- depends on: Character Stats, Inventory, World-State Persistence

### Presentation Layer (wraps gameplay systems)

1. **HUD System** -- depends on: Health & Resource, Ability Database, Combat, Input
2. **Menu System** -- depends on: Inventory, Character Stats, Class & Mastery, Profession & Crafting, Settings
3. **Map System** -- depends on: Scene/Zone Mgmt, Quest System, Travel System
4. **Quest Journal UI** -- depends on: Quest System
5. **Notification System** -- depends on: Character Stats, Class & Mastery, Profession & Crafting, Quest System

### Polish Layer (depends on everything)

1. **Tutorial/Onboarding** -- depends on: Quest System, Combat, Ability Database, Cutscene System
2. **Collection System** -- depends on: Item Database, Save/Load, Pet System, Travel System
3. **Character Creator** -- depends on: Player Controller, Save/Load, Menu System

---

## Recommended Design Order

| Order | System | Priority | Layer | Est. Effort |
|-------|--------|----------|-------|-------------|
| 1 | Input System | MVP | Foundation | S |
| 2 | Character Stats | MVP | Foundation | M |
| 3 | Item Database | MVP | Foundation | M |
| 4 | Pause System | MVP | Foundation | S |
| 5 | Player Controller | MVP | Core | M |
| 6 | Camera System | MVP | Core | S |
| 7 | Health & Resource System | MVP | Core | M |
| 8 | Ability Database | MVP | Core | L |
| 9 | SFX System | MVP | Core | S |
| 10 | Scene/Zone Management | MVP | Core | L |
| 11 | Damage Calculation | MVP | Feature | M |
| 12 | Ability Rotation Combat | MVP | Feature | L |
| 13 | Enemy AI | V.Slice | Feature | L |
| 14 | Inventory System | V.Slice | Feature | M |
| 15 | NPC System | V.Slice | Feature | M |
| 16 | Dialogue System | V.Slice | Feature | M |
| 17 | World-State Persistence | V.Slice | Feature | L |
| 18 | Save/Load System | V.Slice | Persistence | L |
| 19 | Status Effects | V.Slice | Feature | M |
| 20 | Loot & Drop Tables | V.Slice | Adv. Feature | M |
| 21 | Gathering System | V.Slice | Adv. Feature | S |
| 22 | Profession & Crafting | V.Slice | Adv. Feature | L |
| 23 | Quest System | V.Slice | Adv. Feature | L |
| 24 | HUD System | V.Slice | Presentation | M |
| 25 | Class & Mastery System | Alpha | Adv. Feature | L |
| 26 | Cutscene System | Alpha | Adv. Feature | M |
| 27 | Settings System | Alpha | Foundation | S |
| 28 | Music System | Alpha | Core | M |
| 29 | Friendly NPC AI | Alpha | Feature | M |
| 30 | Pet System | Alpha | Adv. Feature | L |
| 31 | Travel System | Alpha | Feature | M |
| 32 | Recipe Discovery | Alpha | Adv. Feature | S |
| 33 | Menu System | Alpha | Presentation | L |
| 34 | Map System | Alpha | Presentation | M |
| 35 | Homestead Building | Full | Adv. Feature | L |
| 36 | Quest Journal UI | Full | Presentation | S |
| 37 | Notification System | Full | Presentation | S |
| 38 | Tutorial/Onboarding | Full | Polish | M |
| 39 | Collection System | Full | Polish | M |
| 40 | Character Creator | Full | Polish | M |

Effort estimates: S = 1 session, M = 2-3 sessions, L = 4+ sessions.
A "session" is one focused design conversation producing a complete GDD.

---

## Circular Dependencies

- **Combat <-> Enemy AI**: Combat needs enemy targets; Enemy AI uses combat
  mechanics. **Resolution**: Define a shared combat interface. Design Combat
  first with a "dummy target" pattern, then Enemy AI implements the interface.

- **Quest System <-> World-State Persistence**: Quests change world state;
  world state gates quest availability. **Resolution**: World-State is the
  data layer (generic flag system). Quest System reads and writes flags.
  Design World-State first, Quest System uses it.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Ability Rotation Combat | Design | Gamepad rotation UX is unproven — WoW's system was designed for mouse+keyboard | Prototype FIRST before full GDD; test FFXIV cross-hotbar vs ESO 5-slot vs custom |
| Scene/Zone Management | Technical | World streaming on Switch (2GB RAM) and iPad requires aggressive LOD | Prototype with worst-case zone size; measure early |
| World-State Persistence | Scope | Branching choices multiply authoring and testing surface combinatorially | Start with binary flags per zone; expand incrementally |
| Item Database | Technical | Schema affects every downstream system; changes are expensive | Design schema carefully with versioning; prototype serialization early |
| Save/Load System | Technical | Must serialize complex world state, inventory, mastery, homestead | Prototype with worst-case save file; test on all platforms |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 40 |
| Design docs started | 9 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 9/12 |
| Vertical Slice systems designed | 0/12 |

---

## Next Steps

- [ ] Review and approve this systems enumeration
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [ ] Start with Input System (design order #1) or prototype Combat first (highest risk)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype the combat rotation on gamepad early (`/prototype combat`)
