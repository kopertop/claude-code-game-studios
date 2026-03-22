# Ability Rotation Combat

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-22
> **Implements Pillar**: ALL — This is the core game loop

## Overview

The Ability Rotation Combat system is the execution engine that makes combat
happen. It receives ability slot activation signals from the Input System, looks
up ability data from the Ability Database, manages the Global Cooldown and
individual cooldown timers, resolves targeting (hybrid: lock-on auto-target or
free camera-aim), triggers the Damage Calculation pipeline, and coordinates with
Health & Resource for resource consumption and HP changes. This is the 30-second
loop -- the beating heart of the game. Every other system exists to support,
enhance, or reward what happens here.

## Player Fantasy

The player should feel like a **master of their class** -- weaving abilities in
a rhythmic rotation that becomes increasingly fluid with practice. The GCD creates
the heartbeat: press, wait, press, wait. Within that rhythm, the player makes
tactical decisions: which ability next? Do I have enough resource? Should I dodge
now or finish this cast? Should I use my cooldown on this enemy or save it for
the boss? The rotation should feel like **playing a musical instrument** -- clunky
at first, then second nature, then deeply satisfying. A perfect rotation should
feel as good as a perfect drum fill.

## Detailed Design

### Core Rules

**1. Combat Engagement**
- Combat starts when: player attacks an enemy, or enemy attacks the player (aggro)
- Input System transitions to Combat context
- Sprint auto-deactivates on combat entry
- Lock-on becomes available (L1)
- Combat ends when: all engaged enemies are dead or deaggro (leave aggro range)
- Out-of-combat regen timer starts after OOC_REGEN_DELAY

**2. Ability Execution Flow**

When a slot activation signal is received (e.g., `slot_3_pressed`):

```
1. Look up ability assigned to slot 3 from player's hotbar config
2. If slot is empty → ignore (no feedback)
3. Check ability state:
   a. If locked (not unlocked) → ignore
   b. If on individual cooldown → flash icon, ignore (queued if within GCD_QUEUE_WINDOW)
   c. If on GCD (and ability is NOT off-GCD) → queue input
   d. If insufficient resource → flash icon red, ignore
   e. If out of range (targeted ability + lock-on active) → "Out of Range" text
4. If all checks pass → begin ability execution:
   a. If cast_time == 0 (instant): execute immediately
   b. If cast_time > 0: start cast bar, lock movement (optional: allow slow movement during cast)
5. On execution:
   a. Consume resource cost from Health & Resource System
   b. If is_builder: generate resource via Health & Resource System
   c. Trigger GCD (if gcd_trigger == true)
   d. Start individual cooldown timer
   e. Resolve targeting (see rule 3)
   f. Send ability data to Damage Calculation for each target hit
   g. Play animation (animation_id from AbilityData)
   h. Play VFX (vfx_id) and SFX (sfx_id)
   i. Apply any buff/debuff effects
```

**3. Targeting Resolution (Hybrid)**

| Mode | Condition | Behavior |
|------|-----------|----------|
| **Lock-On Target** | L1 lock-on active | Ability targets locked enemy. Range check against lock-on target. |
| **Free Aim** | No lock-on | Ability fires in camera forward direction. Hitbox/hitscan in camera direction + cone. |
| **Self-Target** | Ability target_type == Self | Always targets player. No aiming needed. |
| **AoE Ground** | Ability target_type == AoEGround | Reticle appears at camera look-at point on ground. Confirm with ability press. |
| **AoE Around Self** | Ability target_type == AoEAroundSelf | Hits all enemies within radius of player. No aiming. |
| **AoE Cone** | Ability target_type == AoECone | Cone in player facing direction. Width/length from ability data. |

For single-target abilities in Free Aim mode:
- Cast a sphere (ABILITY_AIM_ASSIST_RADIUS) in camera direction
- If an enemy is within the sphere, ability hits that enemy
- If multiple enemies in sphere, hit the nearest to center
- This provides "aim assist" so gamepad players don't need pixel-perfect aim

