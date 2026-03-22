# Input System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-21
> **Implements Pillar**: Pillar 5 — Couch-Ready Controller Experience

## Overview

The Input System is the foundational layer that translates physical controller
inputs into game actions. It owns gamepad button mapping, action binding, modifier
states (for ability bar access), input remapping, and input context switching
(e.g., combat vs. menu vs. dialogue). Every system that responds to player input
-- combat, movement, UI navigation, crafting -- reads from the Input System's
action bindings rather than polling raw hardware directly. This system exists to
enforce Pillar 5 (controller-first design) at the architectural level: if Input
doesn't support it on a gamepad, it doesn't ship.

## Player Fantasy

The player should never think about the Input System. When it's working, every
action feels instant, natural, and precisely where they expect it on the
controller. The fantasy is **effortless mastery** -- the controller becomes an
extension of the player's intent. Pressing a button should feel like *casting a
spell*, not *pressing a button*. The ability bar modifier system should feel like
second nature within 10 minutes, the way FFXIV players instinctively hold L2+R2
without thinking about it. If the player ever consciously thinks "how do I do X?",
the Input System has failed.

## Detailed Design

### Core Rules

**1. Action Binding Architecture**

All input flows through Godot's InputMap system, extended with a custom modifier
layer. No system ever reads raw button presses -- everything goes through named
actions.

**2. Input Contexts**

The system uses input contexts to determine which bindings are active. Only one
primary context is active at a time:

| Context | When Active | What Changes |
|---------|------------|--------------|
| Exploration | Moving through world, no menu open | Full movement + ability access |
| Combat | Enemy engaged (auto-detected via aggro) | Same as Exploration but dodge prioritized |
| Near-Death | HP drops below 15% during Combat | Time dilation ~30%, quick items at full speed, abilities at slow-mo speed |
| Menu | Any menu/inventory/character screen open | Face buttons navigate UI, triggers scroll, d-pad moves cursor |
| Dialogue | NPC conversation active | Face buttons select choices, triggers scroll, B=back |
| Cutscene | Cutscene playing | Start=pause, B=skip prompt, all else disabled |
| Crafting | Crafting station active | Hybrid: d-pad navigates recipes, face buttons confirm/cancel |
| Dead | HP reaches 0 | Respawn options only: D-pad navigates, A confirms |

**3. Gamepad Layout -- Exploration/Combat Context**

Base (no modifier held):
- **Left Stick**: Movement (8-directional, analog sensitivity)
- **Right Stick**: Camera control
- **A**: Interact / Confirm (context-sensitive)
- **B**: Dodge / Roll
- **X**: Basic Attack (auto-targets nearest)
- **Y**: Context Action (loot, mount, gather -- changes with proximity)
- **D-Pad Up**: Toggle quest tracker
- **D-Pad Down**: Toggle mount
- **D-Pad Left**: Quick item slot 1 (health potion)
- **D-Pad Right**: Quick item slot 2 (mana/resource potion)
- **L1**: Target lock toggle (soft lock-on)
- **R1**: Cycle targets
- **L3 (stick click)**: Sprint toggle
- **R3 (stick click)**: Center camera behind player
- **Start**: Pause (universal, works everywhere including cutscenes)
- **Select/Back**: Open main menu

R2 Held (Primary Ability Bar -- 4 slots):
- **R2 + A**: Ability Slot 1
- **R2 + B**: Ability Slot 2
- **R2 + X**: Ability Slot 3
- **R2 + Y**: Ability Slot 4

L2 Held (Secondary Ability Bar -- 4 slots):
- **L2 + A**: Ability Slot 5
- **L2 + B**: Ability Slot 6
- **L2 + X**: Ability Slot 7
- **L2 + Y**: Ability Slot 8

R2 + D-Pad (Utility Abilities -- 4 slots):
- **R2 + D-Up**: Ability Slot 9
- **R2 + D-Down**: Ability Slot 10
- **R2 + D-Left**: Ability Slot 11
- **R2 + D-Right**: Ability Slot 12

