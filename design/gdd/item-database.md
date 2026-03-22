# Item Database

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-21
> **Implements Pillar**: Foundation for all pillars (every item-touching system reads from here)

## Overview

The Item Database is the central data repository defining every item in the game.
It is designed for **infinite expandability** -- new item types, categories,
modifications, and content can be added without restructuring existing data.
Items follow a clear vertical progression (better zone = better gear, always),
while modifications (gems, enchantments) add lateral fun abilities without
replacing power. The player never agonizes over item choices -- upgrades are
obvious, and modifications are additive excitement.

## Player Fantasy

The player should feel an **endless stream of exciting discoveries**. Every zone
should bring clearly better gear. Every crafting milestone should unlock items
that make old ones obsolete. The fantasy is "I'm always finding something better"
-- not "I'm choosing between two equally mediocre options." Modifications (gems,
enchantments) are the creative layer -- they don't replace stats, they add
**abilities that change how you play**: wings, teleportation, elemental effects,
pet enhancements. The item system should feel as expandable as WoW's -- new
expansions bring new tiers, new modification types, and new item categories
that didn't exist before. Boredom is the enemy; expansion is the solution.

## Detailed Design

### Core Rules

**1. Item Type Hierarchy**

All items inherit from a base `ItemData` Resource. Subtypes extend it with
type-specific properties. New item types are new Resource subclasses -- no
existing code changes needed for expansion.

```
ItemData (base)
├── EquipmentData (weapons, armor, accessories)
│   ├── WeaponData
│   ├── ArmorData
│   └── AccessoryData
├── ConsumableData (potions, food, scrolls)
├── MaterialData (crafting ingredients, gathered resources)
├── RecipeData (crafting recipes -- learned, not consumed)
├── ModificationData (gems, enchantments, runes)
├── QuestItemData (key items, story items)
├── FurnitureData (homestead items)
└── CollectibleData (lore items, mounts, cosmetics)
```

**2. Base Item Properties (all items have these)**

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique identifier (e.g., `"sword_iron_01"`) |
| `name` | String | Display name (e.g., "Iron Longsword") |
| `description` | String | Flavor text / gameplay description |
| `icon` | Texture | Inventory icon |
| `item_type` | Enum | Which subtype (Equipment, Consumable, Material, etc.) |
| `rarity` | Enum | Starter, Common, Uncommon, Rare, Epic, Legendary |
| `zone_tier` | int | Which zone tier this item belongs to (determines base power) |
| `sell_value` | int | Gold value when sold to vendor |
| `is_unique` | bool | Can only hold 1 of this item (quest items, legendaries) |
| `lore_entry` | String | Optional lore text for the Collection system |
| `tags` | Array[String] | Flexible tagging for filtering/searching (e.g., ["fire", "two-handed", "crafted"]) |

**3. Equipment Properties (extends base)**

| Property | Type | Description |
|----------|------|-------------|
| `equipment_slot` | Enum | Head, Chest, Legs, Feet, Hands, Shoulder, Back, MainHand, OffHand, Ring1, Ring2, Necklace, Trinket (expandable -- new zones can add new slot types) |
| `stat_bonuses` | Dict{Stat: int} | Flat bonuses to primary/derived stats |
| `required_power_level` | int | Minimum Power Level to equip |
| `crafting_affinity` | Enum | Might, Finesse, Intellect, None |
| `modification_slots` | int | Number of gem/enchant slots (determined by rarity) |
| `installed_modifications` | Array[ModificationData] | Currently socketed mods (runtime state) |
| `visual_model` | Resource | 3D model/appearance for the character |
| `transmog_visual` | Resource | Override visual (if player has applied transmog). Null = use own visual. |

**4. Rarity Tiers**

| Rarity | Color | Stat Budget Multiplier | Modification Slots | How You Get It |
|--------|-------|----------------------|-------------------|----------------|
| Starter | Grey | 0.7x | 0 | Starting gear, tutorial rewards |
| Common | White | 1.0x | 0 | Early quest rewards, vendor purchases |
| Uncommon | Green | 1.3x | 1 | Quest rewards (mid-zone) |
| Rare | Blue | 1.6x | 2 | Major quest rewards, boss kills |
| Epic | Purple | 2.0x | 3 | Zone climax quest, rare boss drops |
| Legendary | Orange | 2.5x | 4 | Zone completion reward ONLY (one per zone) |

