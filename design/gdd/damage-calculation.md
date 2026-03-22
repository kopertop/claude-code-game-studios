# Damage Calculation

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-22
> **Implements Pillar**: Pillar 2 — Always Something New (gear/stats always matter)

## Overview

The Damage Calculation system is the math engine that converts ability data and
character stats into final damage and healing numbers. It processes a multi-layer
pipeline: raw ability output, critical strike check, damage type multipliers,
armor/resistance reduction with diminishing returns, and final application to the
target's Health & Resource system. This system is pure computation with no state
-- it receives inputs, runs the formula, and returns a result. Both player
abilities and enemy attacks use the same pipeline.

## Player Fantasy

The player should feel that **every stat point, every gear upgrade, every mastery
node meaningfully increases their power**. When they equip a new weapon, they
should see bigger numbers. When they crit, it should feel exciting. When they
face a heavily armored boss, they should feel the resistance and adapt (use
armor-piercing abilities, switch damage types). The numbers should be large enough
to feel impactful but not so large they become meaningless.

## Detailed Design

### Core Rules

**1. Damage Pipeline (in order)**

```
Step 1: Raw Damage = base_damage + (scaling_stat * scaling_coefficient)
Step 2: Critical Check → if crit, multiply by crit_damage_multiplier
Step 3: Damage Type Modifier → multiply by target's vulnerability/resistance to damage_type
Step 4: Armor/Resistance Reduction → reduce by target's armor (physical) or resistance (magical)
Step 5: Final Damage = max(1, result)  → minimum 1 damage (no zero-damage hits)
Step 6: Apply to target HP via Health & Resource System
```

**2. Healing Pipeline**

```
Step 1: Raw Healing = base_healing + (scaling_stat * scaling_coefficient)
Step 2: Critical Check → if crit, multiply by crit_damage_multiplier (crits apply to heals too)
Step 3: Healing Modifier → multiply by any healing-received buffs/debuffs
Step 4: Final Healing = result (no minimum — 0 healing is valid if fully debuffed)
Step 5: Apply to target HP via Health & Resource System
```

**3. Critical Strike**

```
roll = random(0.0, 1.0)
is_crit = roll < crit_chance AND ability.can_crit
if is_crit:
    damage *= crit_damage_multiplier
```

- crit_chance from Character Stats (Finesse-derived, capped at 75%)
- crit_damage_multiplier: base 150% + mastery bonuses
- Crits apply to both damage and healing
- Crits trigger special VFX and damage number color (gold instead of white)

**4. Damage Types**

| Type | Resisted By | Examples |
|------|------------|---------|
| Physical | Armor | Sword hits, arrow shots, shield bash |
| Fire | Resistance | Fireball, flame DoT, fire enchantment |
| Frost | Resistance | Ice lance, frost nova, slow effects |
| Arcane | Resistance | Arcane missiles, mana drain |
| Nature | Resistance | Poison, thorns, lightning |
| Shadow | Resistance | Shadow bolt, life drain, fear |
| Holy | Resistance | Smite, heal, purify |

Physical damage is reduced by Armor. All magical types are reduced by Resistance.
No per-element resistance (simplicity) — just one Resistance stat.

**5. Armor Reduction (Diminishing Returns)**