L2 + D-Pad (Defensive/Misc Abilities -- 4 slots):
- **L2 + D-Up**: Ability Slot 13
- **L2 + D-Down**: Ability Slot 14
- **L2 + D-Left**: Ability Slot 15
- **L2 + D-Right**: Ability Slot 16

**Total ability slots**: 16 (expandable via future double-tap modifiers if needed).

**4. Modifier Behavior Rules**
- Holding L2/R2 does NOT fire abilities immediately -- the trigger is the
  face button or d-pad press while held
- L2/R2 analog value threshold: below 50% = not held (allows light resting
  on triggers without accidental activation)
- If L2 and R2 are both held simultaneously, R2 takes priority (primary bar)
- Releasing L2/R2 after pressing a face button does NOT cancel the ability
- Ability input is queued: if a button is pressed during a GCD (global cooldown),
  the ability fires as soon as the GCD ends (max 1 queued input)

**5. Near-Death Context**
- Triggered when Health & Resource System signals HP < 15% threshold
- Time dilation: game speed reduced to ~30% (Engine.time_scale = 0.3)
- Quick item inputs (D-Pad Left, D-Pad Right) process at **real-time speed**
  -- potion use is instant regardless of slow-mo
- Ability inputs still work but cast at slow-mo speed -- potions are the clear
  survival action
- Movement and dodge still functional at slow-mo speed
- Visual: screen edge vignette, desaturation, heartbeat audio cue
- **Persists indefinitely** until HP rises above 15% (slow-mo ends, time snaps
  back to normal) OR HP reaches 0 (transition to Dead state)
- No arbitrary timer -- the player stays in slow-mo as long as they are in danger
- If player heals above 15%, a brief "time snap" effect plays (0.2s ease-out
  from 30% to 100% speed) so the transition feels smooth

**6. Dead Context**
- Triggered when HP reaches 0
- Screen dims, camera pulls back
- Respawn options presented:
  - **Respawn at Waypoint** (free, always available) -- teleport to nearest
    discovered waypoint with full HP
  - **Use Respawn Potion** (consumable item required) -- revive in place with
    50% HP, brief invulnerability window (3s)
- D-pad navigates options, A confirms
- If no Respawn Potion in inventory, that option is grayed out
- No XP loss, no item loss, no corpse run -- death is a setback, not punishment

**7. Input Remapping**
- All bindings are remappable via Settings menu
- Remapping UI uses "press the button you want" paradigm
- Presets available: "Default", "FFXIV-like", "ESO-like"
- Modifier assignment is remappable (swap L2/R2 roles)
- Quick item slot assignment is remappable
- Remapping persists in save file per-character

**8. Keyboard/Mouse Fallback**
- Full keyboard/mouse support as secondary input method
- Traditional hotbar (1-0, Shift+1-0) for keyboard users
- Mouse click-to-move NOT supported (controller-first, but keyboard supported)
- Input method auto-detected: UI prompts switch between controller icons and
  keyboard icons based on last input device used
- Switching between controller and keyboard mid-session is seamless

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Exploration | Default state, no combat/menu/dialogue | Combat/menu/dialogue/cutscene triggers | Full movement + all abilities |
| Combat | Enemy aggro triggered | All enemies dead or deaggro | Same as Exploration, dodge prioritized, target lock available |
| Near-Death | HP < 15% during Combat | HP rises above 15% OR HP reaches 0 | Time dilation ~30%, quick items at full speed, abilities at slow-mo speed. Persists indefinitely. |
| Menu | Select/Back pressed or menu opened | B pressed or menu closed | Navigation mode, abilities disabled |
| Dialogue | NPC interaction started | Dialogue ends or B to exit | Choice selection mode |
| Cutscene | Cutscene triggered | Cutscene ends | Only pause (Start) and skip prompt (B) |
| Crafting | Crafting station interaction | B to exit or craft complete | Hybrid navigation + confirm |
| Dead | HP reaches 0 | Respawn option selected | Respawn UI: Waypoint (free) or Respawn Potion (consumable). D-pad + A. |