Rarity is strictly vertical: higher rarity within the same zone tier is ALWAYS
better in raw stats. No sidegrades.

**5. Item Acquisition Rules**

| Source | What You Get |
|--------|-------------|
| Enemy kills | Materials, consumables, gold. **NEVER gear.** |
| Quest rewards | Gear (primary source), recipes, consumables, materials |
| Boss kills | Gear (guaranteed, high rarity), rare materials, recipes |
| Zone completion | ONE Legendary item (specific slot per zone, unique) |
| Crafting | Gear, consumables, modifications, furniture |
| Gathering | Materials only |
| Vendors | Common/Uncommon gear, consumables, materials, recipes |

Gear is primarily earned through **quests and boss fights**, not random drops.
This ensures every piece of gear feels like an achievement, not a slot machine.

**6. Zone-Focused Gear Slots**

Each zone focuses on specific gear slots. Completing a zone's questline rewards
gear for those slots, culminating in a Legendary for one specific slot:

| Zone | Focus Slots | Legendary Slot |
|------|------------|---------------|
| Zone 1 | MainHand, Chest | MainHand (Legendary Weapon) |
| Zone 2 | Head, Legs | Head (Legendary Helm) |
| Zone 3 | Shoulder, Hands, Feet | Shoulder (Legendary Pauldrons) |
| [etc.] | [designed per zone] | [one per zone] |

A **full Legendary set requires completing every zone** -- a long-term goal that
drives exploration across the entire world. New zones added via expansions can
introduce entirely new gear slots (Tattoos, Tabards, Earrings, etc.) that
didn't exist before.

**7. Zone Tier Power Scaling**

```
item_stat_budget = ZONE_BASE_BUDGET * zone_tier * rarity_multiplier
```

| Rule | Description |
|------|-------------|
| Zone determines base stat budget | Zone 1: ~10-30 stats. Zone 5: ~100-200 stats. |
| Higher zone = strictly better base | A Common from Zone 3 > Rare from Zone 1 in raw stats |
| Rarity multiplies within zone | Same zone, higher rarity = always better |
| Cross-zone, tier always wins | Zone tier > rarity for raw power |

**8. Transmog System**

- Every equipment slot stores TWO references: stats source and visual source
- **Changing visual appearance is free, instant, and available anywhere**
- No vendor, no consumable, no currency -- open the character menu, pick a look
- Any previously owned item's appearance can be applied to any slot of the same
  type (weapon visual on weapon slot, armor visual on armor slot)
- Visual appearances are permanently unlocked when an item is first obtained
  (added to a "wardrobe" collection -- the item itself can be sold/destroyed)
- Transmog persists through gear upgrades -- equipping new stats doesn't reset look

**9. Modification System (Gems, Enchantments, Runes)**

Modifications socket into equipment modification slots. They add abilities and
effects, never replace or reduce base stats:

| Type | What It Does | Examples |
|------|-------------|----------|
| **Gems** | Passive stat bonuses (small) + visual flair | Ruby of Flame (+2% fire damage, weapon glows red) |
| **Enchantments** | Active or triggered abilities | "On hit: 10% chance to teleport behind enemy" |
| **Runes** | Transformative gameplay effects | "Grants double jump", "Attacks heal for 5% dealt" |

Rules:
- **Additive only** -- never removes or replaces base stats
- **Removable and reusable** -- unsocket without destruction
- **Stackable where logical** -- 2x fire gems = more fire damage
- **Never a trade-off** -- adding a mod never makes you weaker
- **Expandable** -- new modification types added via new ModificationData subclasses

**10. Consumable Properties (extends base)**

| Property | Type | Description |
|----------|------|-------------|
| `effect_type` | Enum | Heal, RestoreResource, Buff, Teleport, Respawn, Utility |
| `effect_value` | float | Magnitude of the effect |
| `effect_duration` | float | Duration in seconds (0 = instant) |
| `cooldown` | float | Shared cooldown per effect_type |
| `is_quick_slottable` | bool | Can assign to D-Pad quick item slots |

Key consumables: Health Potion, Resource Potion (quick-slottable), Respawn
Potion (revive in place -- see Input System GDD).