```
damage_reduction = armor / (armor + ARMOR_CONSTANT + (attacker_power_level * ARMOR_LEVEL_SCALING))
final_physical_damage = raw_damage * (1 - damage_reduction)
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| armor | int | varies | Target's armor value (from Character Stats: gear + MGT scaling) |
| ARMOR_CONSTANT | float | 500 | Controls the curve shape — higher = armor less effective |
| ARMOR_LEVEL_SCALING | float | 10 | Higher-level attackers bypass more armor |

**Diminishing returns behavior**: At 500 armor vs a PL1 attacker (constant=500+10):
500/(500+510) = ~49% reduction. At 1000 armor: 1000/(1000+510) = ~66%. At 2000:
~80%. Approaches but never reaches 100%.

**6. Resistance Reduction (Same Formula)**

```
magic_reduction = resistance / (resistance + RESIST_CONSTANT + (attacker_power_level * RESIST_LEVEL_SCALING))
final_magic_damage = raw_damage * (1 - magic_reduction)
```

Same formula as armor but with separate tuning constants.

**7. Minimum Damage**
- All damage is floored at 1 (after all reductions)
- No zero-damage hits — the player should always feel they're doing something
- This prevents extreme armor stacking from making enemies invulnerable

**8. Damage Numbers Display**
- White numbers: normal damage
- Gold numbers: critical damage (larger font)
- Red numbers: damage taken by player
- Green numbers: healing
- Numbers float upward from target and fade
- Multiple hits show stacked/offset numbers to prevent overlap

### States and Transitions

No states. This is a pure function system: inputs → formula → output.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Ability Database** | Upstream | Reads base_damage, scaling_coefficient, scaling_attribute, damage_type, can_crit, num_hits |
| **Character Stats** | Upstream | Reads Physical Power, Spell Power, Crit Chance, Crit Damage, Armor, Resistance, Attack Speed |
| **Health & Resource System** | Downstream | Sends final damage/healing amount to apply_damage() or apply_healing() |
| **Status Effects** | Both | Reads damage modifiers (vulnerability, damage boost buffs). DoTs call damage calc per tick. |
| **Ability Rotation Combat** | Upstream | Combat system triggers damage calculation when ability hits target |
| **HUD System** | Downstream | Sends damage numbers (amount, type, is_crit) for floating combat text |
| **SFX System** | Downstream | Sends hit type for impact sound selection (normal, crit, resist-heavy) |
| **Enemy AI** | Both | Enemy attacks use same pipeline. Enemy stats feed into same formulas. |

## Formulas

### Complete Damage Formula

```
raw = ability.base_damage + (scaling_stat * ability.scaling_coefficient)
after_crit = raw * (crit_multiplier if is_crit else 1.0)
after_type = after_crit * damage_type_modifier
if ability.damage_type == Physical:
    reduction = target.armor / (target.armor + ARMOR_CONSTANT + attacker.power_level * ARMOR_LEVEL_SCALING)
else:
    reduction = target.resistance / (target.resistance + RESIST_CONSTANT + attacker.power_level * RESIST_LEVEL_SCALING)
final = max(1, after_type * (1 - reduction))
```

### Example Calculations

**Early game (PL 10, MGT 30, no gear)**:
- Mortal Strike: base=10, coeff=1.5, Physical Power=30
- Raw: 10 + (30 * 1.5) = 55
- No crit: 55
- Target armor 50: 50/(50+500+100) = 7.7% reduction → 55 * 0.923 = ~51 damage

**Mid game (PL 100, INT 250, good gear)**:
- Fireball: base=50, coeff=2.0, Spell Power=250
- Raw: 50 + (250 * 2.0) = 550
- Crit (150%): 550 * 1.5 = 825
- Target resistance 200: 200/(200+500+1000) = 11.8% reduction → 825 * 0.882 = ~728 damage

**Late game (PL 500, MGT 800, legendary gear)**:
- Mortal Strike rank 5: base=200, coeff=2.5, Physical Power=800
- Raw: 200 + (800 * 2.5) = 2200
- Crit (200% from mastery): 2200 * 2.0 = 4400
- Target armor 1000: 1000/(1000+500+5000) = 15.4% reduction → 4400 * 0.846 = ~3722 damage

### Complete Healing Formula

```
raw = ability.base_healing + (scaling_stat * ability.scaling_coefficient)
after_crit = raw * (crit_multiplier if is_crit else 1.0)
after_modifier = after_crit * healing_received_modifier
final = max(0, after_modifier)
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Damage after all reductions < 1 | Floor to 1. Always deal minimum 1 damage. | No invulnerable targets |
| Healing on full HP target | Clamped to max HP. Overheal amount discarded. | No overheal mechanic |
| Crit on a DoT tick | Each tick rolls independently for crit | More exciting DoTs |
| Multi-hit ability (num_hits=3) | Each hit runs full pipeline independently | Each can crit separately |
| Negative armor (from debuff) | Treat as 0 armor. No damage amplification from negative armor. | Prevents exploit; use vulnerability debuffs instead |
| Damage to invulnerable target (Respawn Potion) | Damage = 0. Bypasses entire pipeline. | Invulnerability is absolute |
| Self-damage (environmental, fall) | Uses same pipeline but no armor/resistance reduction (true damage) | Environmental damage ignores defense |
| Reflect damage (future ability type) | Reflected damage uses original attacker's stats, not reflector's | Prevents reflect loops |

## Dependencies

