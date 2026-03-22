# Ability Database

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-22
> **Implements Pillar**: Pillar 2 — Always Something New (infinite ability expansion)

## Overview

The Ability Database defines every ability in the game as data -- cast times,
cooldowns, resource costs, damage/healing values, range, target type, effects,
and visual/audio references. It uses a shared Global Cooldown (GCD) plus
individual ability cooldowns for WoW-style rotation depth. Like the Item Database,
abilities are defined as Godot Resource files for data-driven expansion. New
abilities are pure data -- no combat engine changes needed. The player interacts
with abilities via the 16-slot gamepad hotbar (Input System), and the combat
system reads ability data to execute effects.

## Player Fantasy

Every ability should feel like **wielding real power**. Pressing a button should
produce a clear, impactful result -- a fireball launches, an enemy staggers, health
returns. The fantasy of "mastering my rotation" comes from the timing puzzle: GCD
rhythm creates the heartbeat, cooldown management creates the strategy, and proc
effects create exciting moments of "my ability just became MORE powerful, use it
NOW." New abilities earned through mastery should feel like genuine upgrades that
expand your toolkit, not just bigger numbers on the same spell.

## Detailed Design

### Core Rules

**1. Ability Data Schema**

All abilities inherit from a base `AbilityData` Resource:

```
AbilityData (base)
├── DamageAbilityData (deals damage)
├── HealAbilityData (restores HP)
├── BuffAbilityData (applies beneficial effect)
├── DebuffAbilityData (applies harmful effect)
├── SummonAbilityData (creates entity -- pet, totem, etc.)
├── UtilityAbilityData (movement, teleport, stealth, etc.)
└── ComboAbilityData (chains into next ability on hit)
```

**2. Base Ability Properties (all abilities have these)**

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique identifier (e.g., `"warrior_mortal_strike"`) |
| `name` | String | Display name (e.g., "Mortal Strike") |
| `description` | String | Tooltip text with dynamic values |
| `icon` | Texture | Hotbar icon |
| `class_id` | String | Which class this ability belongs to |
| `required_mastery_level` | int | Mastery tier required to unlock |
| `resource_type` | Enum | Mana, Rage, Energy, Focus, None |
| `resource_cost` | int | Amount of resource consumed (0 = free) |
| `cast_time` | float | Seconds to cast (0 = instant) |
| `gcd_trigger` | bool | Does this ability trigger the Global Cooldown? |
| `cooldown` | float | Individual cooldown in seconds (0 = no cooldown) |
| `range` | float | Maximum range in meters (0 = melee/self) |
| `target_type` | Enum | Self, SingleEnemy, SingleAlly, AoEGround, AoEAroundSelf, AoECone, Projectile |
| `damage_type` | Enum | Physical, Fire, Frost, Arcane, Nature, Shadow, Holy, None |
| `is_builder` | bool | Generates resource on use (Rage builders, Focus builders) |
| `builder_amount` | int | Resource generated if is_builder=true |
| `is_off_gcd` | bool | Can be used during GCD (weaved between GCD abilities) |
| `animation_id` | String | Which character animation to play |
| `vfx_id` | String | Visual effect reference |
| `sfx_id` | String | Sound effect reference |
| `tags` | Array[String] | Flexible tagging (e.g., ["fire", "aoe", "dot", "mobility"]) |

**3. Damage Ability Properties (extends base)**

| Property | Type | Description |
|----------|------|-------------|
| `base_damage` | float | Base damage before scaling |
| `scaling_attribute` | Enum | MGT (Physical Power) or INT (Spell Power) |
| `scaling_coefficient` | float | Multiplier on the scaling stat (e.g., 2.0 = 200% of Spell Power) |
| `can_crit` | bool | Can this ability critically strike? |
| `num_hits` | int | Number of damage instances (1 = single hit, 3 = triple strike) |
| `dot_tick_interval` | float | If > 0, applies damage over time (seconds between ticks) |
| `dot_duration` | float | Total DoT duration |

**4. Heal Ability Properties (extends base)**

| Property | Type | Description |
|----------|------|-------------|
| `base_healing` | float | Base heal amount |
| `scaling_attribute` | Enum | Typically INT (Spell Power) |
| `scaling_coefficient` | float | Multiplier on scaling stat |
| `hot_tick_interval` | float | If > 0, heals over time |
| `hot_duration` | float | Total HoT duration |

**5. Buff/Debuff Ability Properties (extends base)**