**11. Material Properties (extends base)**

| Property | Type | Description |
|----------|------|-------------|
| `material_type` | Enum | Ore, Herb, Leather, Wood, Cloth, Gem, Essence, etc. |
| `gathering_skill` | Enum | Mining, Herbalism, Skinning, Woodcutting, etc. |
| `min_gathering_level` | int | Minimum profession level to gather |

**12. Recipe Properties (extends base)**

| Property | Type | Description |
|----------|------|-------------|
| `ingredients` | Array[{item_id, quantity}] | Required materials |
| `result_item_id` | String | What this recipe produces |
| `result_quantity` | int | How many items produced |
| `profession` | Enum | Which profession crafts this |
| `required_profession_level` | int | Minimum profession level |
| `discovery_method` | Enum | QuestReward, Trainer, WorldDrop, Experimentation |

**13. Data Format and Storage**

- Items defined as Godot `.tres` Resource files
- Each item type has a corresponding custom Resource class (GDScript)
- Stored in `assets/data/items/` organized by type:
  ```
  assets/data/items/
  ├── equipment/weapons/
  ├── equipment/armor/
  ├── equipment/accessories/
  ├── consumables/
  ├── materials/
  ├── recipes/
  ├── modifications/
  ├── quest_items/
  ├── furniture/
  └── collectibles/
  ```
- `ItemRegistry` singleton loads all Resources at startup, provides lookup by
  ID, type, zone tier, rarity, tags
- New items added by creating new Resource files -- no code changes

**14. Expandability Architecture**

| Expansion Type | How | Code Changes? |
|---------------|-----|---------------|
| New items | Create new .tres Resource files | None |
| New item types | New Resource subclass extending ItemData | Minimal (new class) |
| New properties on existing types | Add export to Resource class (defaults auto-apply) | Minimal |
| New rarity tiers | Add to Rarity enum, define multiplier + slots | Minimal |
| New modification types | New ModificationData subclass | Minimal |
| New zone tiers | Add to zone config | None |
| New gear slots | Add to equipment_slot enum, UI support | Small |
| Item merging/upgrading | Recipe system defines upgrade recipes consuming old item | None |
| Visual variants | New visual_model Resources | None |

### States and Transitions

Item definitions are static. Item **instances** in inventory have runtime state:

| State | Description | Applies To |
|-------|-------------|-----------|
| Unmodified | No modifications installed | Equipment |
| Modified | One or more mod slots filled | Equipment |
| Equipped | Currently worn (stats active) | Equipment |
| Transmogged | Visual override applied | Equipment |
| Quick-Slotted | Assigned to D-Pad quick slot | Consumables |
| Quest-Active | Associated quest in progress | Quest Items |
| Quest-Complete | Associated quest done | Quest Items |
| Wardrobe-Unlocked | Visual permanently available for transmog | All Equipment (on first acquire) |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Character Stats** | Downstream | Equipment stat_bonuses read for derived stat calculation. Crafting affinity read for quality bonus. |
| **Ability Database** | Downstream | Modification effects (enchantments, runes) feed into ability/effect system. |
| **Inventory System** | Downstream | Reads item properties for display, sorting, filtering. Manages item instances. Unlimited capacity. |
| **Loot & Drop Tables** | Downstream | Drop tables reference item IDs. Enemies drop materials/consumables only, never gear. |
| **Gathering System** | Downstream | Reads MaterialData for gathering requirements and yields. |
| **Profession & Crafting** | Downstream | Reads RecipeData for ingredients, results, requirements. |
| **Homestead Building** | Downstream | Reads FurnitureData for placement rules, visuals. |
| **Collection System** | Downstream | Reads CollectibleData, lore_entry, wardrobe unlocks. |
| **NPC System (Shops)** | Downstream | Reads sell_value and vendor inventory definitions. |
| **Quest System** | Upstream | Quests grant gear rewards. Zone completion grants Legendary. |
| **Save/Load System** | Both | Definitions are static. Instances (inventory, mods, equipped, transmog, wardrobe) serialized. |
| **Input System** | Indirect | Quick-slottable consumables via is_quick_slottable. Respawn Potion via effect_type. |

## Formulas

### Item Stat Budget