| System | Direction | Hard/Soft | Nature |
|--------|-----------|-----------|--------|
| **Ability Database** | Upstream | Hard | Cannot calculate without ability data |
| **Character Stats** | Upstream | Hard | Cannot calculate without stat values |
| **Health & Resource System** | Downstream | Hard | Must apply result to HP |
| **Status Effects** | Both | Soft | Modifiers from buffs/debuffs. Works without (just no modifiers). |
| **Combat System** | Upstream | Hard | Triggers calculation on ability hit |
| **HUD System** | Downstream | Soft | Floating damage numbers. Game works without display. |
| **SFX System** | Downstream | Soft | Impact sounds. Works silent. |

## Tuning Knobs

| Parameter | Default | Range | Increase | Decrease |
|-----------|---------|-------|----------|----------|
| ARMOR_CONSTANT | 500 | 200-2000 | Armor less effective (more damage gets through) | Armor more effective (tankier) |
| ARMOR_LEVEL_SCALING | 10 | 5-30 | Higher-PL attackers bypass more armor | Armor stays relevant longer |
| RESIST_CONSTANT | 500 | 200-2000 | Resistance less effective | Resistance more effective |
| RESIST_LEVEL_SCALING | 10 | 5-30 | Higher-PL casters bypass more resistance | Resistance stays relevant |
| BASE_CRIT_MULTIPLIER | 1.5 (150%) | 1.25-2.5 | Crits hit harder (spikier combat) | Crits matter less (smoother) |
| MIN_DAMAGE | 1 | 0-5 | Higher damage floor | Lower floor (0 = possible zero-damage) |

**Key interaction**: ARMOR_CONSTANT and Character Stats' HP_SCALING together
determine time-to-kill. More armor reduction = faster kills. Higher HP = slower
kills. Tune together for target TTK at each Power Level.

## Visual/Audio Requirements

| Event | Visual | Audio | Priority |
|-------|--------|-------|----------|
| Normal damage dealt | White floating number | Standard impact | HIGH |
| Critical damage dealt | Gold floating number (larger, bounce animation) | Enhanced impact + crit SFX | HIGH |
| Damage received | Red floating number + screen flash | Pain grunt / impact | HIGH |
| Healing received | Green floating number + green glow | Heal chime | HIGH |
| Resisted (high armor reduction) | Smaller number, "reduced" indicator | Dull impact (armor clang) | MEDIUM |
| Minimum damage (1) | Tiny "1" with "absorbed" indicator | Shield/armor ping | LOW |

## UI Requirements

| Information | Location | Update | Condition |
|-------------|----------|--------|-----------|
| Floating damage/healing numbers | Above target (world space) | Per damage event | Combat |
| DPS meter (optional) | HUD corner or character sheet | Rolling average | User preference |
| Damage breakdown (tooltip) | Ability tooltip or combat log | On hover | Menu/log |

## Acceptance Criteria

- [ ] Damage pipeline processes all 6 steps in correct order
- [ ] Raw damage = base + (stat * coefficient) matches Ability Database values
- [ ] Crit rolls correctly against crit_chance, applies crit_multiplier
- [ ] Armor diminishing returns formula produces correct reduction percentages
- [ ] At 500 armor vs PL1: ~49% reduction. At 2000 armor: ~80% reduction.
- [ ] Resistance uses same formula with separate constants
- [ ] Minimum damage of 1 enforced (no zero-damage hits)
- [ ] Healing pipeline works: raw heal * crit * modifier, clamped to max HP
- [ ] Multi-hit abilities calculate each hit independently
- [ ] DoT ticks each roll for crit independently
- [ ] Enemy attacks use same pipeline as player abilities
- [ ] Invulnerability (Respawn Potion) blocks all damage
- [ ] Floating damage numbers display correctly (color, size, crit indicator)
- [ ] Performance: damage calculation < 0.01ms per event

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Should there be per-element resistances later? | Game Designer | Post-Alpha evaluation | Currently one Resistance stat for all magic. Per-element adds depth but complexity. |
| Damage type vulnerability system? (Fire enemies weak to Frost) | Game Designer | During Enemy AI GDD | Would add a per-enemy damage_type_modifier table. Increases build diversity. |
| Should there be a combat log? | UX Designer | During HUD System GDD | Useful for rotation optimization, common in MMO-style games |
| Overkill tracking? (For "kill this in one hit" achievements) | Game Designer | During Collection System GDD | Low priority but fun for achievement hunters |
