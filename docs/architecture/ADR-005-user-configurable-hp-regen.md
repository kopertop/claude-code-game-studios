# ADR-005: User-Configurable HP Regeneration

**Status**: Accepted
**Date**: 2026-03-22
**Source**: design/gdd/health-resource-system.md

## Context

In MMOs, HP regeneration rate is a balance lever -- too fast and healers lose
value. In a solo game, there's no such constraint. Different players want
different pacing: hardcore players savor tension, casual players want no downtime.

## Decision

Make HP regeneration a **user-configurable comfort setting** with 5 presets:
- None (potions/abilities only)
- Slow (1% max HP/sec out of combat -- default)
- Moderate (3%/sec OOC)
- Fast (10%/sec OOC -- full in ~10s)
- Always (0.5%/sec in combat, 5%/sec OOC)

Changeable at any time in Settings. Takes effect immediately.

## Alternatives Considered

- **Fixed regen rate**: Simpler but forces one playstyle on all players.
  Contradicts Pillar 1 (Your Journey, Your Pace).
- **Difficulty settings that include regen**: Bundling regen with enemy damage/HP
  removes granular control. Players may want hard enemies but fast regen.

## Consequences

- HP regen is decoupled from difficulty. Could add separate enemy difficulty
  settings later.
- Balance must work at ALL preset levels. Potion economy must be meaningful
  even at "Fast" regen (potions still valuable in combat where most presets
  provide 0 regen).
- Default (Slow) is the designed experience. Other presets are comfort options.