**4. Global Cooldown Management**
- GCD is a shared timer: when one GCD-triggering ability is used, ALL GCD abilities
  are locked for the GCD duration
- effective_gcd = BASE_GCD / (1 + attack_speed_bonus), min MIN_GCD (from Ability Database GDD)
- Off-GCD abilities ignore and don't trigger the GCD
- GCD sweep animation plays on all ability icons simultaneously
- Input queue: one ability can be queued during the last GCD_QUEUE_WINDOW (0.5s) of a GCD

**5. Individual Cooldowns**
- Each ability has its own cooldown (0 = no cooldown, only GCD)
- Cooldown starts when ability fires (not when GCD starts)
- Cooldown ticks in real-time (NOT affected by time_scale during Near-Death)
  - This means cooldowns recover faster relative to game-time during slow-mo
  - This is intentional: gives the player MORE options during Near-Death
- Cooldown shown as radial sweep on ability icon

**6. Basic Attack (X Button)**
- Special ability: auto-targets nearest enemy, no resource cost, triggers GCD
- Class-specific animation (sword swing, staff hit, arrow shot, etc.)
- Acts as a builder for Rage and Focus resource types
- Available to all classes at all times
- Low damage, high reliability -- the "filler" in your rotation

**7. Cast-Time Abilities**
- Abilities with cast_time > 0 show a cast bar on HUD
- Player can move at CAST_MOVE_SPEED_MULTIPLIER during cast (slow movement, not locked)
- Cast cancelled by: dodge (B button), player choosing to cancel (pressing B without dodge)
- Cast NOT cancelled by: taking damage (solo-friendly, from Ability Database GDD)
- Resource consumed on cast COMPLETION, not on cast start
- If cast completes, ability fires at current target/aim point

**8. Dodge Integration**
- Dodge (B) always works during combat (from Player Controller GDD)
- Dodge cancels current cast (no resource consumed)
- Dodge has i-frames (DODGE_IFRAMES_DURATION = 0.3s)
- Dodge costs no resource (not part of combat resource economy)
- Dodge triggers its own cooldown (DODGE_COOLDOWN = 1.0s)
- Dodge does NOT trigger the GCD

**9. Near-Death Integration**
- When HP < 15%, Input System triggers Near-Death (time_scale = 0.3)
- ALL combat actions slow down proportionally:
  - GCD ticks at 30% speed (effectively 3x longer real-time between abilities)
  - Cast bars progress at 30% speed
  - Enemy attacks come in at 30% speed
  - BUT: cooldowns tick at real-time (player gains cooldown advantage)
  - AND: quick items (potions) are instant regardless of slow-mo
- This creates a window where the player can react: dodge, potion, or finish
  casting a heal ability (at slow speed)

**10. Aggro and Threat (Simplified for Solo)**
- Enemies have an aggro range (detection sphere)
- Once aggro'd, enemies track and attack the player
- No threat table (solo game -- player is always the only target)
- Enemies deaggro if player moves beyond DEAGGRO_RANGE for DEAGGRO_TIME
- Transitioning zones clears all aggro

**11. Enemy Combat (Same System)**
- Enemies use the same ability execution system as the player
- Enemy abilities defined as AbilityData Resources (same schema)
- Enemy AI (separate system, not yet designed) decides WHICH ability to use and WHEN
- Damage from enemy abilities flows through the same Damage Calculation pipeline
- Enemy abilities can be dodged with i-frames

### States and Transitions

| State | Entry | Exit | Player Can |
|-------|-------|------|-----------|
| Out of Combat | Default, all enemies dead/deaggro | Player attacks or enemy aggros | Move freely, sprint, interact, use abilities (pre-pull) |
| In Combat | Attack or aggro | All enemies dead/deaggro after DEAGGRO_TIME | Move, dodge, use abilities, use quick items. No sprint, no interact (except AoE loot). |
| Casting | Cast-time ability started | Cast completes, cancelled (dodge/B), interrupted | Slow movement, can dodge-cancel, can queue next ability |
| Near-Death Combat | HP < 15% during combat | HP > 20% or HP = 0 | Same as In Combat but at 30% speed. Potions at full speed. |
| Dead | HP = 0 | Respawn selected | Nothing (respawn UI only) |