**Transition rules:**
- Transitions are instant -- no transition animation or delay on input context switches
- Near-Death can only be entered FROM Combat (not from Exploration -- no enemies = no danger)
- Dead can be entered from Combat or Near-Death
- Menu can be opened from any non-Dead, non-Cutscene state (opens over gameplay, pauses game)
- Pause (Start) works in ALL states including cutscenes and Near-Death slow-mo

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Player Controller** | Downstream | Input emits movement vector (Vector2) and action signals (dodge, interact, jump, sprint). Player Controller reads these to move the character. |
| **Camera System** | Downstream | Input emits camera stick vector (Vector2), target lock toggle, and cycle target signals. Camera reads these. |
| **Ability Rotation Combat** | Downstream | Input emits ability slot activation signals (slot_1_pressed through slot_16_pressed). Combat reads slot-to-ability mapping from Ability Database. |
| **Health & Resource System** | Upstream | Health system emits hp_threshold_crossed signal when HP drops below or rises above 15%. Input System uses this to enter/exit Near-Death context. |
| **Inventory System** | Downstream | In Menu context, Input emits navigation signals. In any context, D-Pad Left/Right emit quick_item_use signals. |
| **Dialogue System** | Downstream | In Dialogue context, Input emits choice selection signals. |
| **HUD System** | Downstream | HUD reads current input context to show/hide ability bar, reads modifier state (L2/R2 held) to highlight active bar section. |
| **Pause System** | Downstream | Input emits pause_toggled signal on Start press. Works in all contexts. |
| **Settings System** | Upstream | Input reads button remapping configuration from Settings on startup and when changed. |
| **Travel System** | Downstream | Input emits mount toggle (D-Pad Down) and fast travel confirmation signals. |
| **Save/Load System** | Upstream | Input reads per-character remapping data from save file on load. |

## Formulas

### Modifier Trigger Threshold

```
modifier_active = trigger_analog_value >= TRIGGER_THRESHOLD
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| trigger_analog_value | float | 0.0 - 1.0 | hardware | Raw analog trigger position |
| TRIGGER_THRESHOLD | float | 0.5 | tuning knob | Activation threshold for L2/R2 modifier |

### Near-Death Time Dilation

```
Engine.time_scale = NEAR_DEATH_TIME_SCALE  (when entering Near-Death)
Engine.time_scale = lerp(current, 1.0, TIME_SNAP_SPEED * delta)  (when exiting)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| NEAR_DEATH_TIME_SCALE | float | 0.1 - 0.5 | tuning knob | Game speed during Near-Death (default 0.3) |
| TIME_SNAP_SPEED | float | 3.0 - 10.0 | tuning knob | How fast time returns to normal on exit (default 5.0) |

**Expected behavior**: At default 0.3, a 1-second enemy attack takes ~3.3 real
seconds. Player has roughly 3x more reaction time for potion use.

### Input Queue Window

