# Scene/Zone Management

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-22
> **Implements Pillar**: Foundation for all pillars (zones are where everything happens)

## Overview

The Scene/Zone Management system handles loading, unloading, and transitioning
between game zones. Each zone is a separate Godot scene (PackedScene) loaded in
its entirety via loading screens. The system manages zone metadata (suggested
Power Level, world-state flags, gear slot focus), spawn points, transition
volumes, and the loading screen itself. It is designed for indefinite zone
expansion -- new zones are new scene files with a metadata Resource, requiring
no changes to existing zone code.

## Player Fantasy

The player should feel like they're entering a **new chapter of an epic story**
every time they transition to a new zone. Loading screens are not downtime --
they're anticipation builders with zone art, lore teasers, and gameplay tips.
Arriving in a new zone should feel like stepping off the boat in WoW's Howling
Fjord or walking through the gates of Whiterun -- a moment of wonder. The
system should be invisible in its mechanics and memorable in its presentation.

## Detailed Design

### Core Rules

**1. Zone as Scene**
- Each zone is a single Godot PackedScene (.tscn) containing all geometry, NPCs,
  enemies, interactables, gathering nodes, lighting, and ambient audio
- Zones are self-contained -- no shared scene tree between zones
- Only ONE zone is loaded at a time (no adjacent zone streaming)
- Zone scenes are stored in `assets/zones/[zone_name]/`

**2. Zone Metadata Resource**

Each zone has a `ZoneData` Resource (.tres) defining:

| Property | Type | Description |
|----------|------|-------------|
| `zone_id` | String | Unique identifier (e.g., `"ashenvale"`) |
| `zone_name` | String | Display name (e.g., "The Ashen Vale") |
| `zone_description` | String | Lore description for loading screen |
| `zone_tier` | int | Power level tier (determines item stat budgets) |
| `suggested_power_level_min` | int | Minimum recommended PL |
| `suggested_power_level_max` | int | Maximum before zone trivializes |
| `gear_focus_slots` | Array[Enum] | Which gear slots this zone rewards |
| `legendary_slot` | Enum | Which slot the zone completion Legendary fills |
| `loading_screen_art` | Texture | Art displayed during loading |
| `loading_screen_tips` | Array[String] | Random gameplay tips shown while loading |
| `zone_music_id` | String | Music track for this zone |
| `spawn_points` | Array[SpawnPoint] | Named spawn locations within the zone |
| `transition_targets` | Dict{String: ZoneTransition} | Where each exit leads |
| `world_state_flags` | Array[String] | Flags this zone reads/writes for state |
| `is_hub_zone` | bool | Is this a town/safe zone? (no enemies, has Cleric) |

**3. Zone Transitions**
- Transition volumes are Area3D nodes placed at zone edges, cave entrances,
  portals, etc.
- When player enters a transition volume, transition is triggered:
  1. Save current game state (auto-save before transition)
  2. Fade screen to black
  3. Show loading screen (zone art + tips + progress bar)
  4. Unload current zone scene
  5. Load target zone scene
  6. Place player at target spawn point
  7. Apply world-state flags to zone (NPC states, quest states, visual changes)
  8. Fade from loading screen to gameplay
- Total loading target: < 5 seconds on PC, < 10 seconds on Switch

**4. Spawn Points**
- Each zone has multiple named spawn points (entrances, waypoints, quest locations)
- Player spawns at the appropriate point based on:
  - Which transition they used (entrance from Zone A vs Zone B)
  - Fast travel target (waypoint selected from map)
  - Respawn after death (nearest discovered waypoint)
- Spawn points double as waypoints for fast travel (Travel System)
- Waypoints are discovered by physically visiting them (first visit unlocks)

**5. World-State Integration**
- On zone load, the system reads world-state flags from the Save/Load system
- Flags determine: NPC presence/absence, quest availability, visual changes
  (village rebuilt vs. destroyed), dialogue variations
- The zone scene has conditional branches controlled by flags
- Example: `flag "village_saved" == true` → show rebuilt village mesh, spawn
  grateful NPCs. `false` → show ruins, spawn scavenger NPCs.

**6. Zone Registry**
- A `ZoneRegistry` singleton holds all ZoneData Resources
- Provides lookup by zone_id, zone_tier, connection map
- The world map reads from ZoneRegistry to display available zones
- New zones added by creating a new ZoneData Resource + scene file

**7. Hub Zones (Towns)**
- Hub zones have `is_hub_zone = true`
- No enemies spawn in hub zones
- Hub zones contain: Cleric (respec), vendors, quest givers, crafting stations,
  mailbox/storage (future), and fast travel waypoints