**Note**: Combat state is an overlay on the Input System's context. The combat
system tracks engagement but doesn't override input context -- Input System
handles that.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Input System** | Upstream | Receives slot activation signals (slot_1_pressed..slot_16_pressed), basic attack (X), dodge (B). Receives Near-Death time_scale. |
| **Player Controller** | Upstream | Reads player position for range checks, AoE placement. Dodge handled by Player Controller with i-frames. Movement during cast uses CAST_MOVE_SPEED_MULTIPLIER. |
| **Camera System** | Upstream | Reads camera forward for free-aim targeting. Reads lock-on target for lock-on targeting. |
| **Ability Database** | Upstream | Reads AbilityData for all ability properties (damage, cost, cooldown, target type, etc.) |
| **Health & Resource System** | Both | Checks resource before execution. Consumes resource on ability fire. Builders add resource. HP changes from damage/healing. Near-Death threshold signals. |
| **Damage Calculation** | Downstream | Sends ability data + attacker stats + target to Damage Calculation pipeline. Receives final damage/healing to apply. |
| **Character Stats** | Upstream | Reads Attack Speed for GCD calculation. Reads all stats for damage scaling (via Damage Calc). |
| **SFX System** | Downstream | Triggers ability SFX on cast and impact. |
| **Pause System** | Upstream | time_scale=0 freezes all combat (GCD, cooldowns if in-game time, animations). |
| **Item Database** | Indirect | Modification rune effects can trigger during combat (on-hit procs, etc.). |
| **Enemy AI** | Both | Enemies use same execution system. Enemy AI decides ability usage. Combat tracks engagement state. |
| **HUD System** | Downstream | Ability bar state (cooldowns, GCD, resource availability), cast bar, target info, damage numbers. |

## Formulas

### GCD Calculation (from Ability Database GDD)

```
effective_gcd = BASE_GCD / (1 + attack_speed_bonus)
effective_gcd = clamp(effective_gcd, MIN_GCD, BASE_GCD)
```

| Variable | Default | Description |
|----------|---------|-------------|
| BASE_GCD | 1.5s | Standard GCD |
| MIN_GCD | 0.75s | Fastest possible GCD |

### Range Check

```
in_range = distance(player, target) <= ability.range
```

For melee abilities (range=0), use MELEE_RANGE constant.

| Variable | Default | Description |
|----------|---------|-------------|
| MELEE_RANGE | 3.0m | Range for melee abilities |
| ABILITY_AIM_ASSIST_RADIUS | 2.0m | Sphere size for free-aim targeting |

### Combat Timing During Near-Death

```
game_time_gcd = effective_gcd / Engine.time_scale
real_time_gcd = effective_gcd / Engine.time_scale  (appears longer to player)
cooldown_tick = cooldown - (real_delta)  (ticks at real-time, advantage to player)
```

At time_scale=0.3: A 1.5s GCD takes 5 real seconds. But a 10s cooldown takes
10 real seconds to expire. Player recovers cooldowns 3x faster relative to the
game pace.

### Cast Time

```
cast_progress += delta / ability.cast_time
if cast_progress >= 1.0: ability fires
```