```
queue_valid = time_since_input < GCD_QUEUE_WINDOW
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| GCD_QUEUE_WINDOW | float | 0.2 - 0.8s | tuning knob | How early before GCD ends an input can be queued (default 0.5s) |

### Analog Stick Deadzone

```
effective_input = (raw_input - DEADZONE) / (1.0 - DEADZONE)  if raw_input > DEADZONE else 0.0
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| DEADZONE | float | 0.05 - 0.3 | settings | Per-stick deadzone (default 0.15) |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| L2 and R2 held simultaneously | R2 takes priority (primary bar) | Prevents ambiguous state; primary bar is most-used |
| Ability pressed during GCD | Input queued, fires when GCD ends (max 1 queued) | Prevents dropped inputs during fast rotations |
| Controller disconnected mid-combat | Game auto-pauses, "Controller Disconnected" overlay | Pillar 1: never punish the player for hardware issues |
| Near-Death entered while in Menu | Menu stays open (game is paused), Near-Death visual effects appear behind menu. Slow-mo activates when menu closes. | Menu already pauses the game, so slow-mo is redundant until unpaused |
| Near-Death HP oscillates around 15% | Hysteresis: enter at 15%, exit at 20% to prevent flickering | Rapid enter/exit slow-mo would be disorienting |
| Player has no potions during Near-Death | Slow-mo still activates, player must dodge/heal via abilities (at slow speed) or die | Slow-mo is a mercy mechanic, not a guaranteed save |
| Quick item slot is empty | D-Pad press does nothing, brief "empty slot" UI flash | No error sound -- keep it non-punishing |
| Respawn Potion used with no enemies nearby | Potion consumed, player revives. No invulnerability needed. | Edge case from dying to environmental damage |
| Two abilities mapped to same slot | Not allowed -- remapping UI prevents duplicate slot assignments | Prevents confusing behavior |
| Keyboard and controller used simultaneously | Last device used determines UI prompt style. Both inputs functional. | Seamless switching, no mode lock |
| Near-Death triggers during cutscene | Not possible -- cutscenes pause gameplay. If HP was low before cutscene, Near-Death activates when cutscene ends if still below threshold. | Cutscenes are a safe space |

## Dependencies

| System | Direction | Hard/Soft | Nature of Dependency |
|--------|-----------|-----------|---------------------|
| **Health & Resource System** | Input reads from | Soft | HP threshold signal triggers Near-Death. Input works without it (no slow-mo). |
| **Settings System** | Input reads from | Soft | Remapping config and deadzone values. Input works with defaults if Settings unavailable. |
| **Save/Load System** | Input reads from | Soft | Per-character remapping data. Falls back to defaults if no save. |
| **Player Controller** | Depends on Input | Hard | Cannot move without input signals. |
| **Camera System** | Depends on Input | Hard | Cannot control camera without input signals. |
| **Ability Rotation Combat** | Depends on Input | Hard | Cannot activate abilities without slot signals. |
| **Inventory System** | Depends on Input | Hard | Cannot navigate UI without input signals. |
| **Dialogue System** | Depends on Input | Hard | Cannot select choices without input signals. |
| **HUD System** | Depends on Input | Soft | Reads modifier state for bar highlighting. Works without it (no highlight). |
| **Pause System** | Depends on Input | Hard | Cannot pause without Start signal. |
| **Travel System** | Depends on Input | Hard | Cannot toggle mount or confirm travel without input. |

**Note**: Input System has zero hard upstream dependencies. It is a true foundation
system that can function in isolation with default settings.

## Tuning Knobs

| Parameter | Default | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|---------|------------|-------------------|-------------------|
| TRIGGER_THRESHOLD | 0.5 | 0.2 - 0.8 | Harder to activate modifier (must press deeper) | Easier to activate (risk of accidental activation) |
| NEAR_DEATH_TIME_SCALE | 0.3 | 0.1 - 0.5 | Less slow-mo effect, less reaction time | More slow-mo, more reaction time (too low feels frozen) |
| NEAR_DEATH_HP_ENTER | 15% | 5% - 30% | Triggers earlier (more safety net) | Triggers later (less warning, harder) |
| NEAR_DEATH_HP_EXIT | 20% | ENTER+5% - 40% | Must heal more to exit slow-mo | Exits slow-mo sooner |
| TIME_SNAP_SPEED | 5.0 | 3.0 - 10.0 | Snappier return to normal speed | Smoother but slower transition |
| GCD_QUEUE_WINDOW | 0.5s | 0.2 - 0.8s | More forgiving ability queuing | Tighter timing required (punishing) |
| DEADZONE | 0.15 | 0.05 - 0.3 | Less sensitive sticks (ignore more drift) | More sensitive (risk of drift input) |
| RESPAWN_POTION_HP | 50% | 25% - 75% | Revive with more HP (safer) | Revive with less HP (still dangerous) |
| RESPAWN_INVULN_DURATION | 3.0s | 1.0 - 5.0s | Longer safety window after revive | Shorter, more punishing revive |