| Property | Type | Description |
|----------|------|-------------|
| `effect_id` | String | Reference to Status Effect definition |
| `effect_duration` | float | How long the buff/debuff lasts |
| `stacks_max` | int | Maximum stack count (1 = no stacking) |

**6. Global Cooldown (GCD)**

- Most abilities trigger the GCD when used
- GCD duration: BASE_GCD (default 1.5s), modified by Attack Speed stat
- While GCD is active, other GCD-triggering abilities cannot be used
- Off-GCD abilities (`is_off_gcd = true`) can be used during the GCD
  - Examples: defensive cooldowns, movement abilities, some procs
- Input queue: ability pressed within GCD_QUEUE_WINDOW (0.5s, from Input System)
  before GCD ends will fire immediately when GCD expires

```
effective_gcd = BASE_GCD / (1 + attack_speed_bonus)
effective_gcd = max(effective_gcd, MIN_GCD)
```

**7. Builder / Spender Design**

Each class resource type has a builder/spender pattern:

| Resource | Builders | Spenders | Rhythm |
|----------|---------|----------|--------|
| Mana | Passive regen, mana potions | All mana abilities | Spend freely, manage pool |
| Rage | Basic attacks, taking damage | Powerful attacks | Build up → unleash |
| Energy | Constant passive regen | Quick strikes, combos | Rapid fire → wait → rapid fire |
| Focus | Basic attacks | Special shots, pet commands | Steady aim → powerful ability |

**8. Ability Slots and Assignment**

- 16 gamepad slots (Input System: R2/L2 + face/d-pad)
- Player assigns abilities to slots freely from their unlocked ability list
- Basic Attack (X button, unmodified) is a special auto-targeting ability:
  - Class-specific (sword swing for warrior, staff hit for mage, arrow for ranger)
  - No resource cost, no cooldown, triggers GCD
  - Is a builder for Rage and Focus resource types
- Abilities can be reassigned at any time (no restrictions, no cost)
- Empty slots show as empty on hotbar (no effect when pressed)

**9. Ability Unlocking**

- Abilities unlock through the Class & Mastery System (provisional -- GDD not yet written)
- Each class has a progression tree of abilities
- Early abilities unlock at low mastery levels (available quickly)
- Advanced abilities unlock at higher mastery levels
- Class-specific quest chains can unlock special/unique abilities (Pillar 6)
- Modifications (runes from Item Database) can grant entirely new abilities
  not tied to any class

**10. Expandability**

- New abilities: create new `.tres` Resource files -- no code changes
- New ability types: new Resource subclass extending AbilityData
- New damage types: add to damage_type enum
- New target types: add to target_type enum with targeting logic
- New resource types: extend Health & Resource System, add new generation rules
- Modification-granted abilities: same schema, just flagged with source="modification"

### States and Transitions

Ability definitions are static data. Ability **execution** has runtime states
managed by the Combat System (not this database):

| State | Description | Managed By |
|-------|-------------|-----------|
| Available | Off cooldown, sufficient resource, not on GCD | Ability Database + Combat |
| On Cooldown | Individual cooldown ticking | Combat System |
| On GCD | Global cooldown active | Combat System |
| Casting | Cast bar in progress (for non-instant abilities) | Combat System |
| Insufficient Resource | Not enough mana/rage/energy/focus | Health & Resource System |
| Locked | Not yet unlocked via mastery | Class & Mastery System |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Character Stats** | Upstream | Reads Physical Power, Spell Power, Attack Speed for scaling and GCD calculation. |
| **Item Database** | Upstream | Modification runes can reference ability IDs to grant abilities. |
| **Health & Resource System** | Both | Checks resource availability before use. Consumes resource on use. Builders add resource. Heals restore HP. |
| **Ability Rotation Combat** | Downstream | Combat system reads AbilityData to execute effects (damage, healing, buffs). Manages GCD and cooldown timers. |
| **Damage Calculation** | Downstream | Reads base_damage, scaling_coefficient, damage_type, can_crit to compute final damage. |
| **Status Effects** | Downstream | Buff/debuff abilities reference effect definitions. |
| **Class & Mastery System** | Upstream | Determines which abilities are unlocked. Mastery may modify ability properties. |
| **Input System** | Upstream | Slot activation signals (slot_1_pressed etc.) trigger ability lookup → execution. |
| **HUD System** | Downstream | Hotbar displays ability icons, cooldown timers, resource costs, availability state. |
| **SFX/VFX** | Downstream | Each ability references VFX and SFX by ID for combat feedback. |

