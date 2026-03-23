# ADR-004: Loading Screen Zone Transitions

**Status**: Accepted
**Date**: 2026-03-22
**Source**: design/gdd/scene-zone-management.md

## Context

The game has multiple large zones (3-5 at launch, expandable). Target platforms
include Nintendo Switch (2GB RAM, slower storage). Three approaches: loading
screens, seamless streaming, or hybrid.

## Decision

Use **WoW-style loading screens** between zones:
- Each zone is a complete Godot PackedScene, loaded in entirety
- Only one zone loaded at a time (previous fully unloaded)
- Loading screen shows zone art, lore teasers, and gameplay tips
- Auto-save triggers before every transition
- Target: < 5s on PC, < 10s on Switch

## Alternatives Considered

- **Seamless streaming (Skyrim)**: Most immersive but extremely complex.
  Requires chunk-based world, LOD streaming, memory management. High risk for
  Switch's 2GB limit.
- **Hybrid (seamless within, loading between)**: Good balance but adds complexity
  of both approaches.

## Consequences

- Simplest implementation. Most reliable on all platforms.
- Zone size budgeted per platform (200MB Switch, 500MB PC).
- Loading screens become a presentation opportunity (not dead time).
- No inter-zone visibility (can't see Zone B from Zone A). Zone edges need
  natural boundaries (mountains, ocean, forest walls).
- Fast travel between zones always goes through loading screen.