```
stat_budget = ZONE_BASE_BUDGET * zone_tier * rarity_multiplier
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| ZONE_BASE_BUDGET | int | 10-30 | tuning knob | Base stat points for zone tier 1 |
| zone_tier | int | 1+ | item definition | Which zone this item comes from |
| rarity_multiplier | float | see table | rarity tier | Multiplier based on item rarity |

| Rarity | Multiplier |
|--------|-----------|
| Starter | 0.7x |
| Common | 1.0x |
| Uncommon | 1.3x |
| Rare | 1.6x |
| Epic | 2.0x |
| Legendary | 2.5x |

**Example**: Zone 3, Rare weapon: 20 * 3 * 1.6 = 96 total stat points distributed
across the item's stat_bonuses.

### Sell Value

```
sell_value = BASE_SELL * zone_tier * rarity_multiplier * ITEM_TYPE_MODIFIER
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| BASE_SELL | int | 5 | Base gold value |
| ITEM_TYPE_MODIFIER | float | 1.0 equip, 0.5 consumable, 0.2 material | Type affects value |

### Crafting Quality Bonus (from Character Stats GDD)

```
crafting_quality_bonus = max(0, (affinity_attr - CRAFT_ATTR_BASELINE) * CRAFT_ATTR_SCALING)
```

Item affinity determines which attribute provides the bonus (MGT for physical
gear, FNS for precision gear, INT for magical gear, None for universal items).

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player sells gear then wants transmog | Wardrobe unlocks are permanent on first acquire. Selling doesn't remove the visual. | No punishment for selling old gear |
| Two Legendaries for same slot (different zones) | Both can be owned. Player equips whichever has better stats, transmogs the other's look if preferred. | Legendaries are unique per zone, not per slot globally |
| New zone adds a gear slot that didn't exist | Existing characters get the slot empty. New gear fills it. No existing systems break. | Expandable enum + UI handles missing gracefully |
| Item ID collision (two items same id) | ItemRegistry rejects duplicate on load, logs error. First loaded wins. | Prevents silent data corruption |
| Modification removed from gear | Mod returns to inventory intact. Equipment stat_bonuses unchanged (mods are additive, not part of base). | Mods are never destroyed |
| Player has no gear for a slot | Slot shows empty, derived stats from that slot = 0 bonus. No penalty. | Starting state is all empty except Starter gear |
| Recipe requires item player sold | Player must re-acquire the material. Materials are farmable from gathering. | Materials drop from enemies and gathering -- always re-obtainable |
| Zone completion reward when inventory is "full" | Inventory is unlimited, so this can't happen. | Design decision: unlimited inventory |
| Gear from Zone 1 vs Zone 5 | Zone 5 Common (20 * 5 * 1.0 = 100) > Zone 1 Legendary (20 * 1 * 2.5 = 50). Zone always wins. | Clear vertical progression across zones |
| Item with 0 stat budget (Starter, zone 1) | 20 * 1 * 0.7 = 14 stat points. Still functional, just weak. | Starter gear works, just clearly outclassed |

## Dependencies

| System | Direction | Hard/Soft | Nature |
|--------|-----------|-----------|--------|
| **Character Stats** | Downstream | Soft | Reads stat_bonuses. Stats system works without gear (base + auto). |
| **Ability Database** | Downstream | Soft | Reads modification effects. Abilities work without mods. |
| **Inventory System** | Downstream | Hard | Cannot display or manage items without item definitions. |
| **Loot & Drop Tables** | Downstream | Hard | Cannot generate drops without item definitions. |
| **Gathering System** | Downstream | Hard | Cannot define harvestable resources without MaterialData. |
| **Profession & Crafting** | Downstream | Hard | Cannot define recipes without RecipeData and MaterialData. |
| **Homestead Building** | Downstream | Hard | Cannot place furniture without FurnitureData. |
| **Collection System** | Downstream | Soft | Reads collectibles and wardrobe. Collection works as empty until items exist. |
| **NPC System** | Downstream | Soft | Vendor inventories reference item IDs. Shops work but empty without items. |
| **Quest System** | Upstream | Soft | Quests define which items to reward. Item Database doesn't need Quest System to function. |
| **Save/Load** | Both | Hard | Must serialize item instances. Must load definitions to reconstruct inventory. |

**Note**: Item Database has zero hard upstream dependencies. It is a true
foundation system.

## Tuning Knobs