- Hub zones are typically smaller and load faster
- Each major zone has at least one associated hub

**8. Expandability**
- New zones: create new .tscn scene + ZoneData Resource. Add transition volumes
  in existing zones pointing to the new zone. No code changes.
- New zone types (dungeons, arenas, instances): subclass ZoneData if needed
- Zone visual updates: modify the .tscn scene. ZoneData metadata unchanged.
- New world-state branches: add new flags to zone's world_state_flags array

### States and Transitions

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Zone Active | Zone loaded, gameplay running | Transition triggered, quit | Normal gameplay |
| Transitioning | Player enters transition volume or fast travel | Target zone loaded | Auto-save, fade out, loading screen, load zone, fade in |
| Loading Screen | Unload complete, load started | Load complete | Show art, tips, progress bar. Input disabled except pause. |
| Main Menu | Game start, exit to menu | "Continue" or "New Game" selected | No zone loaded |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Pause System** | Upstream | Pause during loading screen pauses the load progress (or not -- loading continues, UI pauses). |
| **Settings System** | Upstream | Graphics quality affects LOD, draw distance within zones. |
| **Player Controller** | Peer | Player position triggers transition volumes. Player placed at spawn point on zone load. |
| **World-State Persistence** | Both | Reads flags on zone load to configure zone. Writes flags on quest completion/choices. |
| **Save/Load System** | Both | Auto-save triggered before transition. Zone ID + spawn point saved for session resume. |
| **Travel System** | Upstream | Fast travel triggers zone transition to target waypoint. |
| **Music System** | Downstream | Zone load triggers zone music change (zone_music_id). |
| **Enemy AI** | Downstream | Enemies spawned per zone scene. Zone tier affects enemy scaling. |
| **NPC System** | Downstream | NPCs placed in zone scene. World-state flags control presence. |
| **Gathering System** | Downstream | Gathering nodes placed in zone scene. |
| **Map System** | Downstream | ZoneRegistry provides zone list, connections, waypoints for world map. |
| **Item Database** | Indirect | Zone tier feeds into item stat budget formula. |
| **Character Stats** | Indirect | Zone suggested PL used for difficulty ratio. |

## Formulas

### Loading Time Budget

```
target_load_time = ZONE_SIZE_MB / LOAD_SPEED_MBps
```

| Platform | Target Load Speed | Max Zone Size | Target Load Time |
|----------|------------------|--------------|-----------------|
| PC | 200 MB/s (SSD) | 500 MB | < 3 seconds |
| iPad | 100 MB/s | 300 MB | < 3 seconds |
| Switch | 50 MB/s | 200 MB | < 5 seconds |

Zone size budgets enforce performance constraints per platform.

### Zone Difficulty (from Character Stats GDD)

```
difficulty_ratio = player_power_level / zone_suggested_level
```

| Ratio | Experience |
|-------|-----------|
| < 0.8 | Underleveled, high risk |
| 0.8 - 1.2 | Appropriate challenge |
| 1.2 - 2.0 | Overpowered, easier |
| > 2.0 | Trivial (power fantasy) |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player dies during zone transition | Not possible -- transition auto-saves and player is safe during loading | Loading screen is a safe state |
| Game crash during zone load | On restart, load from auto-save (pre-transition). Player is in previous zone. | Auto-save is the safety net |
| Zone scene file corrupted/missing | Error screen: "Zone could not be loaded." Return to last hub zone. | Graceful failure, don't crash |
| Player enters transition during combat | Combat ends (enemies deaggro/despawn). Transition proceeds. | No combat lockout on zone exit |
| Two transition volumes overlapping | First entered takes priority. Second is ignored until first transition completes. | Prevent double-load |
| Fast travel to undiscovered waypoint | Not allowed -- only discovered waypoints are selectable. | Must visit first to unlock |
| Zone loaded but world-state flag missing | Default to false (conservative state). Log warning for debugging. | New flags added in updates shouldn't crash old saves |
| Player returns to zone after world-state change | Zone reloads with new flags. Changed NPCs, visuals, quests reflected. | World remembers choices |
| Switch memory pressure during large zone | Aggressive LOD, reduced draw distance. Zone size budgeted per platform. | Performance budgets in technical preferences |

## Dependencies

