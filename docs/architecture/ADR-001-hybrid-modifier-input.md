# ADR-001: Hybrid Modifier Input System

**Status**: Accepted
**Date**: 2026-03-22
**Source**: design/gdd/input-system.md

## Context

The game uses WoW-style ability rotations with 12-20+ abilities per class, but
must be playable entirely with a gamepad. Standard gamepads have ~14 buttons.
Three proven approaches exist: FFXIV cross-hotbar (32 slots), ESO compact bar
(12 slots), and a hybrid modifier system (16 slots).

## Decision

Use a **hybrid modifier system** with R2/L2 held as modifiers:
- R2 + face buttons = 4 slots (primary bar)
- L2 + face buttons = 4 slots (secondary bar)
- R2 + d-pad = 4 slots (utility)
- L2 + d-pad = 4 slots (defensive/misc)
- Total: 16 ability slots, expandable via future double-tap modifiers

Trigger threshold at 50% analog to prevent accidental activation.

## Alternatives Considered

- **FFXIV Cross-Hotbar (32 slots)**: More capacity but steeper learning curve
  with double-tap combos. Overkill for initial class designs.
- **ESO Compact Bar (12 slots)**: Simpler but too restrictive for WoW-depth
  rotations with builder/spender + cooldowns + utility.

## Consequences

- 16 slots is sufficient for MVP through Alpha. May need expansion for multi-class.
- D-pad abilities harder to use while moving (thumb leaves stick). Utility/defensive
  abilities are appropriate for d-pad since they're used less frequently.
- All downstream systems (Combat, HUD, Ability Database) reference 16-slot architecture.