## Formulas

### Ability Damage (delegated to Damage Calculation GDD)

```
raw_damage = base_damage + (scaling_stat * scaling_coefficient)
```

| Variable | Type | Source | Description |
|----------|------|--------|-------------|
| base_damage | float | AbilityData | Flat damage before scaling |
| scaling_stat | float | Character Stats | Physical Power or Spell Power |
| scaling_coefficient | float | AbilityData | How strongly the ability scales |

Final damage (after crit, armor, resistance) is handled by the Damage Calculation
system -- not this database. This database provides the raw inputs.

### Effective GCD

```
effective_gcd = BASE_GCD / (1 + attack_speed_bonus)
effective_gcd = clamp(effective_gcd, MIN_GCD, BASE_GCD)
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| BASE_GCD | float | 1.5s | Standard GCD duration |
| MIN_GCD | float | 0.75s | Fastest possible GCD (prevents ability spam) |
| attack_speed_bonus | float | 0.0+ | From Character Stats (Finesse scaling) |

**Example**: 30% attack speed bonus → 1.5 / 1.3 = 1.15s GCD.

### DoT/HoT Tick Damage

```
tick_damage = (base_damage + scaling_stat * scaling_coefficient) / num_ticks
num_ticks = dot_duration / dot_tick_interval
```

Total DoT damage equals a single-hit ability of equivalent power, spread over
the duration. This ensures DoTs and direct damage are balanced.

### Resource Cost Scaling

Resource costs are flat values defined per ability -- they do NOT scale with
Power Level. This means:
- Early game: resource feels tight (costs are large relative to pool)
- Late game: resource feels abundant (pool grew, costs stayed flat)
- This is intentional: high-mastery characters should feel resource-empowered

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Ability pressed with insufficient resource | Ability doesn't fire. Hotbar icon flashes red. No error sound (anti-frustration). | Clear visual feedback, not punishing |
| Ability pressed during GCD | Input queued (max 1). Fires when GCD expires. | From Input System: GCD_QUEUE_WINDOW = 0.5s |
| Off-GCD ability pressed during GCD | Fires immediately. Does not affect GCD timer. | Off-GCD is explicitly designed for weaving |
| Cast-time ability interrupted by dodge | Cast cancelled. Resource NOT consumed (only on successful cast). | Dodge is an escape -- don't punish using it |
| Cast-time ability interrupted by damage | Cast continues (no pushback). | Anti-frustration for solo play. No healer to protect you while casting. |
| Two abilities assigned to same slot | Not allowed -- slot assignment UI prevents duplicates | Same as Input System edge case |
| Ability removed from hotbar while on cooldown | Cooldown continues. Re-assigning shows remaining cooldown. | Cooldowns are per-ability, not per-slot |
| DoT reapplied before expiry | Refreshes duration, does NOT stack (unless explicitly stackable). Tick damage uses new application's values. | Pandemic-style refresh (WoW standard) |
| Ability unlocked mid-combat | Available immediately. Player can assign to empty slot. | No wait -- excitement of new ability should be instant |
| Modification rune grants ability player already has | Both exist independently. Class version and rune version can both be on hotbar. | Rune version may have different properties |
| Basic Attack with no target in range | Character plays attack animation in facing direction. Hits nothing. No resource change. | Don't lock the player out of attacking |

## Dependencies

| System | Direction | Hard/Soft | Nature |
|--------|-----------|-----------|--------|
| **Character Stats** | Upstream | Hard | Cannot calculate scaling damage/healing without stats |
| **Item Database** | Upstream | Soft | Rune modifications can grant abilities. Database works without. |
| **Health & Resource System** | Both | Hard | Must check and consume resource. Builders must add resource. |
| **Ability Rotation Combat** | Downstream | Hard | Combat system is the execution engine for ability data |
| **Damage Calculation** | Downstream | Hard | Processes raw ability damage into final damage |
| **Status Effects** | Downstream | Soft | Buff/debuff abilities reference effects. Works without (just no buffs). |
| **Class & Mastery System** | Upstream | Soft | Determines unlocks. All abilities work without (just all unlocked for testing). |
| **Input System** | Upstream | Hard | Slot activation signals trigger ability lookup |
| **HUD System** | Downstream | Soft | Displays ability data on hotbar |

## Tuning Knobs

| Parameter | Default | Safe Range | Increase | Decrease |
|-----------|---------|------------|----------|----------|
| BASE_GCD | 1.5s | 1.0-2.5 | Slower rotation, more deliberate | Faster, more frantic |
| MIN_GCD | 0.75s | 0.5-1.0 | Allows faster rotations with speed gear | Caps rotation speed lower |
| Per-ability base_damage | Varies | Per class balance | Stronger ability | Weaker ability |
| Per-ability resource_cost | Varies | Per class balance | More expensive (use sparingly) | Cheaper (spam more) |
| Per-ability cooldown | Varies | 0-300s | Used less often, more impactful | Used more often, less impactful |
| Per-ability scaling_coefficient | Varies | 0.5-5.0 | Scales harder with gear/stats | Less gear-dependent |

**Note**: Individual ability tuning is per-ability in the Resource files.
These are authored by designers, not global knobs. The global knobs (GCD, MIN_GCD)
affect ALL abilities uniformly.

## Visual/Audio Requirements

| Event | Visual | Audio | Priority |
|-------|--------|-------|----------|
| Ability cast start | Cast bar appears (if cast_time > 0) | Cast start sound | HIGH |
| Ability fires | VFX plays (referenced by vfx_id) | SFX plays (referenced by sfx_id) | HIGH |
| Ability hits target | Impact VFX at target | Impact sound | HIGH |
| Ability on cooldown (pressed) | Hotbar icon flashes dimmed | None (silent -- anti-frustration) | MEDIUM |
| Ability insufficient resource | Hotbar icon flashes red | None (silent) | MEDIUM |
| GCD active | Sweep animation on hotbar icons | None | LOW |
| Ability unlocked | "New Ability" popup, icon glow | Unlock fanfare | HIGH |
| DoT/HoT tick | Small periodic VFX on target | Subtle tick sound | LOW |

## UI Requirements

| Information | Location | Update | Condition |
|-------------|----------|--------|-----------|
| Ability icon + keybind | Hotbar (16 slots) | On assignment | Always in gameplay |
| Cooldown sweep (radial) | Over ability icon | Per frame | On cooldown |
| GCD sweep (radial) | Over all GCD-ability icons | Per frame | GCD active |
| Resource cost | Tooltip | On hover/select | Ability details |
| Damage/healing numbers | Tooltip (dynamic, uses current stats) | On stat change | Ability details |
| "Not enough resource" | Icon flash red | On failed use | Insufficient resource |
| Cast bar | HUD center | During cast | Cast_time > 0 |
| Ability list (assignment) | Character sheet > Abilities tab | On unlock | Menu |

## Acceptance Criteria

- [ ] All ability types (Damage, Heal, Buff, Debuff, Summon, Utility, Combo) load from Resource files
- [ ] GCD triggers correctly: 1.5s base, reduced by Attack Speed, minimum 0.75s
- [ ] Off-GCD abilities fire during active GCD without affecting GCD timer
- [ ] Resource cost checked before execution; ability blocked if insufficient
- [ ] Resource consumed only on successful cast (not on cancellation/dodge)
- [ ] Cast-time abilities are NOT interrupted by taking damage
- [ ] Cast-time abilities ARE cancelled by dodge
- [ ] Input queue works: ability pressed during GCD fires when GCD expires
- [ ] Builder abilities generate correct resource amount
- [ ] DoT/HoT abilities tick at correct intervals for correct duration
- [ ] DoT refresh extends duration without stacking (pandemic behavior)
- [ ] Ability scaling produces correct damage: base + (stat * coefficient)
- [ ] New abilities can be added as Resource files without code changes
- [ ] Hotbar displays correct cooldown state, GCD state, and resource availability
- [ ] Performance: ability lookup + data read < 0.1ms
- [ ] 200+ abilities can be loaded without performance impact

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Should abilities have talent-style modifications (pick between 2 versions)? | Game Designer | During Class & Mastery GDD | E.g., Fireball vs Frostfire Bolt as a talent choice |
| How do combo abilities chain? (Press once = Ability A, press again within window = Ability B) | Game Designer | During Combat System GDD | ComboAbilityData needs chain definition |
| Should abilities have "ranks" that increase with mastery? | Systems Designer | During Class & Mastery GDD | Rank 1 Fireball → Rank 5 Fireball with scaling base_damage |
| Pet abilities: same schema or separate? | Game Designer | During Pet System GDD | Likely same schema with class_id = pet class |
| Should some abilities change based on world-state? | Narrative Director | During World-State GDD | E.g., ability empowered after completing a specific zone |
