# Player Controller

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-21
> **Implements Pillar**: Pillar 5 — Couch-Ready Controller Experience

## Overview

The Player Controller handles all physical character movement -- walking, running,
sprinting, dodging, jumping, swimming, and world interaction. It reads input
vectors from the Input System and translates them into CharacterBody3D movement
using Godot's Jolt physics. Movement is responsive and snappy with no momentum
delay -- the character goes where the stick points immediately. Dodge provides
invincibility frames for skill-based damage avoidance. This system is the
player's primary physical interface with the game world.

## Player Fantasy

The character should feel like an **extension of the player's hands**. Push the
stick, the character moves -- instantly, precisely, no lag. Dodge should feel
**powerful and satisfying** -- a well-timed roll through an enemy attack should
make the player feel skilled. The WoW feeling of "my character goes exactly
where I want" combined with the God of War feeling of "that dodge was perfect."
Movement should never frustrate -- invisible when exploring, empowering in combat.

## Detailed Design

### Core Rules

**1. Basic Movement**
- CharacterBody3D with Jolt physics
- Left stick input produces immediate velocity change (no acceleration curve)
- Character faces movement direction (instant turn, no rotation lerp while moving)
- Analog stick sensitivity: full range 0-1 maps to 0 to BASE_MOVE_SPEED
- Dead stick = full stop (no slide, no momentum)

**2. Sprint**
- L3 toggle activates sprint (Input System GDD)
- Sprint multiplies movement speed by SPRINT_MULTIPLIER
- Sprint has no stamina cost or duration limit (anti-grind, Pillar 1)
- Sprint deactivates on: dodge, attack, interact, entering combat
- Reactivate by pressing L3 again

**3. Dodge / Roll**
- B button triggers dodge in current movement direction (backward if stationary)
- Fixed-distance, fixed-duration animation with root motion
- **Invincibility frames**: Player is invulnerable for DODGE_IFRAMES_DURATION
  at the start of the dodge animation
- Cooldown: DODGE_COOLDOWN prevents spam
- Cancels current ability cast (emergency escape)
- During Near-Death slow-mo: dodge works at slow-mo speed but i-frame duration
  is preserved in real-time (effectively longer protection in game-time)
- Dodge costs nothing -- no stamina, no resource

**4. Jumping**
- Not available by default -- unlocked via mastery or modification rune
- When unlocked: mapped to customizable button
- Fixed height, no air control beyond initial direction
- Purpose: traversal and exploration, not combat
- Optional "double jump" rune exists as a modification

**5. Interaction**
- A button interacts with nearest interactable within INTERACT_RADIUS
- Sphere check from player center
- Priority when multiple interactables in range:
  1. Quest NPC
  2. Regular NPC
  3. Loot / Chest
  4. Gathering Node
  5. World Object (door, lever, etc.)
- Context action (Y): secondary interactions (mount, gather, loot at range)

**6. Swimming**
- Automatic state on entering water volume
- Speed reduced to SWIM_SPEED_MULTIPLIER of base
- No breath timer -- no underwater drowning (anti-frustration)
- Left stick Y-axis or camera angle controls depth
- Dodge disabled while swimming

**7. Root Motion vs. Controller Input**
- Movement uses controller input, NOT animation root motion
- Animations blend to match speed (walk/run/sprint blend tree)
- Movement always responsive -- animation follows physics
- Exception: dodge uses root motion for consistent distance

### States and Transitions

| State | Entry | Exit | Movement | Dodge | Interact |
|-------|-------|------|----------|-------|----------|
| Idle | No stick input | Stick moved, action | None | Yes (backward) | Yes |
| Moving | Stick input | Stick released, action | Full speed | Yes (move dir) | Yes (if range) |
| Sprinting | L3 while Moving | L3, dodge, attack, combat | Sprint speed | Yes (ends sprint) | Yes (ends sprint) |
| Dodging | B (cooldown ready) | Animation complete | Root motion | No (cooldown) | No |
| Interacting | A near interactable | Complete/cancelled | Stopped | No | No |
| Swimming | Enter water volume | Exit water | Swim speed, 3D | No | Limited |
| Mounted | Mount activated | Dismount/attack/interact | Mount speed | Dismount on dodge | Limited |
| Dead | HP = 0 | Respawn selected | None | No | Respawn UI only |
| Cutscene | Cutscene start | Cutscene end | Scripted/None | No | No |

**Transition rules:**
- Dodging has highest priority -- B always triggers dodge if off cooldown
  (except during Interacting, Swimming, Dead, Cutscene)
- Mounting from Idle/Moving only (not during combat, dodge, interact)
- Combat context (from Input System) doesn't change movement state -- player
  moves the same in and out of combat. Only sprint auto-deactivates on combat enter.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Input System** | Upstream | Reads movement vector, dodge signal, interact signal, sprint toggle, context action. Near-Death time_scale affects all movement. |