| Parameter | Default | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|---------|------------|-------------------|-------------------|
| ZONE_BASE_BUDGET | 20 | 10-50 | Higher stat values on all gear (numbers inflation) | Lower stat values (tighter math) |
| Rarity multipliers | See table | 0.5x-5.0x per tier | Bigger gap between rarities | Rarities feel more similar |
| STARTER_MULTIPLIER | 0.7x | 0.3x-0.9x | Starter gear more competitive | Starter gear weaker, faster replacement |
| BASE_SELL | 5 | 1-20 | More gold from selling (faster economy) | Less gold (slower economy) |
| Mod slots per rarity | 0/0/1/2/3/4 | 0-6 per tier | More customization at lower rarities | More exclusive customization |

**Key interaction**: ZONE_BASE_BUDGET and Character Stats' ATTR_PER_LEVEL
together determine whether gear or Power Level is the bigger source of stats.
Tune together to maintain the desired gear-vs-level balance.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Item acquired | Item icon flies to inventory, rarity-colored glow | Rarity-appropriate pickup sound (grey=plain, orange=epic fanfare) | HIGH |
| Legendary acquired | Full-screen glow, item showcase camera | Legendary fanfare (memorable, WoW-style) | HIGH |
| Gear equipped | Character model updates | Equip click/clang | MEDIUM |
| Transmog applied | Visual shimmer transition on character | Subtle magical chime | LOW |
| Modification socketed | Gem/rune socket animation on gear | Socket click + magical hum | MEDIUM |
| Modification removed | Reverse socket animation | Reverse click | LOW |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Item tooltip (name, rarity, stats, description) | On hover/select in inventory | Instant | Any item UI |
| Stat comparison (green/red arrows vs equipped) | Item tooltip | When viewing unequipped gear | Inventory/vendor |
| Rarity color coding | All item name displays | Always | All UIs showing items |
| Modification slots (filled/empty) | Equipment detail view | On mod change | Character sheet |
| Transmog wardrobe | Character sheet > Appearance tab | On new unlock | Menu |
| Zone focus indicator | Zone map/quest tracker | Per zone | Map UI |
| Collection completion % | Collection UI | On new acquisition | Collection menu |

## Acceptance Criteria

- [ ] All 7 item types load correctly from .tres Resource files
- [ ] ItemRegistry provides O(1) lookup by item ID
- [ ] Rarity multipliers produce correct stat budgets (Starter 0.7x through Legendary 2.5x)
- [ ] Zone tier scaling: Zone 5 Common > Zone 1 Legendary in raw stats
- [ ] Equipment modification slots match rarity (0/0/1/2/3/4)
- [ ] Modifications are removable and reusable without destruction
- [ ] Modifications never reduce base stats (additive only)
- [ ] Transmog visual can be changed for free, instantly, on any equipment slot
- [ ] Wardrobe unlocks persist after selling/destroying the source item
- [ ] Enemies never drop gear -- only materials, consumables, gold
- [ ] Legendary items only obtainable via zone completion (one per zone)
- [ ] New item types can be added via new Resource subclass without modifying existing code
- [ ] New gear slots can be added to equipment_slot enum without breaking existing items
- [ ] Tags system enables flexible filtering (by type, element, source, etc.)
- [ ] ItemRegistry handles 10,000+ items without startup lag (< 2 seconds load)
- [ ] Save/load correctly serializes item instances (installed mods, transmog, equipped state)

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| How many gear slots at launch? Standard 13 or fewer? | Game Designer | During zone design | Start with core slots, expand via new zones |
| Should crafted gear compete with quest reward gear? | Economy Designer | During Profession & Crafting GDD | If crafted gear = quest gear at same tier, crafting becomes the primary path. May want crafted gear slightly below quest rewards but with more mod slots. |
| How do upgrade recipes work? Consume old item + materials = better version? | Game Designer | During Profession & Crafting GDD | Preserving installed modifications through upgrades is important |
| Should Legendary items have unique visual effects (particle auras, etc.)? | Art Director | During visual design pass | WoW Legendaries have distinctive appearances -- strongly recommended |
| How does the wardrobe handle class-specific visuals? | UX Designer | During Class & Mastery GDD | Can a mage transmog plate armor appearance? Probably yes (Pillar 4). |