| System | Direction | Hard/Soft | Nature |
|--------|-----------|-----------|--------|
| **Pause System** | Upstream | Hard | Must pause loading screen UI on pause |
| **Settings System** | Upstream | Soft | Graphics quality. Uses defaults without. |
| **Player Controller** | Peer | Hard | Transition volumes need player position. Spawn placement. |
| **World-State Persistence** | Both | Soft | Flags configure zone. Works without (default state). |
| **Save/Load System** | Both | Hard | Auto-save on transition. Zone ID persisted for resume. |
| **Travel System** | Upstream | Soft | Fast travel triggers transitions. Zones work without fast travel. |
| **Music System** | Downstream | Soft | Zone music trigger. Works silent. |
| **Enemy AI** | Downstream | Soft | Enemies are in the zone scene. Zone loads without enemies (just empty). |
| **NPC System** | Downstream | Soft | NPCs in zone scene. |
| **Map System** | Downstream | Soft | ZoneRegistry provides map data. |

## Tuning Knobs

| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| LOADING_FADE_DURATION | 0.5s | 0.2-1.5 | Longer = smoother fade, slower feel |
| MIN_LOADING_SCREEN_TIME | 2.0s | 0.0-5.0 | Minimum time to show loading screen (prevents flash-loads from feeling jarring) |
| MAX_ZONE_SIZE_MB | 200 (Switch) | 100-500 | Larger = more detail, longer loads |
| AUTO_SAVE_ON_TRANSITION | true | bool | Disable to skip auto-save (debug only) |
| SPAWN_POINT_DISCOVER_RADIUS | 10.0m | 5-20 | How close to walk to unlock a waypoint |

## Visual/Audio Requirements

| Event | Visual | Audio | Priority |
|-------|--------|-------|----------|
| Transition start | Screen fades to black | Fade-out whoosh | HIGH |
| Loading screen | Zone art, random tip, progress bar | Ambient/quiet music or silence | HIGH |
| Transition complete | Fade from black to gameplay | Zone music starts, ambient fades in | HIGH |
| Waypoint discovered | Waypoint pillar/marker activates, glow effect | Discovery chime | MEDIUM |
| Zone entered (first time) | Zone name + subtitle displays ("The Ashen Vale — Tier 3") | Dramatic zone entrance music sting | HIGH |

## UI Requirements

| Information | Location | Condition |
|-------------|----------|-----------|
| Loading screen art | Full screen | During transition |
| Loading progress bar | Bottom of loading screen | During transition |
| Gameplay tip | Center-bottom of loading screen | During transition |
| Zone name + tier | Top center of screen (fades after 5s) | On zone enter |
| Suggested Power Level | Below zone name on enter | On zone enter |
| "Zone too dangerous!" warning | Screen overlay | PL < 0.6 * zone suggested min |

## Acceptance Criteria

- [ ] Zone loads as complete PackedScene via loading screen
- [ ] Only ONE zone loaded at a time -- previous zone fully unloaded
- [ ] Loading screen shows zone art, tips, and progress bar
- [ ] Load time < 5s on PC, < 10s on Switch for max-size zones
- [ ] Transition volumes trigger zone change when player enters
- [ ] Player spawns at correct spawn point based on transition source
- [ ] Auto-save triggers before every zone transition
- [ ] World-state flags correctly configure zone on load (NPC presence, visuals)
- [ ] Waypoints discoverable by proximity (SPAWN_POINT_DISCOVER_RADIUS)
- [ ] Fast travel triggers zone transition to target waypoint
- [ ] ZoneRegistry provides correct zone data for map and UI
- [ ] New zones addable via scene file + ZoneData Resource without code changes
- [ ] Hub zones have no enemies and contain Cleric, vendors, quest givers
- [ ] Memory usage stays within 2GB ceiling on Switch during any zone
- [ ] Draw calls stay under 500 in any zone
- [ ] Graceful failure if zone file is missing (return to hub, no crash)

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Should dungeons be separate zones or sub-areas within zones? | Level Designer | During zone content design | Separate zones = simpler loading. Sub-areas = more seamless dungeon entrance. |
| Instanced zones for repeatable content? | Game Designer | Post-Alpha | If players want to replay zones, do they get a "fresh" instance? Or is the world persistent? |
| Background loading / preloading adjacent zones? | Gameplay Programmer | During optimization pass | Could reduce load times by preloading likely next zones |
| Should loading screens be interactive? (mini-game, ability practice) | UX Designer | Post-Alpha polish | Low priority but high player value during long Switch loads |
| How large should MVP Zone 1 be? | Level Designer | During prototype phase | Need to test performance with a real zone before committing to scale |
