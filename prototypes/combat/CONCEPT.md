---
status: reverse-documented
source: prototypes/combat/
date: 2026-03-23
verified-by: cmoyer
---

# Combat Prototype — Concept Document

> **Note**: Reverse-engineered from the working combat prototype. Captures validated
> design decisions, playtested values, and lessons learned. This document informs
> production implementation — the prototype code itself should NOT be migrated directly.

## Hypothesis

**Question**: Does WoW-style GCD rotation feel fun on a gamepad in Godot 4.6?

**Answer**: **Yes** — with significant adaptations. The result is closer to an
action-RPG with WoW-style spell depth than a traditional MMO combat system.
The controller mapping required fundamental rethinking of how abilities are accessed.

## Core Design Identity

**Action-RPG with spell rotation depth.** Players always have physical agency
(jump, dodge, move) while casting is layered on top via a modifier button.
This is NOT adapted MMO combat — it's a new hybrid that borrows WoW's rotation
complexity but wraps it in action-game responsiveness.

## Key Discovery: The Modifier Pattern

The single most important finding: **face buttons must always do physical actions**.
Spells go behind a modifier (L2 hold). This was NOT the original plan — early
iterations tried modal combat (face buttons change meaning when targeting), but
playtesting revealed that needing to jump/dodge mid-combat is constant, and
locking those behind a mode switch felt terrible.

### Final Controller Layout (Validated)

**Always available — physical actions:**
- A: Jump
- B: Dodge/Roll
- Y: Clear target
- X: Interact (reserved)
- R2: Basic Attack (weapon swing)
- R1/L1: Cycle targets (next/prev)

**L2 modifier — magical actions:**
- L2+A/B/X/Y: Spell slots 1-4 (from active spellbar)
- L2+R1: Ultimate / Major Spell (90s cooldown)

**D-pad — spellbar management:**
- Up/Left/Right/Down: Switch between 4 spellbars (16 total spell slots)

**Stick clicks — stance toggles:**
- Left stick: Run/Walk
- Right stick: Crouch/Sneak

**Design intent**: Your left index finger (L2) is the "magic finger." Everything
else is physical. You never have to think "which mode am I in?" — just hold L2
when you want to cast.

## Validated Combat Loop

### Warlock Rotation (Tested)

```
1. Curse of Agony (opener — always first, 30s duration)
2. Immolate (5s burn, reapply on expiry)
3. Shadow Bolt (1.0s cast, main damage)
4. Basic Attack (weave between casts for mana)
5. Shadow Bolt + Basic Attack (alternate)
6. Immolate (reapply at 5s)
7. Shadow Bolt + Basic Attack...
8. Fel Cleave (when enemies cluster, 8s cooldown)
9. Dark Pact (emergency shield, off-GCD)
10. Fel Cataclysm (ultimate panic button, 90s cooldown)
```

**What makes it feel good**: You're always pressing something. Shadow Bolt and
Basic Attack run on independent timers (GCD vs 1.0s cooldown), so you weave
R2 between L2+A casts. Immolate pops back every 5 seconds for a quick reapply.
Curse is set-and-forget for 30 seconds.

### Resource Economy (Validated)

**Design intent**: Basic attacks must feel valuable, not just "filler while spells
are on cooldown." Making them the ONLY mana source in combat forces melee engagement.

- **Out of combat**: Passive mana regen (5/sec) — quality of life between fights
- **In combat**: Zero passive regen — must basic attack for mana (+15 per hit)
- **Basic attack also heals**: Small HP return (5 flat + 10% lifesteal) rewards aggression
- **Curse lifesteal**: Additional 15% heal when hitting cursed targets — rewards rotation discipline

**Result**: Players who execute the rotation well sustain indefinitely. Players who
panic-spam spells run dry and die. The resource system IS the skill expression.

### GCD Timing (Validated)

