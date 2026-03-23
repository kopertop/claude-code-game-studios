---
name: godot46-environment-enum-migration
description: |
  Fix "Cannot find member TONE_MAP_ACES in base Environment" and similar enum errors
  in Godot 4.6. Use when: (1) GDScript fails with "Cannot find member" for Environment
  enum constants like TONE_MAP_LINEAR, TONE_MAP_ACES, TONE_MAP_FILMIC, TONE_MAP_REINHARDT,
  (2) upgrading a Godot 4.3 or earlier project to 4.6, (3) Environment enum constants
  that previously worked now cause parse errors. The ToneMapper enum constants moved from
  Environment to RenderingServer in Godot 4.6.
author: Claude Code
version: 1.0.0
date: 2026-03-22
---

# Godot 4.6 Environment Enum Migration

## Problem
Godot 4.6 removed `ToneMapper` enum constants from the `Environment` class.
Code using `Environment.TONE_MAP_ACES` (or LINEAR, REINHARDT, FILMIC) fails with:
```
Parse Error: Cannot find member "TONE_MAP_ACES" in base "Environment".
```

## Context / Trigger Conditions
- Godot 4.6.x project (check with `godot --version`)
- GDScript references `Environment.TONE_MAP_*` constants
- Error occurs at script load/parse time, not runtime
- Common in code generated for or written against Godot 4.3 or earlier

## Solution

Replace `Environment.TONE_MAP_*` with `RenderingServer.ENV_TONE_MAPPER_*`:

| Old (Godot <= 4.3)              | New (Godot 4.6)                          | Value |
|----------------------------------|------------------------------------------|-------|
| `Environment.TONE_MAP_LINEAR`    | `RenderingServer.ENV_TONE_MAPPER_LINEAR`    | 0 |
| `Environment.TONE_MAP_REINHARDT` | `RenderingServer.ENV_TONE_MAPPER_REINHARD`  | 1 |
| `Environment.TONE_MAP_FILMIC`    | `RenderingServer.ENV_TONE_MAPPER_FILMIC`    | 2 |
| `Environment.TONE_MAP_ACES`      | `RenderingServer.ENV_TONE_MAPPER_ACES`      | 3 |

The `tonemap_mode` property on Environment still exists and accepts the same integer
values. Only the enum constant location changed.

Godot 4.6 also added `AgX` as value 4 via `RenderingServer.ENV_TONE_MAPPER_AGX`.

## Verification
Run `godot --headless --path . --script your_script.gd` and confirm no parse errors.

## Example
```gdscript
# Before (Godot 4.3):
environment.tonemap_mode = Environment.TONE_MAP_ACES

# After (Godot 4.6):
environment.tonemap_mode = RenderingServer.ENV_TONE_MAPPER_ACES
```

## Notes
- The property `environment.tonemap_mode` is unchanged; only the enum constants moved
- This may affect other Environment enums as well — if similar errors occur for other
  Environment constants, check RenderingServer for the relocated enum
- Integer values are stable, so `environment.tonemap_mode = 3` also works as a quick fix
  but is less readable