During Near-Death, delta is reduced by time_scale, so cast takes longer in
real-time (but the world is also slower, so it feels proportional).

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Ability target dies during cast | Cast completes but whiffs (no target). Resource NOT consumed. | Don't punish player for enemy dying |
| Two abilities pressed same frame | First processed wins. Second is queued or rejected. | Deterministic ordering |
| Dodge pressed during cast | Cast cancelled immediately. Dodge executes. No resource consumed. | Dodge is always the escape |
| Lock-on target goes out of range mid-ability | Ability still fires at last known position. May miss. | Abilities are fire-and-forget |
| Off-GCD ability + GCD ability pressed together | Both fire: off-GCD immediately, GCD ability starts GCD | Off-GCD is designed for weaving |
| Enemy dies from DoT tick | Combat doesn't end until all enemies dead. DoT on last enemy → death → combat ends. | Clean combat exit |
| Near-Death → potion → above 20% → combat continues | Slow-mo ends smoothly, combat continues at normal speed | From Input System: hysteresis |
| Respawn Potion used → invuln → still in combat | 3s invulnerability, enemies still attacking (hitting for 0). Combat continues after invuln. | Respawn isn't a combat exit |
| Player runs away from enemies | After DEAGGRO_RANGE + DEAGGRO_TIME, enemies deaggro. Combat state ends. | Running is a valid strategy |
| AoE hits 10+ enemies | Each enemy takes damage independently. Performance budgeted for MAX_SIMULTANEOUS_TARGETS. | Cap to prevent frame drops |
| Ability with 0 range (self-buff) used with lock-on | Self-target overrides lock-on. Buff applies to player. | target_type is authoritative |

## Dependencies

| System | Direction | Hard/Soft | Nature |
|--------|-----------|-----------|--------|
| **Input System** | Upstream | Hard | Cannot receive ability activations without input signals |
| **Player Controller** | Upstream | Hard | Cannot check range/position without player position. Dodge integration. |
| **Camera System** | Upstream | Hard | Cannot free-aim without camera forward. Cannot lock-on without camera. |
| **Ability Database** | Upstream | Hard | Cannot execute abilities without ability data |
| **Health & Resource System** | Both | Hard | Resource check/consumption, HP application, Near-Death signals |
| **Damage Calculation** | Downstream | Hard | Cannot resolve damage/healing without the formula pipeline |
| **Character Stats** | Upstream | Hard | Attack Speed for GCD. All stats for damage scaling. |
| **SFX System** | Downstream | Soft | Audio feedback. Game works silent. |
| **Pause System** | Upstream | Hard | Must freeze all combat on pause |
| **Enemy AI** | Both | Soft | Enemies use same system. Combat works without AI (just no enemies). |
| **HUD System** | Downstream | Soft | Visual feedback. Combat works without HUD (just blind). |

## Tuning Knobs

| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| BASE_GCD | 1.5s | 1.0-2.5 | Core rotation speed. THE most important tuning knob. |
| MIN_GCD | 0.75s | 0.5-1.0 | Speed cap with high attack speed |
| MELEE_RANGE | 3.0m | 2.0-5.0 | How close for melee abilities |
| ABILITY_AIM_ASSIST_RADIUS | 2.0m | 1.0-4.0 | Free-aim forgiveness. Higher = easier to hit. |
| DEAGGRO_RANGE | 40.0m | 20-60 | Distance to reset enemies |
| DEAGGRO_TIME | 5.0s | 3-10 | Time at range before deaggro |
| CAST_MOVE_SPEED_MULTIPLIER | 0.5 | 0.0-0.8 | Movement speed while casting. 0=locked in place. |
| MAX_SIMULTANEOUS_TARGETS | 20 | 10-40 | Cap for AoE performance |
| GCD_QUEUE_WINDOW | 0.5s | 0.2-0.8 | Input queue timing (from Input System) |

**Critical tuning chain**: BASE_GCD → MIN_GCD → per-ability cooldowns → resource
costs. These together define the "feel" of every class rotation. Tune as a set.

## Visual/Audio Requirements

