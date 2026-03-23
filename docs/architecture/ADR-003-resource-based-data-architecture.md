# ADR-003: Godot Resource-Based Data Architecture

**Status**: Accepted
**Date**: 2026-03-22
**Source**: design/gdd/item-database.md, design/gdd/ability-database.md

## Context

Items and abilities are the two largest data systems in the game. Both need to
support indefinite expansion (new items, new abilities, new types) without code
changes. The game targets Godot 4.6.

## Decision

Use **Godot Resource (.tres) files** with inheritance hierarchies:
- Items: ItemData base → EquipmentData, ConsumableData, MaterialData, etc.
- Abilities: AbilityData base → DamageAbilityData, HealAbilityData, BuffAbilityData, etc.
- Singleton registries (ItemRegistry, AbilityRegistry) load all Resources at startup
- New content = new .tres files, no code changes
- New types = new Resource subclass (minimal code), existing data unaffected

## Alternatives Considered

- **JSON/CSV flat files**: Simpler but no type safety, no Godot editor integration,
  no inheritance.
- **SQLite database**: Powerful queries but overkill for single-player, no Godot
  editor integration, harder to version control.
- **Hardcoded GDScript dictionaries**: Fast to prototype but impossible to expand
  without code changes. Violates expandability pillar.

## Consequences

- Godot editor can edit item/ability data visually (export vars on Resources).
- All Resources are version-controlled as text files (.tres format).
- Startup load of 10,000+ Resources must complete in < 2 seconds.
- Modding community could potentially add content via Resource files (future).