**Interaction warning**: NEAR_DEATH_HP_ENTER and NEAR_DEATH_HP_EXIT must maintain
a gap (hysteresis) to prevent slow-mo flickering. EXIT must always be > ENTER.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Near-Death enter | Screen edge vignette, desaturation, slight blur | Heartbeat sound (loops while in Near-Death) | HIGH |
| Near-Death exit (survive) | Vignette fades, color returns, brief "relief" flash | Heartbeat stops, exhale/relief SFX | HIGH |
| Near-Death exit (death) | Full screen fade to dark | Heartbeat flatline, death SFX | HIGH |
| Modifier held (L2/R2) | HUD ability bar section highlights | Subtle "ready" click | MEDIUM |
| Modifier released | Highlight fades | None | LOW |
| Quick item used | Item icon flash on HUD | Potion drink SFX | MEDIUM |
| Controller disconnected | Overlay: "Controller Disconnected" | Warning chime | HIGH |
| Respawn (waypoint) | Teleport/fade transition | Teleport whoosh | MEDIUM |
| Respawn (potion) | Revival glow effect, invuln shimmer | Revival chime, shield hum during invuln | MEDIUM |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Active ability bar section | HUD bottom-center | On modifier change | Always in Exploration/Combat |
| Ability slot cooldowns | HUD ability bar icons | Every frame | Always in Exploration/Combat |
| Quick item slots + count | HUD bottom-left/right | On use or pickup | Always |
| Near-Death vignette | Full screen overlay | On enter/exit | HP < 15% in combat |
| Respawn options | Center screen | On death | Dead state only |
| Controller prompt icons | All UI elements | On input device change | Always |
| Input remapping UI | Settings > Controls | On enter settings | Menu context only |
| Current input context | Debug only (not player-facing) | On change | Dev builds only |

## Acceptance Criteria

- [ ] All 16 ability slots fire correctly via R2/L2 + face/d-pad modifiers
- [ ] Modifier threshold prevents accidental activation when resting fingers on triggers
- [ ] Input context switches instantly when entering/exiting combat, menus, dialogue
- [ ] Near-Death slow-mo activates when HP drops below 15% in combat
- [ ] Near-Death persists until HP rises above 20% or reaches 0 (no timer cutoff)
- [ ] Quick items (D-Pad Left/Right) respond at real-time speed during Near-Death
- [ ] Abilities fire at slow-mo speed during Near-Death
- [ ] Time smoothly returns to normal (lerp) when exiting Near-Death
- [ ] Dead state shows respawn options; Respawn Potion option grayed if none in inventory
- [ ] Pause (Start) works in ALL contexts including cutscenes and Near-Death
- [ ] Controller disconnect auto-pauses the game
- [ ] All bindings are remappable via Settings menu
- [ ] Input device auto-detection switches UI prompts between controller/keyboard icons
- [ ] Ability input queuing works: press during GCD fires after GCD ends
- [ ] No raw button polling anywhere in codebase -- all systems use named actions
- [ ] Performance: Input processing completes within 1ms per frame
- [ ] No hardcoded button assignments in implementation -- all read from config

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Should we support double-tap L2/R2 for 16 additional ability slots (32 total)? | Game Designer | After Alpha -- evaluate if 16 slots is sufficient for multi-class builds | Low priority: 16 is enough for MVP through Alpha |
| How does Near-Death interact with abilities that heal over time (HoTs)? | Systems Designer | During Health & Resource System GDD | If a HoT ticks HP above 20%, slow-mo exits smoothly |
| Should keyboard/mouse get its own Near-Death visual treatment? | UX Designer | During UI polish pass | Slow-mo works identically; visual overlay may need adjustment for monitor vs. TV distance |
| iPad touch controls: do we need a virtual gamepad fallback? | UX Designer | During platform testing | Scope: iPad is controller-required. Touch fallback is stretch goal only. |
| Haptic feedback on controller for Near-Death heartbeat? | Audio Director | During audio system design | PS5/Switch Pro controllers support HD rumble |