- **Base GCD**: 0.5 seconds (very fast vs WoW's 1.5s)
- **Why**: Controller input is faster than keyboard — you can hit L2+A much faster
  than reaching for a number key. 1.5s felt sluggish on a controller.
- **Basic Attack**: Off-GCD with own 1.0s cooldown — lets you weave between spells
- **Design note**: Both GCD and basic attack cooldown should be easily modifiable.
  Talents will reduce these as a core progression lever.

### Dodge System (Validated)

- **Duration**: 0.4 seconds
- **I-frames**: 0.3 seconds (75% of dodge is invulnerable)
- **Cooldown**: 1.0 seconds
- **Design intent**: Generous window — dodging should feel EASY and reliable.
  The skill expression is in choosing WHEN to dodge (opportunity cost of not
  attacking), not whether you can execute the dodge timing.

## Debuff System (Validated)

Two debuff archetypes emerged:

### Utility Debuff (Curse of Agony)
- Long duration (30s), apply once, fight normally
- Weakens enemy (-30% damage) AND rewards you (+15% lifesteal on hit)
- **Design role**: "Always up" maintenance buff, rewards target prioritization
- Refreshes on reapply (no stacking)

### Damage-over-Time Debuff (Immolate)
- Short duration (5s), frequent reapplication
- Passive damage (5 HP/sec) — adds up across multiple targets
- **Design role**: Rotation filler, multi-target pressure, "keep it rolling"
- Refreshes on reapply (no stacking)

**HUD**: Debuffs shown on target frame as emoji + countdown: `💀 28s 🔥 4s`

## Projectile System (Validated)

- Ranged spells fire homing projectiles (Shadow Bolt, Curse, Immolate)
- Damage deferred until projectile impacts — creates dodge windows for enemies
- Melee abilities (Fel Strike, Fel Cleave) and self-buffs (Dark Pact) are instant
- **Visual**: Glowing sphere with particle trail, color-matched to ability + explosion on impact
- **Key implementation note**: Projectile on_hit callback must fire exactly once
  (discovered multi-hit bug during testing — guard flag required)

## Camera System (Validated)

WoW-style orbit camera:
- Right stick horizontal: Orbit around player (yaw only, always level with ground)
- Right stick vertical: Zoom in/out (3-18 unit range)
- Fixed height (5 units above player), always looking at player center
- **No pitch** — early iterations allowed pitch rotation which created disorienting angles

## Auto-Targeting (Validated)

Three targeting paths:
1. **Manual**: R1/L1 bumpers cycle through enemies by distance
2. **On attack**: If no target and you press an attack, auto-locks nearest enemy within ability range
3. **On hit**: If no target and an enemy hits you, auto-locks the attacker

**Design intent**: You should never feel like you're "fighting the UI." Targeting
should be invisible when there's an obvious choice, and manual when there are
multiple valid targets.

## Pause & Controller (Validated)

- Auto-pause on controller disconnect (with "Continue without controller" option)
- Auto-pause on startup if no controller detected
- Auto-resume when controller reconnects
- Manual pause with + button, dark overlay with "PAUSED" text
- All game entities freeze (player, enemies, projectiles) — pause overlay processes independently

## Tuning Values Reference

### Player
| Value | Amount | Notes |
|-------|--------|-------|
| Max HP | 500 | |
| Max Mana | 200 | |
| Mana Regen (out of combat) | 5/sec | Pauses when target locked |
| Run Speed | 7.0 u/s | |
| Walk Speed | 3.0 u/s | |
| Crouch Speed | 2.0 u/s | |
| Cast Move Multiplier | 0.5x | Half speed while casting |
| Crit Chance | 15% | |
| Crit Multiplier | 1.5x | |
| Spell Power | 60 | Primary scaling stat |
| Physical Power | 20 | Melee scaling stat |

### Enemy
| Value | Amount | Notes |
|-------|--------|-------|
| Max HP | 800 | ~15-20s to kill with full rotation |
| Attack Damage | 25 | Reduced by Curse (-30%) |
| Attack Cooldown | 2.0s | |
| Move Speed | 3.0 u/s | Slower than player (7.0) |
| Aggro Range | 15 u | |
| Deaggro Range | 40 u | |
| Armor | 80 | |
| Resistance | 40 | |

### Damage Formula
```
raw = base_damage + (scaling_stat * scaling_coefficient)
if crit: raw *= 1.5
reduction = defense / (defense + 500 + level * 10)
final = max(1.0, raw * (1 - reduction))
```

## What's NOT Validated (Needs Production Testing)

- **Multiple enemy types** — all enemies are identical. Need ranged, tank, healer to test target priority
- **Drain Life channel** — defined but channeling mechanic not implemented
- **Sound/VFX** — no audio, minimal visual effects. Juice is missing.
- **Player death** — HP reaches 0 and nothing happens
- **Spellbar 2-3** — empty, untested with full spell loadout
- **Talent system** — designed to modify cooldowns/GCD but not implemented
- **Long fights** — 800 HP enemies die fast. Need boss-length encounters (30s+) to test rotation sustainability

## Lessons Learned

1. **Controller layout assumptions are wrong** — prototype early and iterate on mappings
2. **GCD needs to match input speed** — controller is faster than keyboard, tune accordingly
3. **Resource economy drives engagement** — mana-from-attacks was the single best feel improvement
4. **Generous dodge windows > precise timing** — for this game, dodging is about WHEN not IF
5. **Projectiles add massive feel** — deferred damage creates tension and visual clarity
6. **Debuff variety matters early** — even 2 debuff types (utility vs DoT) create interesting decisions
7. **Projectile cleanup bugs are subtle** — always guard on-hit callbacks with a "fired" flag
8. **Pause system needs PROCESS_MODE_PAUSABLE on all children** — Godot's PROCESS_MODE_ALWAYS propagates to children, which is rarely what you want
