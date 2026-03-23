# ADR-002: Soft-Cap Logarithmic Stat Progression

**Status**: Accepted
**Date**: 2026-03-22
**Source**: design/gdd/character-stats.md

## Context

The game has no level cap (Pillar 2: Always Something New). Traditional linear
stat scaling would make early content trivial and late-game numbers unmanageable.
The progression system must feel rewarding at Power Level 10, 100, and 1000+.

## Decision

Use **logarithmic diminishing returns** for derived stat scaling:
```
derived = base + SCALING_COEFF * ln(1 + attribute / SOFT_CAP_POINT) * attribute
```
- Below SOFT_CAP_POINT: roughly linear growth (each point feels impactful)
- Above SOFT_CAP_POINT: diminishing but never zero returns
- Combined with: auto-increasing stats (no manual allocation), free mastery respec,
  3 universal attributes (Might/Finesse/Intellect)

Power Level replaces traditional levels. No maximum.

## Alternatives Considered

- **Hard cap with expansion resets (WoW)**: Requires gear resets every expansion.
  Contradicts "investment is never wasted" pillar.
- **Pure horizontal expansion (GW2)**: Power plateaus too early, numbers feel stagnant.
- **Linear scaling (no cap)**: Numbers become astronomical. Balance is impossible.

## Consequences

- 64-bit integers required for stat values at extreme Power Levels.
- Zone difficulty ratio (PL / zone_suggested) naturally creates "power fantasy in
  old zones, challenge in new zones" without artificial scaling.
- Gear remains impactful at all stages because gear bonuses are additive (not
  subject to the soft-cap curve).