| **Camera System** | Peer | Camera follows player position. Movement is camera-relative (forward = camera forward). Soft lock-on affects facing in combat. |
| **Ability Rotation Combat** | Downstream | Combat reads player position for range/targeting. Dodge cancels ability casts. X (basic attack) triggers combat system, not Player Controller. |
| **Enemy AI** | Downstream | Enemies track player position for aggro, pathfinding, attack targeting. |
| **Gathering System** | Downstream | Player must be in INTERACT_RADIUS and stationary to gather. |
| **Travel System** | Downstream | Mount state overrides movement speed/animations. Fast travel teleports player. |
| **Pet System** | Downstream | Pets follow player position with offset and path smoothing. |
| **Character Stats** | Upstream | Movement speed modifiers from gear and mastery bonuses. |
| **Pause System** | Upstream | time_scale=0 freezes all movement. |
| **Scene/Zone Management** | Peer | Zone transitions trigger when player enters transition volumes. |

## Formulas

### Movement Speed

```
effective_speed = BASE_MOVE_SPEED * (1 + speed_modifier_sum) * sprint_multiplier * state_multiplier
```

| Variable | Type | Default | Source | Description |
|----------|------|---------|--------|-------------|
| BASE_MOVE_SPEED | float | 6.0 m/s | tuning knob | Walking/running speed |
| speed_modifier_sum | float | 0.0+ | Character Stats | Sum of gear + mastery movement bonuses |
| sprint_multiplier | float | 1.5 | tuning knob | Multiplier when sprinting (1.0 if not) |
| state_multiplier | float | varies | state | 1.0 normal, 0.6 swimming, 0.0 interacting/dead |

### Dodge Distance and Timing

```
dodge_distance = DODGE_BASE_DISTANCE  (fixed, root motion)
dodge_duration = DODGE_ANIMATION_DURATION  (fixed)
iframe_window = DODGE_IFRAMES_DURATION  (starts at frame 0 of dodge)
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| DODGE_BASE_DISTANCE | float | 4.0 meters | How far the dodge travels |
| DODGE_ANIMATION_DURATION | float | 0.6s | Total dodge animation length |
| DODGE_IFRAMES_DURATION | float | 0.3s | Invulnerability window (first half of dodge) |
| DODGE_COOLDOWN | float | 1.0s | Time between dodges |

### Gravity and Falling

```
fall_velocity += GRAVITY * delta
fall_velocity = min(fall_velocity, TERMINAL_VELOCITY)
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| GRAVITY | float | 20.0 m/s² | Downward acceleration (slightly above real for game feel) |
| TERMINAL_VELOCITY | float | 30.0 m/s | Max fall speed |
| FALL_DAMAGE_THRESHOLD | float | 10.0 meters | Fall distance before damage starts |
| FALL_DAMAGE_PER_METER | float | 5% max HP/m | Damage per meter above threshold |

### Interaction Range

