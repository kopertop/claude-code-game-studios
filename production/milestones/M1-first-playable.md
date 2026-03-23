# Milestone 1: First Playable

**Target**: Playable combat loop in production-quality code
**Systems**: All 12 MVP-tier systems from systems-index.md
**Success criteria**: Player can load into a zone, fight enemies using the validated
warlock rotation, and see the core loop working with production architecture.

## Scope

Rewrite the combat prototype to production standards in `src/`:
- Proper architecture (dependency injection, data-driven config, testable)
- GDScript with static typing enforced
- GUT test coverage on gameplay formulas and systems
- ADRs for major technical decisions
- Code following project coding standards

## What's NOT in M1

- Multiple classes/zones
- Save/load
- Quests/dialogue/NPCs
- Crafting/gathering
- Sound effects (placeholder OK)
- Polish/VFX (prototype-level OK)
