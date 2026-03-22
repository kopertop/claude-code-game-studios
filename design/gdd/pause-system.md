# Pause System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-21
> **Implements Pillar**: Pillar 1 — Your Journey, Your Pace

## Overview

The Pause System provides universal, instant game pause accessible from any state
-- combat, cutscenes, dialogue, Near-Death slow-mo, menus, everywhere. When paused,
all gameplay simulation freezes while UI remains interactive. This system exists to
enforce Pillar 1: the player's real life always takes priority over the game. A
solo game has no excuse for unpausable moments.

## Player Fantasy

The player should feel **completely in control of their time**. Doorbell rings
mid-boss-fight? Pause. Kid needs attention during a cutscene? Pause. Phone call
during a dramatic dialogue choice? Pause. The game waits for you, always. This is
the single most important difference between a solo game and an MMO -- and it
should feel effortless.

## Detailed Design

### Core Rules

**1. Universal Pause Trigger**
- Start button pauses the game in ALL input contexts (see Input System GDD)
- Pause is a toggle: Start once = pause, Start again = unpause
- Keyboard equivalent: Escape key

**2. What Freezes**
- `Engine.time_scale = 0.0` (freezes all physics, animation, timers, AI)
- Audio: gameplay audio pauses (SFX, ambient, music fades to low volume)
- Particles and VFX freeze in place
- Enemy AI completely stops
- Cooldowns, buffs, debuffs do NOT tick while paused
- Near-Death slow-mo timer (if active) freezes at current time_scale

**3. What Stays Active**
- UI rendering and navigation (pause menu is interactive)
- Input processing for menu navigation
- Settings changes (adjust audio/graphics while paused)
- Screenshot/photo mode (if implemented)

**4. Pause Menu**
When paused, a pause menu overlay appears with options:
- Resume
- Settings (audio, video, controls, accessibility)
- Quest Log (read-only)
- Map (read-only)
- Save Game (manual save)
- Exit to Main Menu

**5. Cutscene Pause**
- Cutscenes pause exactly where they are -- mid-animation, mid-dialogue
- Camera freezes, characters freeze, audio stops
- Subtitle text remains visible
- Resume continues from exact frame

**6. Near-Death Pause**
- If paused during Near-Death, time_scale was already 0.3
- Pause sets it to 0.0
- On unpause, time_scale returns to 0.3 (not 1.0) -- Near-Death persists
- Stored as: `pre_pause_time_scale` variable

**7. Auto-Pause Triggers**
- Controller disconnected (see Input System GDD)
- Window loses focus (PC -- configurable in Settings)
- Low battery warning (Switch/iPad -- configurable)

### States and Transitions

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Unpaused | Game start, Resume selected, Start pressed while paused | Pause triggered | Normal gameplay |
| Paused | Start pressed, auto-pause trigger | Resume, Start pressed | time_scale=0, pause menu visible |

Two states. One transition each way. Simplest system in the project.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Input System** | Upstream | Receives pause_toggled signal from Start button press. Also receives auto-pause signals (controller disconnect). |
| **All Gameplay Systems** | Downstream | Engine.time_scale = 0 freezes all systems using delta-based updates. |
| **Music System** | Downstream | Emits pause/unpause signal. Music fades to low volume, doesn't stop. |
| **SFX System** | Downstream | All gameplay SFX pause. Menu SFX remain active. |
| **Save/Load System** | Downstream | Pause menu provides manual save option. |
| **Settings System** | Downstream | Settings accessible from pause menu. |
| **HUD System** | Downstream | HUD hidden behind pause menu overlay. |

## Formulas

No formulas. This is a binary state system (paused/unpaused).

The only stored value is:
```
pre_pause_time_scale = Engine.time_scale  (captured on pause)
Engine.time_scale = pre_pause_time_scale  (restored on unpause)
```

This ensures Near-Death slow-mo (0.3) is preserved through a pause/unpause cycle.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Pause during Near-Death | Stores time_scale=0.3, sets to 0.0. Unpause restores 0.3. | Near-Death persists through pause |
| Pause during cutscene | Freezes on exact frame. Resume from same frame. | Pillar 1: always pausable |
| Double-tap Start quickly | First press pauses, second unpauses. No debounce issues. | Simple toggle |
| Pause during save | Save completes, then pauses. Never interrupt a save. | Data integrity |
| Pause during zone transition | Loading screen already blocks input. Pause queues for after load. | Can't pause a loading screen |
| Auto-pause + manual pause overlap | Both set paused=true. Unpause requires manual Start press (auto-pause condition clearing alone doesn't unpause). | Player must explicitly resume |
| Settings changed while paused | Applied immediately (audio/visual). Gameplay settings take effect on unpause. | Instant feedback for A/V settings |

## Dependencies

| System | Direction | Hard/Soft | Nature |
|--------|-----------|-----------|--------|
| **Input System** | Upstream | Hard | Cannot pause without receiving the pause signal |
| **All Gameplay** | Downstream | Hard | Engine.time_scale=0 freezes everything |
| **Music/SFX** | Downstream | Soft | Audio fade is nice but game works without it |
| **Save/Load** | Downstream | Soft | Save from pause menu is convenience, not required |
| **Settings** | Downstream | Soft | Settings access from pause is convenience |

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| MUSIC_PAUSE_VOLUME | 0.2 | 0.0-0.5 | Music volume while paused (0=mute, 0.5=half) |
| MUSIC_FADE_DURATION | 0.3s | 0.1-1.0s | How fast music fades on pause |
| AUTO_PAUSE_ON_FOCUS_LOSS | true | true/false | PC: pause when window loses focus |
| AUTO_PAUSE_ON_LOW_BATTERY | true | true/false | Mobile: pause on battery warning |

## Visual/Audio Requirements

| Event | Visual | Audio | Priority |
|-------|--------|-------|----------|
| Pause activated | Screen dims slightly, pause menu appears | Music fades to low, gameplay SFX stop | HIGH |
| Unpause | Dim fades, menu disappears | Music fades back up, gameplay SFX resume | HIGH |
| Auto-pause (disconnect) | "Controller Disconnected" overlay on top of pause menu | Warning chime | HIGH |

## UI Requirements

| Information | Location | Condition |
|-------------|----------|-----------|
| Pause menu options | Center screen overlay | Paused state |
| "PAUSED" indicator | Top center | Paused state |
| Controller disconnect notice | Above pause menu | Auto-pause from disconnect |

## Acceptance Criteria

- [ ] Start button pauses from ALL input contexts (combat, cutscene, dialogue, Near-Death, menu)
- [ ] Engine.time_scale = 0.0 when paused; all gameplay frozen
- [ ] Cooldowns, buffs, debuffs do NOT tick while paused
- [ ] Near-Death time_scale (0.3) preserved through pause/unpause cycle
- [ ] Cutscenes resume from exact frame after unpause
- [ ] Pause menu is navigable with gamepad
- [ ] Controller disconnect triggers auto-pause
- [ ] Save game accessible from pause menu
- [ ] Settings accessible and adjustable while paused
- [ ] Music fades to low volume (not silence) while paused
- [ ] Performance: pause/unpause transition < 1 frame (16ms)

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Should there be a "photo mode" accessible from pause? | UX Designer | Post-Alpha polish | Low priority but high player value |
| Should auto-pause on focus loss be default on all platforms or PC only? | UX Designer | During Settings System GDD | Console/mobile may handle differently |