```
can_interact = distance_to_target <= INTERACT_RADIUS
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| INTERACT_RADIUS | float | 3.0 meters | Sphere check radius for A button |
| CONTEXT_ACTION_RADIUS | float | 5.0 meters | Extended range for Y context action |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Dodge off a cliff | Dodge completes, then gravity applies. No air-dodge. | Prevents exploits, feels natural |
| Dodge into a wall | Dodge distance shortened, animation plays fully. No clipping. | Jolt physics handles collision |
| Sprint into water | Sprint deactivates, swim state activates at swim speed | Clean state transition |
| Interact during dodge | Ignored -- dodge has priority | Dodge is escape, don't interrupt it |
| Two interactables overlapping | Priority order applies (Quest NPC > NPC > Loot > etc.) | Predictable behavior |
| Fall damage while at low HP | Can trigger Near-Death. Can kill. Respawn Potion works. | Environmental danger is real but fair |
| Movement during Near-Death | Works but at slow-mo speed. Dodge works with real-time i-frames. | Player can still act, just slower |
| Stick input during cutscene | Ignored. Player cannot move during cutscenes. | Cutscenes control camera and character |
| Mounted → combat | Auto-dismount on taking damage or pressing attack. | Smooth combat entry |
| Swimming → zone transition | Transition occurs. New zone handles whether player is in water. | No softlock at zone boundary water |

## Dependencies

| System | Direction | Hard/Soft | Nature |
|--------|-----------|-----------|--------|
| **Input System** | Upstream | Hard | Cannot move without input vectors and action signals |
| **Character Stats** | Upstream | Soft | Speed modifiers. Works at base speed without stats. |
| **Camera System** | Peer | Soft | Camera-relative movement. Works with fixed camera fallback. |
| **Ability Rotation Combat** | Downstream | Soft | Combat reads position. Works without Player Controller (but unplayable). |
| **Enemy AI** | Downstream | Soft | AI tracks player position. |
| **Gathering System** | Downstream | Soft | Checks player range for gathering. |
| **Travel System** | Downstream | Soft | Mount overrides movement. |
| **Pet System** | Downstream | Soft | Pets follow player. |
| **Pause System** | Upstream | Hard | time_scale=0 must freeze movement. |
| **Scene/Zone Management** | Peer | Hard | Zone transitions based on player position. |

## Tuning Knobs

| Parameter | Default | Safe Range | Increase | Decrease |
|-----------|---------|------------|----------|----------|
| BASE_MOVE_SPEED | 6.0 m/s | 4.0-10.0 | Faster traversal, may outrun camera | Slower, may feel sluggish |
| SPRINT_MULTIPLIER | 1.5x | 1.2-2.5 | Faster sprint, sprint feels more distinct | Sprint barely noticeable |
| DODGE_BASE_DISTANCE | 4.0m | 2.0-8.0 | Longer dodge, easier to escape AoE | Shorter, more precise positioning |
| DODGE_IFRAMES_DURATION | 0.3s | 0.1-0.5 | More forgiving timing (easier) | Tighter timing (harder, more skillful) |
| DODGE_COOLDOWN | 1.0s | 0.5-3.0 | More dodge uptime (easier) | Less dodging, more positioning required |
| SWIM_SPEED_MULTIPLIER | 0.6x | 0.3-0.8 | Faster swimming | Slower, swimming feels tedious |
| INTERACT_RADIUS | 3.0m | 1.5-5.0 | Easier interaction | Must be very close to interact |
| FALL_DAMAGE_THRESHOLD | 10.0m | 5.0-20.0 | Safe falls from higher | Fall damage starts sooner |
| GRAVITY | 20.0 m/s² | 15.0-30.0 | Heavier, more grounded | Floatier, more airtime |

**Key interaction**: DODGE_IFRAMES_DURATION and DODGE_COOLDOWN together define
combat difficulty. More i-frames + shorter cooldown = easier game. Tune together.

## Visual/Audio Requirements

| Event | Visual | Audio | Priority |
|-------|--------|-------|----------|
| Walk/Run | Blended walk-run animation tree | Footstep sounds (surface-aware: stone/grass/dirt/wood) | HIGH |
| Sprint | Faster animation, optional speed lines | Faster footsteps, wind rush | MEDIUM |
| Dodge | Roll animation, brief motion blur | Whoosh sound, armor rustle | HIGH |
| I-frame active | Subtle character flash/shimmer during i-frames | None (don't telegraph to enemies in future) | MEDIUM |
| Land after fall | Impact animation (knee bend) | Landing thud (scales with height) | MEDIUM |
| Fall damage | Screen shake, red flash | Impact slam + pain grunt | HIGH |
| Enter water | Splash VFX | Splash sound | MEDIUM |
| Swimming | Swim animation blend tree | Water movement sounds | LOW |
| Interaction | Character reaches/bends toward target | Interaction click/chime | LOW |

## UI Requirements

| Information | Location | Condition |
|-------------|----------|-----------|
| Dodge cooldown indicator | Small icon near ability bar or character | Dodge on cooldown only |
| Sprint active indicator | Small icon near character or HUD | Sprint active |
| Interaction prompt ("A: Talk", "Y: Gather") | Floating above interactable | In range of interactable |
| Context action prompt | Floating above target | Y action available |
| Fall damage warning | None -- let physics speak | N/A (no warning, just don't jump off cliffs) |

## Acceptance Criteria

- [ ] Character moves instantly on stick input with zero perceptible delay
- [ ] Character stops instantly when stick returns to center (no slide)
- [ ] Sprint activates/deactivates on L3 toggle with correct speed multiplier
- [ ] Sprint has no stamina cost or time limit
- [ ] Dodge covers DODGE_BASE_DISTANCE with root motion
- [ ] I-frames active for exactly DODGE_IFRAMES_DURATION (damage ignored during window)
- [ ] Dodge cooldown prevents spam (DODGE_COOLDOWN between dodges)
- [ ] Dodge cancels current ability cast
- [ ] Interaction priority order correct when multiple interactables overlap
- [ ] Swimming activates automatically in water, dodge disabled
- [ ] No breath timer while swimming
- [ ] Fall damage applies above threshold, scales correctly
- [ ] Movement works at slow-mo speed during Near-Death
- [ ] All movement freezes when paused (time_scale=0)
- [ ] Movement is camera-relative (forward = camera forward direction)
- [ ] Footstep sounds change with surface type
- [ ] Performance: Player Controller update completes within 1ms per frame
- [ ] No clipping through walls during dodge

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Should jump be in the base game or truly unlock-only? | Game Designer | During prototyping | Many zones may need vertical traversal. Could gate it behind early mastery. |
| Mount movement: separate state machine or speed override? | Gameplay Programmer | During Travel System GDD | Mounts may need unique movement (flying mount, swimming mount) |
| Should dodge direction be stick-relative or camera-relative? | UX Designer | During prototyping | Stick-relative feels more responsive; camera-relative is easier to learn |
| Combat-specific movement states (strafing while locked on)? | Game Designer | During Combat System GDD | Lock-on may change movement to strafe-and-face-target |
