# Character Stats

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-21
> **Implements Pillar**: Pillar 2 — Always Something New, Pillar 4 — Master of All Trades

## Overview

The Character Stats system defines the numerical foundation of the player
character -- primary attributes, derived stats, and the soft-cap scaling curve
that governs how powerful the character becomes over time. Every combat
calculation, ability effect, profession check, and difficulty scaling formula
reads from this system. The player interacts with it through class/mastery
choices that allocate stat points, gear that modifies stats, and profession
bonuses. Stats never hard-cap -- they use diminishing returns so the character
always grows, but old content eventually trivializes while new content remains
challenging.

## Player Fantasy

The player should feel like a **character who never stops growing**. Every stat
point invested, every piece of gear equipped, every mastery node unlocked should
feel like a meaningful step forward. The fantasy is building the ultimate
character across hundreds of hours -- not racing to a cap, but continuously
refining and expanding. Returning to an early zone should feel *powerful* ("I
remember when this was hard"). Entering a new zone should feel *challenged*
("I need to get stronger"). This serves Pillar 2 (Always Something New) -- the
stat curve IS the progression promise.

## Detailed Design

### Core Rules

**1. Primary Attributes (3)**

| Attribute | Abbreviation | What It Affects |
|-----------|-------------|-----------------|
| **Might** | MGT | Physical damage, block strength, HP scaling, armor scaling |
| **Finesse** | FNS | Critical chance, dodge chance, attack speed |
| **Intellect** | INT | Spell damage, resource pool scaling, magical crafting affinity bonus |

All 3 attributes matter to every class -- a mage benefits from Finesse (crit) and
Might (HP). No dump stats. No attribute affects carry capacity, gathering speed,
or movement speed -- those are universal.

**2. Derived Stats (calculated from primaries + gear + mastery)**

| Derived Stat | Formula Basis | Description |
|-------------|--------------|-------------|
| **Health (HP)** | Base + (MGT * scaling) + gear + mastery | Total hit points. Near-Death at 15%, death at 0. |
| **Resource** | Base + (Primary * scaling) + gear + mastery | Class-specific (mana, rage, energy, etc.). Primary attr depends on class. |
| **Physical Power** | MGT * power_scaling + gear | Scales physical ability damage |
| **Spell Power** | INT * power_scaling + gear | Scales magical ability damage |
| **Critical Chance** | Base + (FNS * crit_scaling) | Chance for abilities to critically strike |
| **Critical Damage** | 150% base + mastery bonuses | Damage multiplier on critical strikes |
| **Dodge Chance** | Base + (FNS * dodge_scaling) | Chance to avoid attacks entirely |
| **Armor** | Gear + (MGT * armor_scaling) | Reduces physical damage taken |
| **Resistance** | Gear + (INT * resist_scaling) | Reduces magical damage taken |
| **Attack Speed** | Base + (FNS * speed_scaling) | Modifies GCD and auto-attack speed |
| **Movement Speed** | Base + gear + mastery (NOT stat-derived) | Universal, not gated by attributes |

**3. Universal Features (NOT stat-gated)**

These features are equal for all characters regardless of attributes or class:
- **Inventory capacity**: Unlimited. No weight system, no bag slots. If you pick
  it up, you keep it. Organization is handled by categories, filters, and
  favorites -- never by artificial scarcity.
- **Gathering speed**: Same for all characters. Profession level may affect yield
  but not speed.
- **Movement speed**: Base is identical for all. Gear and mastery can enhance it.
- **Carry capacity**: Does not exist. No encumbrance system.

**4. Stat Progression (Auto-Increase)**

- Primary attributes increase automatically as the character progresses
- Each Power Level gained (from quests, mastery milestones, zone completions)
  grants a flat increase to ALL 3 primary stats
- No manual stat point allocation -- the player cannot make a "wrong" build
- Specialization comes from mastery trees (Class & Mastery System) which grant
  bonus percentages or flat bonuses to specific derived stats

**5. Mastery Respec**

- Free respec available at any **Cleric NPC** in towns
- Reallocates ALL mastery points -- full rebuild, not partial
- No cost, no cooldown, no penalty, no limit
- The player can experiment freely with builds at any time
- This is a non-negotiable Pillar 4 decision: investment is never wasted,
  mistakes are never permanent
- Respec preserves Power Level, gear, professions, quest progress -- only
  mastery point allocation changes

**6. Soft-Cap Scaling Curve**

Primary stats use a **logarithmic diminishing returns** curve for derived stat
conversion:
- Early investment has high impact (each point of MGT adds significant HP)
- Late investment has reduced but never zero impact (each point still adds HP,
  just less)
- There is no hard ceiling -- stats grow forever, just more slowly
- This creates the "powerful in old zones, challenged in new zones" feel

**7. Gear Stat Budget**

- Gear provides flat bonuses to primary and/or derived stats
- Gear does NOT use the soft-cap curve -- gear stats are additive
- This means gear remains impactful at all progression stages
- Gear from higher-level zones has higher stat budgets

**8. Power Level (Character Progression Metric)**

Instead of "levels" (which imply a cap), the game uses **Power Level** -- a number
that represents overall character progression:
- Increases from quest completion, zone milestones, mastery unlocks
- Has no maximum
- Determines which zones are appropriate (zone difficulty = suggested Power Level range)
- Drives auto-increase of primary attributes
- Is visible to the player as their primary progression number

**9. Crafting Stat Interaction**

- Crafting quality is primarily driven by **profession level** (Profession &
  Crafting System)
- Each craftable item has an **affinity attribute** (Might for heavy gear,
  Finesse for precision gear, Intellect for magical gear)
- The matching attribute provides a small bonus to crafting quality for that item
- You are naturally better at crafting things aligned with your build
- All characters can craft everything at full effectiveness through profession
  level -- the attribute bonus is an edge, not a gate

### States and Transitions

Character Stats is a stateless calculation system -- it reads inputs and outputs
derived values. No internal states. Recalculation triggers:

| Trigger | What Recalculates |
|---------|------------------|
| Power Level increases | All primary attributes, all derived stats |
| Gear equipped/unequipped | Affected derived stats only |
| Mastery node unlocked/respec'd | Affected derived stats only |
| Buff/debuff applied/removed | Affected derived stats (temporary modifier) |
| Class switched | Resource type changes, stat weights recalculated |

All recalculations are immediate -- no delay, no animation. The character sheet
updates instantly.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Health & Resource System** | Downstream | Reads HP and Resource derived values. Recalculates max HP/Resource on stat change events. |
| **Damage Calculation** | Downstream | Reads Physical Power, Spell Power, Crit Chance, Crit Damage, Armor, Resistance. |
| **Ability Database** | Downstream | Abilities reference primary attributes for scaling (e.g., "200% of Spell Power"). |
| **Class & Mastery System** | Upstream | Mastery trees provide bonus multipliers and flat bonuses. Class determines resource type. Respec resets mastery bonuses. |
| **Inventory / Gear** | Upstream | Equipped gear provides flat stat bonuses. Stat recalculation on equip/unequip. Inventory is unlimited (no carry stat). |
| **Profession & Crafting** | Downstream | Profession level is primary driver of crafting quality. Each item type has an affinity attribute (MGT/FNS/INT) that provides a small quality bonus. |
| **Enemy AI / Zone Scaling** | Downstream | Zone difficulty reads player Power Level to determine appropriate scaling. |
| **Input System** | Indirect | Near-Death (HP < 15%) triggers time dilation -- requires HP percentage from Health & Resource, which reads max HP from here. |
| **Menu System** | Downstream | Character sheet displays all stats, breakdowns by source (base, gear, mastery, buffs). |
| **Save/Load System** | Both | Saves Power Level, mastery allocations. Loads and recalculates all derived stats. |
| **NPC System** | Indirect | Cleric NPCs provide mastery respec service. |

## Formulas

### Primary Attribute Auto-Increase

```
attribute_value = BASE_ATTR + (power_level * ATTR_PER_LEVEL) + gear_bonus + mastery_bonus
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| BASE_ATTR | int | 10 | constant | Starting value for each primary attribute |
| power_level | int | 1 - unlimited | progression | Current Power Level |
| ATTR_PER_LEVEL | float | 2.0 | tuning knob | Flat attribute points gained per Power Level |
| gear_bonus | int | 0 - varies | equipped gear | Sum of gear bonuses to this attribute |
| mastery_bonus | int | 0 - varies | mastery tree | Sum of mastery node bonuses to this attribute |

**Example at Power Level 50**: 10 + (50 * 2) + 30 (gear) + 20 (mastery) = 160 Might

### Soft-Cap Derived Stat Scaling

```
derived_value = base_derived + SCALING_COEFF * ln(1 + attribute / SOFT_CAP_POINT) * attribute
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_derived | float | varies | constant | Minimum value of the derived stat |
| SCALING_COEFF | float | varies per stat | tuning knob | How strongly the attribute affects this derived stat |
| attribute | int | 10+ | calculated | The relevant primary attribute value |
| SOFT_CAP_POINT | float | 100 | tuning knob | Attribute value where diminishing returns become noticeable |

**Behavior**: Below SOFT_CAP_POINT, scaling is roughly linear. Above it,
each additional point gives less return. At 2x SOFT_CAP_POINT, each point
gives roughly 70% of its original value. At 5x, roughly 50%. Never reaches zero.

### Health Calculation

```
max_hp = BASE_HP + HP_SCALING * ln(1 + might / HP_SOFT_CAP) * might + gear_hp + mastery_hp
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| BASE_HP | int | 100 | Starting HP at Power Level 1 |
| HP_SCALING | float | 5.0 | How much Might affects HP |
| HP_SOFT_CAP | float | 100 | Where HP gains start diminishing |

**Example outputs**:
- Power Level 1 (10 MGT): ~100 + 5 * ln(1.1) * 10 = ~105 HP
- Power Level 50 (160 MGT): ~100 + 5 * ln(2.6) * 160 = ~865 HP
- Power Level 200 (500 MGT): ~100 + 5 * ln(6.0) * 500 = ~4,580 HP

### Critical Chance

```
crit_chance = BASE_CRIT + CRIT_SCALING * ln(1 + finesse / CRIT_SOFT_CAP) * finesse
crit_chance = min(crit_chance, CRIT_HARD_CAP)
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| BASE_CRIT | float | 5% | Everyone starts with 5% crit |
| CRIT_SCALING | float | 0.08 | How much Finesse affects crit |
| CRIT_SOFT_CAP | float | 100 | Where crit gains diminish |
| CRIT_HARD_CAP | float | 75% | Maximum achievable crit chance |

**Note**: Crit chance is the one derived stat with a hard cap (75%) to prevent
guaranteed crits from breaking encounter design.

### Power Level Scaling (Zone Difficulty)

```
zone_difficulty_ratio = player_power_level / zone_suggested_level
```

| Ratio | Player Experience |
|-------|------------------|
| < 0.8 | Significantly underleveled -- high risk, reduced rewards |
| 0.8 - 1.2 | Appropriately challenged -- full rewards |
| 1.2 - 2.0 | Overpowered -- enemies easier, still some challenge |
| > 2.0 | Trivial -- enemies fall quickly, minimal challenge (power fantasy) |

### Crafting Attribute Bonus

Each craftable item has an **affinity attribute** based on its type. The relevant
primary attribute provides a small quality bonus when crafting that item type:

```
crafting_quality_bonus = (affinity_attr - CRAFT_ATTR_BASELINE) * CRAFT_ATTR_SCALING
crafting_quality_bonus = max(0, crafting_quality_bonus)
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| affinity_attr | int | varies | The primary attribute matching the item's affinity |
| CRAFT_ATTR_BASELINE | int | 50 | Attribute below this gives no bonus |
| CRAFT_ATTR_SCALING | float | 0.05% per point | Bonus quality per point above baseline |

| Item Affinity | Attribute | Examples |
|--------------|-----------|----------|
| Physical gear (plate, weapons, shields) | Might | Heavy armor, swords, axes |
| Precision gear (leather, ranged, tools) | Finesse | Leather armor, bows, daggers, gathering tools |
| Magical gear (cloth, staves, potions) | Intellect | Robes, wands, scrolls, enchantments, potions |
| Universal items (food, furniture, basic) | None | No attribute bonus -- profession level only |

**Effect**: A warrior with high Might naturally crafts better plate armor. A mage
with high Intellect makes better potions. But profession level is always the
primary driver -- the attribute bonus is a slight edge, not a gate.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Attribute reaches 0 (debuff) | Clamp to 1. Derived stats recalculate with minimum. | 0 Might = 0 HP would instant-kill. Minimum of 1 prevents this. |
| Player respec all mastery points | All mastery bonuses removed. Derived stats recalculate. Gear stays equipped. | Clean slate -- if gear requirements exist, they're based on Power Level, not attributes. |
| Buff and debuff on same stat | Additive stacking. Buff +50 MGT and debuff -30 MGT = net +20 MGT. | Simple, predictable, no order-of-operations confusion. |
| Multiple gear pieces boosting same stat | All bonuses stack additively. No cap on gear stat totals. | Pillar 2: always reward getting better gear. |
| Class switch changes resource type | Resource pool recalculates using new class's primary attribute. Current resource resets to max. | Switching class mid-field should not leave player with 0 resource. |
| Power Level 1 character enters high-level zone | Stats are calculated normally. Zone difficulty ratio < 0.8 applies. Enemies are very dangerous but not gated. | Pillar 1: no hard gates. Player can attempt anything, but difficulty is real. |
| Negative derived stat from debuffs | Clamp all derived stats to 0 minimum (except HP which clamps to 1). Negative armor = 0 armor, not bonus damage taken. | Prevents exploits where stacking debuffs creates inverted effects. |
| Respec during combat | Not allowed -- Cleric NPCs are in towns, not in combat zones. If somehow triggered, queue for after combat ends. | Prevents mid-fight build swapping as an exploit. |
| Very high Power Level (1000+) | Formulas still function. Logarithmic curve means stats grow slowly but never overflow. Use 64-bit integers for stat values. | System must support infinite progression without numerical issues. |

## Dependencies

| System | Direction | Hard/Soft | Nature of Dependency |
|--------|-----------|-----------|---------------------|
| **Class & Mastery System** | Upstream | Soft | Mastery trees provide stat bonuses. Stats work without mastery (base + auto-increase). Respec signals stat recalculation. |
| **Inventory / Gear** | Upstream | Soft | Gear provides stat bonuses. Stats work without gear (base + auto-increase). Equip/unequip signals recalculation. |
| **Health & Resource System** | Downstream | Hard | Cannot calculate HP or Resource pool without Character Stats. |
| **Damage Calculation** | Downstream | Hard | Cannot compute damage without Physical/Spell Power, Crit, Armor, Resistance. |
| **Ability Database** | Downstream | Hard | Abilities scale from primary attributes and derived stats. |
| **Profession & Crafting** | Downstream | Soft | Crafting affinity bonus reads relevant attribute. Crafting works without it (profession level only). |
| **Enemy AI / Zone Scaling** | Downstream | Hard | Zone difficulty ratio reads Power Level. |
| **Menu System** | Downstream | Soft | Character sheet displays stats. Game works without the display. |
| **Save/Load System** | Both | Hard | Must serialize Power Level and mastery allocations. Must reconstruct derived stats on load. |
| **NPC System** | Indirect | Soft | Cleric NPCs provide respec. Not a data dependency. |
| **Input System** | Indirect | Soft | Near-Death threshold (15% HP) depends on max HP from this system, via Health & Resource. |

## Tuning Knobs

| Parameter | Default | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|---------|------------|-------------------|-------------------|
| BASE_ATTR | 10 | 5 - 20 | Stronger starting character | Weaker start, more growth needed |
| ATTR_PER_LEVEL | 2.0 | 1.0 - 5.0 | Faster stat growth per Power Level | Slower growth, more grind feel |
| SOFT_CAP_POINT | 100 | 50 - 300 | Diminishing returns kick in later (more linear growth) | Diminishing returns kick in earlier (flatter curve sooner) |
| BASE_HP | 100 | 50 - 200 | More HP at start | Less HP at start |
| HP_SCALING | 5.0 | 2.0 - 10.0 | Might gives more HP per point | Might gives less HP per point |
| BASE_CRIT | 5% | 1% - 10% | Everyone crits more at start | Lower base crit, more Finesse needed |
| CRIT_HARD_CAP | 75% | 50% - 95% | Higher achievable crit (more burst damage) | Lower max crit (more consistent damage) |
| CRAFT_ATTR_BASELINE | 50 | 20 - 100 | Higher bar before crafting bonus kicks in | Bonus starts earlier |
| CRAFT_ATTR_SCALING | 0.05%/pt | 0.01% - 0.2% | Stronger crafting bonus from matching attribute | Weaker bonus, more egalitarian crafting |

**Key interaction**: ATTR_PER_LEVEL and SOFT_CAP_POINT together control the
"feel" of progression. High ATTR_PER_LEVEL + high SOFT_CAP = long linear growth
before plateau. Low ATTR_PER_LEVEL + low SOFT_CAP = quick plateau then slow grind.
Tune these together, not independently.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Power Level up | Full-screen flash, Power Level number animates up | Level-up fanfare (WoW-style) | HIGH |
| Stat increase (any source) | Character sheet stat number pulses green | Subtle "stat up" chime | MEDIUM |
| Stat decrease (debuff) | Stat number pulses red | Subtle "stat down" tone | MEDIUM |
| Mastery respec complete | Swirl effect on character, "refreshed" visual | Cleansing/blessing sound | LOW |
| New Power Level milestone (every 10/25/50) | Special enhanced level-up effect | Grander fanfare variant | MEDIUM |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Power Level | HUD top-left, always visible | On change | Always |
| Power Level progress bar | HUD below Power Level number | On XP/milestone progress | Always |
| Primary attributes (3) | Character sheet | On stat change | Menu open |
| Derived stats (all) | Character sheet, expandable | On stat change | Menu open |
| Stat breakdown by source | Character sheet tooltip/detail | On hover/select | Menu open |
| Stat comparison (gear swap) | Inventory screen, green/red arrows | When comparing gear | Inventory open |
| Crafting affinity indicator | Crafting UI, per-recipe | When viewing recipe | Crafting station |

## Acceptance Criteria

- [ ] All 3 primary attributes increase correctly with Power Level (ATTR_PER_LEVEL * level)
- [ ] Soft-cap curve produces diminishing returns above SOFT_CAP_POINT
- [ ] HP scales correctly: ~105 at PL1, ~865 at PL50, ~4580 at PL200
- [ ] Crit chance respects hard cap of 75% regardless of Finesse value
- [ ] All derived stats recalculate instantly on gear equip/unequip
- [ ] All derived stats recalculate instantly on mastery respec
- [ ] Mastery respec at Cleric is free, no cooldown, preserves all non-mastery state
- [ ] Inventory has no capacity limit -- unlimited items
- [ ] Crafting affinity bonus applies correctly per item type (MGT/FNS/INT)
- [ ] No attribute can drop below 1 (debuff floor)
- [ ] No derived stat can go negative (floor at 0, HP floor at 1)
- [ ] Power Level has no maximum -- system works at PL 1000+
- [ ] 64-bit integers prevent overflow at extreme stat values
- [ ] Performance: full stat recalculation completes within 1ms
- [ ] Character sheet displays all stats with source breakdowns
- [ ] Zone difficulty ratio calculates correctly from Power Level vs zone level

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| What specific mastery tree bonuses exist? | Game Designer | During Class & Mastery System GDD | Mastery trees are the main vehicle for stat specialization |
| How do buffs/debuffs interact with the soft-cap curve? | Systems Designer | During Status Effects GDD | Do buffs add to raw attribute (pre-curve) or derived stat (post-curve)? Pre-curve is cleaner but less impactful at high stats. |
| Should there be stat-based equipment requirements? | Game Designer | During Inventory System GDD | Could gate gear by Power Level instead, which is simpler and aligns with Pillar 4. |
| What is the XP/progression curve for Power Level gains? | Systems Designer | During Class & Mastery System GDD | Defines how fast Power Level increases -- key to pacing feel. |
| How does class switching affect stat display? | UX Designer | During Menu System GDD | Show all-class stats or only active class's relevant stats? |
