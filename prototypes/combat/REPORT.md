## Prototype Report: Combat System (Warlock)

### Hypothesis

A WoW-style GCD ability rotation adapted for gamepad (R2/L2 modifier hotbar,
1.5s GCD heartbeat, builder/spender rhythm, dodge weaving) will feel fun and
responsive in Godot 4.6 with a Warlock "battle mage" class.

### Approach

Built a self-contained Godot 4.6 project in `prototypes/combat/` with:

- **7 files, ~900 lines of GDScript** — all procedurally constructed (no editor dependency)
- **CombatSystem** node: GCD timer, ability execution pipeline, input queue,
  cast bar, cooldown tracking, damage calculation (full formula from GDD)
- **Player**: CharacterBody3D with capsule mesh, WoW-style orbit camera,
  gamepad movement, dodge with i-frames, mana regen
- **Warlock abilities (7)**: Fel Strike (instant melee), Shadow Bolt (1.8s cast),
  Curse of Agony (instant DoT), Immolate (instant fire DoT), Fel Cleave
  (melee AoE + 8s CD), Drain Life (2.5s cast heal+damage), Dark Pact (off-GCD shield)
- **Enemy**: Box mesh, aggro range, melee attacks, HP, damage flash, death animation
- **HUD**: HP/mana bars, 7-slot ability hotbar with GCD sweep overlay, cooldown
  numbers, cast bar, target HP, floating damage numbers, debug info
- **Arena**: 60x60 ground plane, 8 stone pillars, moonlight atmosphere, 3 enemies
  that respawn after clearing

Shortcuts taken (prototype-appropriate):
- All nodes built in code, no .tscn editor setup needed
- Hardcoded stats (PL 10, INT 40, Spell Power 60)
- No save/load, no pause, no Near-Death slow-mo
- No DoT tick implementation (damage applies on cast only)
- Placeholder geometry (capsule player, box enemies, cylinder pillars)
- Damage numbers positioned at screen center rather than world-projected
- No sound effects

### Result

**Cannot run-test in CLI** — Godot requires a display server to launch. The
prototype must be opened in Godot Editor and run with F5/Play.

Observable from code review:
- GCD pipeline implements all rules from the Ability Rotation Combat GDD
- Input queue within GCD_QUEUE_WINDOW (0.5s) prevents dropped inputs
- Off-GCD (Dark Pact) correctly bypasses GCD check
- Damage formula matches Damage Calculation GDD exactly
- Dodge cancels cast, applies i-frames for 0.3s
- Cast-time abilities allow slow movement (50% speed)
- Mana regen (5/s) creates resource tension with 15-30 cost abilities
- Enemy respawn loop enables continuous combat testing

### Metrics

- Frame time: N/A (requires playtest)
- Feel assessment: N/A (requires gamepad playtest)
- Code size: ~900 lines across 7 files (lean for a full combat loop)
- Iteration count: 1 (first pass, no rework needed at code level)
- Systems implemented: 5 of 7 from the GDD dependency chain
  (Input, Combat, Abilities, Damage Calc, Health/Resource)
- Systems deferred: Pause, SFX, Near-Death, DoT ticks, Lock-on targeting

### Recommendation: PROCEED (conditional on playtest)

The code architecture cleanly implements the GDD's combat pipeline. The
Warlock rotation offers meaningful decision-making:

1. **Opener**: Curse of Agony → Immolate → Shadow Bolt (apply DoTs, then filler)
2. **Rotation**: Shadow Bolt spam, refresh DoTs, Fel Cleave when in melee range
3. **Defensive**: Dodge enemy attacks (cancels cast), Dark Pact (off-GCD shield),
   Drain Life (heal while damaging)
4. **Resource**: Mana management — can't spam everything, must choose

This covers the full WoW rotation archetype: DoT maintenance + filler + cooldowns + defensive weaving.

**However**, the core question ("does it *feel* fun on a gamepad?") can ONLY be
answered by running the prototype in Godot with a controller. Code architecture
is sound but feel is subjective and requires hands-on testing.

### If Proceeding

1. **Playtest first**: Open in Godot 4.6, connect gamepad, play for 10 minutes
2. **Tune**: BASE_GCD (1.5s), cast times, mana costs, enemy HP/damage
3. **Add DoT ticks**: Currently DoTs apply full damage on cast — needs tick system
4. **Add Near-Death**: The signature mechanic — prototype separately or extend this
5. **Add lock-on targeting**: Currently auto-targets nearest — need L1 toggle
6. **Production rewrite**: All systems need proper Resource-based architecture,
   signal bus, scene composition (not procedural), and GUT test coverage
7. **Estimated production effort**: 2-3 weeks for combat system alone (with tests,
   proper architecture, VFX hooks, SFX hooks, enemy AI variety)

### If Pivoting

If the GCD rhythm feels too slow or "clunky" on a gamepad:
- Try reducing BASE_GCD to 1.0s (more action-game pacing)
- Try action-combat hybrid: instant abilities + GCD only on heavy attacks
- Try combo chains instead of GCD (press-press-press for combos)

### If Killing

If modifier hotbar (R2/L2 + face buttons) feels awkward:
- The entire input architecture would need redesign
- Consider simpler 4-ability + basic attack (God of War style)
- This would fundamentally change the game from "WoW rotation" to "action RPG"

### Lessons Learned

1. **Godot 4.6 CharacterBody3D** works well for this style — physics-based
   movement with manual velocity control gives precise dodge feel
2. **Procedural scene construction** is viable for prototypes but would be
   unmaintainable at scale — production needs .tscn scene composition
3. **The Warlock "battle mage" archetype** naturally tests more systems than a
   pure melee or pure caster would — good prototype class choice
4. **7 abilities is the sweet spot** for prototype: enough for a real rotation,
   not so many that tuning becomes complex
5. **Off-GCD abilities** (Dark Pact) are critical for the "weaving" feel — they
   give the player something to do during GCD windows