| Event | Visual | Audio | Priority |
|-------|--------|-------|----------|
| Ability fires | Character animation + VFX (per ability) | Ability SFX (per ability) | CRITICAL |
| Ability hits target | Impact VFX at target | Impact SFX | CRITICAL |
| Critical hit | Larger impact VFX, screen shake (subtle) | Enhanced impact + crit sound | HIGH |
| GCD active | Sweep overlay on all ability icons | None | HIGH |
| Cooldown active | Radial sweep on individual icon | None | HIGH |
| Cast bar progress | HUD cast bar fills | Casting loop sound | HIGH |
| Cast complete | Cast bar flashes and disappears | Cast complete sound | MEDIUM |
| Out of range | "Out of Range" text above target | None | MEDIUM |
| Insufficient resource | Ability icon flashes red | None (silent) | MEDIUM |
| Combat enter | Enemies aggro animation, combat music starts | Aggro sound, music transition | HIGH |
| Combat exit | Music transitions back to zone theme | Combat end sound | MEDIUM |

## UI Requirements

| Information | Location | Update | Condition |
|-------------|----------|--------|-----------|
| Ability hotbar (16 slots) | HUD bottom-center | Per frame | Always in gameplay |
| GCD sweep (all icons) | Over ability icons | Per frame | GCD active |
| Individual cooldown sweep | Over specific icon | Per frame | On cooldown |
| Resource availability (icon dim) | Ability icons | On resource change | Insufficient resource |
| Cast bar | HUD center | Per frame | Casting |
| Target HP bar | Above locked target or HUD | On damage event | Lock-on active |
| "Out of Range" text | Above target | On failed ability | Target too far |
| Damage/healing numbers | Float above targets | Per damage event | Combat |
| Combat state indicator | HUD edge glow or icon | On combat enter/exit | In combat |

## Acceptance Criteria

- [ ] Ability slot activation correctly looks up assigned ability
- [ ] GCD triggers on GCD-abilities, does NOT trigger on off-GCD abilities
- [ ] GCD duration scales correctly with Attack Speed (min 0.75s)
- [ ] Input queue works: ability pressed in last 0.5s of GCD fires on GCD expire
- [ ] Individual cooldowns track independently per ability
- [ ] Lock-on targeting correctly targets locked enemy
- [ ] Free-aim targeting uses camera direction with aim assist sphere
- [ ] AoE abilities (ground, self, cone) target correctly
- [ ] Cast-time abilities show cast bar, allow slow movement, cancel on dodge
- [ ] Cast-time abilities NOT interrupted by taking damage
- [ ] Resource consumed on ability fire (instant) or cast completion (cast-time)
- [ ] Builder abilities generate correct resource amount
- [ ] Dodge (B) always available in combat with i-frames and cooldown
- [ ] Near-Death slow-mo affects GCD/cast timing but cooldowns tick at real-time
- [ ] Aggro system works: enemy detection, tracking, deaggro at range+time
- [ ] Enemy abilities use same execution pipeline
- [ ] Combat enter/exit state transitions correctly
- [ ] AoE capped at MAX_SIMULTANEOUS_TARGETS for performance
- [ ] Basic Attack (X) works as auto-target, no-cost, GCD, builder
- [ ] Full combat flow: engage → rotate abilities → dodge attacks → kill → loot
- [ ] Performance: combat system update < 2ms per frame with 20 active combatants
- [ ] "The rotation feels fun on a gamepad" (subjective — requires playtest validation)

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Should lock-on change movement to strafe-and-face-target? | Game Designer | During prototyping | Open in both Player Controller and Camera GDDs. Prototype both modes. |
| How should enemy attack telegraphing work? | Game Designer | During Enemy AI GDD | AoE circles on ground? Wind-up animations? Both? Critical for dodge timing. |
| Should there be a combo system (press same ability twice for variant)? | Game Designer | Post-MVP evaluation | ComboAbilityData exists in schema but execution rules aren't defined yet. |
| Should ability effects be interruptible by specific counter-abilities? | Game Designer | During Status Effects GDD | "Interrupt" as an ability type (like WoW's Counterspell/Kick) |
| How do pet abilities interact with the GCD? | Game Designer | During Pet System GDD | Pets probably have their own GCD, independent of player |
| What happens when player has multiple classes' abilities unlocked simultaneously? | Game Designer | During Class & Mastery GDD | Can you use Warrior and Mage abilities at the same time? Or only active class? |
