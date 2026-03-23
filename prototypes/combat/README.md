# Combat Prototype

**Hypothesis**: Does WoW-style GCD rotation feel fun on a gamepad in Godot 4.6?

**Status**: Concluded — Hypothesis Validated

## How to Run

```bash
cd prototypes/combat
godot
```

Requires Godot 4.6.1+. Launches fullscreen. Press `+`/Escape to pause.

## Controller Layout

Tested with Nintendo-style controller (A/B and X/Y positions may differ on Xbox-style pads).

### Base Controls (always active)

| Button | Action |
|--------|--------|
| A | Jump |
| B | Dodge / Roll (directional, 0.3s i-frames, 1s cooldown) |
| Y | Cancel / Untarget (clears locked target) |
| X | Interact (not yet implemented) |
| R2 (right trigger) | Basic Attack — Fel Strike (melee, weapon-dependent) |
| R1 (right bumper) | Next Target (cycles nearest-to-farthest) |
| L1 (left bumper) | Previous Target |
| D-pad Up | Spellbar: Default (Shadow Bolt, Curse of Agony, Immolate, Fel Cleave) |
| D-pad Left | Spellbar: Utility (Drain Life, Dark Pact) |
| D-pad Right | Spellbar: Custom (empty) |
| D-pad Down | Spellbar: Potions (empty) |
| Left Stick | Move |
| Right Stick | Camera |
| Left Stick Click | Toggle Run / Walk |
| Right Stick Click | Toggle Crouch / Sneak |
| + (Start) | Pause |
| - (Select) | Inventory (not yet implemented) |

### L2 Modifier (hold left trigger + face button)

| Combo | Action |
|-------|--------|
| L2 + A | Spell Slot 1 (from active spellbar) |
| L2 + B | Spell Slot 2 |
| L2 + Y | Spell Slot 3 |
| L2 + X | Spell Slot 4 |
| L2 + R2 | **Major Spell — Fel Cataclysm** (ultimate, 90s cooldown) |

### Keyboard Fallback

| Key | Action |
|-----|--------|
| WASD | Move |
| Space | Jump (A) |
| Right Shift | Dodge (B) |
| Escape | Cancel / Untarget (Y) |
| F | Interact (X) |
| Q | L2 modifier (hold for spells) |
| E | R2 / Basic Attack |
| Tab | Next Target |
| ` (backtick) | Previous Target |

## Spellbar System

4 spellbars, each holding 4 spell slots. Switch with D-pad. Active spellbar shown in the HUD.

| Spellbar | D-pad | Slot 1 | Slot 2 | Slot 3 | Slot 4 |
|----------|-------|--------|--------|--------|--------|
| Default | Up | Shadow Bolt (1.8s cast) | Curse of Agony (instant DoT) | Immolate (instant fire DoT) | Fel Cleave (AoE melee, 8s CD) |
| Utility | Left | Drain Life (2.5s channel) | Dark Pact (shield, 15s CD) | — | — |
| Custom | Right | — | — | — | — |
| Potions | Down | — | — | — | — |

## Abilities Reference

### Basic Attack (R2)
- **Fel Strike** — Melee shadow hit, 3m range, no cost, triggers GCD

### Spellbar 0: Default
1. **Shadow Bolt** — 1.8s cast, 20 mana, 25m range, shadow nuke
2. **Curse of Agony** — Instant, 15 mana, shadow DoT (12s duration)
3. **Immolate** — Instant, 18 mana, fire DoT (15s duration)
4. **Fel Cleave** — Instant, 30 mana, 4m AoE around self, 8s cooldown

### Spellbar 1: Utility
1. **Drain Life** — 2.5s channel, 25 mana, heals while damaging, 6s CD
2. **Dark Pact** — Instant, 40 mana, self-shield, off-GCD, 15s CD

### Ultimate (L2+R2)
- **Fel Cataclysm** — Instant, no cost, 20m AoE shockwave, 2000+ damage to all enemies in range, heals for 50% of total damage dealt, 90s cooldown, off-GCD

## HUD Layout

```
[HP Bar]  [Mana Bar]                    [Target Frame - when locked]

                                        (target lock ring on enemy)

[R2:Strike] | [L2+A] [L2+B] [L2+Y] [L2+X] | [L2+R2:Ult] | Bar Name
[Debug: GCD | Cast | Target | Movement | Spellbar | FPS]
```

- Spell slots flash **white** when fired
- Spell slots flash **red** when ability fails (cooldown, no mana, etc.)
- GCD shown as dark overlay sweeping down on affected slots
- Cooldowns shown as countdown text on slots
- Ultimate shows remaining cooldown in seconds with overlay

## Known Limitations (not blocking — prototype is concluded)

- Interact (X) and Inventory (-) not wired
- No visual/audio feedback for dodge, jump, spellbar switch
- No VFX for shockwave (Cataclysm), melee swings
- Damage numbers at fixed screen coords, not projected from 3D
- Grip buttons (ML/MR) not mapped
- Drain Life channeling not implemented
- No player death state
- No enemy variety (all identical)
- Controller mapping assumes Nintendo layout (A/B, X/Y swapped vs Xbox)

## Findings

**Hypothesis validated**: WoW-style GCD rotation feels fun on a gamepad in Godot 4.6,
with significant adaptations.

### What worked
1. **L2 modifier pattern** — physical actions on face buttons, spells behind L2 hold. Players can always jump/dodge mid-combat without mode switching.
2. **0.5s GCD** — much faster than WoW's 1.5s, matches controller input speed. Feels responsive, not sluggish.
3. **Off-GCD basic attack weaving** — R2 on its own 1.0s cooldown, independent of spell GCD. Creates satisfying rhythm.
4. **Mana-from-attacks** — forcing basic attack engagement makes weapons feel valuable and creates real resource decisions.
5. **Generous dodge (0.3s i-frames)** — easy to execute, skill is in choosing WHEN to dodge (opportunity cost).
6. **Projectile deferred damage** — adds visual clarity and tension. Watching a Shadow Bolt fly is satisfying.
7. **Debuff rotation** — even with just Curse (utility) + Immolate (DoT), meaningful decisions emerge.
8. **D-pad spellbar switching** — 4 bars × 4 slots = 16 spells accessible without complex combos.

### What didn't work (iterated away)
1. **Modal input (combat mode vs explore mode)** — confusing, removed in favor of always-available physical actions.
2. **R1/L1 as spell modifier** — triggers (L2/R2) are more natural for "hold while pressing" than bumpers.
3. **Face buttons as ability slots** — can't dodge if A/B are spell slots. Critical failure.
4. **Camera pitch control** — allowing vertical camera rotation caused disorienting angles. Zoom only.
5. **Auto-targeting all attacks** — felt like the game was playing itself. Require explicit target with range-based fallback.

### Key insight
The controller mapping that feels right was NOT what was originally expected. The prototype went through 3 major input revisions before landing on the L2-modifier pattern. **Prototype input mappings early.**

### Informs these GDDs
- `design/gdd/input-system.md` — L2 modifier pattern validated, modal input rejected
- `design/gdd/ability-rotation-combat.md` — 0.5s GCD, off-GCD weaving, debuff rotation validated
- `design/gdd/health-resource-system.md` — mana-from-attacks, no passive combat regen validated
- `design/gdd/damage-calculation.md` — armor/resistance formula, crit system, lifesteal validated
- `design/gdd/camera-system.md` — orbit-only camera (no pitch), zoom range validated
- `design/gdd/pause-system.md` — controller disconnect handling validated

See `CONCEPT.md` for the full reverse-documented design with all tuning values.
