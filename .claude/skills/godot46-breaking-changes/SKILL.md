---
name: godot46-breaking-changes
description: |
  Fix common Godot 4.6 breaking changes and parse errors. Use when: (1) "Could not find
  type X in the current scope" for class_name types loaded via set_script(load(...)),
  (2) "Cannot find member PRESET_BOTTOM_CENTER in base Control" — renamed to
  PRESET_CENTER_BOTTOM, (3) "Node not inside tree. Use look_at_from_position()" when
  calling look_at() on a node before add_child(), (4) class_name types not resolving
  in dynamically loaded scripts, (5) upgrading Godot 4.3 projects to 4.6.
author: Claude Code
version: 1.0.0
date: 2026-03-22
---

# Godot 4.6 Breaking Changes

## Problem
Godot 4.6 introduced several breaking changes that cause parse errors and runtime
errors in code written for Godot 4.3 or earlier.

## Issue 1: class_name Not Resolving in Dynamic Scripts

### Trigger
```
Parse Error: Could not find type "MyClass" in the current scope.
```
When scripts are loaded via `set_script(load("res://script.gd"))` at runtime.

### Cause
Godot's global script class cache (`class_name` registry) may not be populated when
scripts are loaded dynamically, especially in projects that haven't been opened in
the editor.

### Solution
Use `preload()` constants instead of relying on `class_name` global resolution:

```gdscript
# In the script that USES the type:
const MyClass = preload("res://my_class.gd")

# Remove class_name from the target script if using preload everywhere:
# class_name MyClass  <-- remove this
extends Node
```

If both `class_name` and a `const` preload with the same name exist, they conflict.
Choose one approach: either use `class_name` everywhere (requires editor cache), or
use `preload()` everywhere (works without cache).

## Issue 2: Control Layout Preset Renames

### Trigger
```
Parse Error: Cannot find member "PRESET_BOTTOM_CENTER" in base "Control".
```

### Solution
| Old Name | New Name (Godot 4.6) |
|----------|---------------------|
| `PRESET_BOTTOM_CENTER` | `PRESET_CENTER_BOTTOM` |
| `PRESET_TOP_CENTER` | `PRESET_CENTER_TOP` |
| `PRESET_LEFT_CENTER` | `PRESET_CENTER_LEFT` |
| `PRESET_RIGHT_CENTER` | `PRESET_CENTER_RIGHT` |

The naming convention changed from `PRESET_{edge}_{axis}` to `PRESET_{axis}_{edge}`.

## Issue 3: look_at() Requires Node in Tree

### Trigger
```
ERROR: Node not inside tree. Use look_at_from_position() instead.
```

### Cause
Godot 4.6 enforces that `look_at()` can only be called on nodes that are already
in the scene tree (after `add_child()`).

### Solution
```gdscript
# Before (broke in 4.6):
camera = Camera3D.new()
camera.look_at(target_pos)
parent.add_child(camera)

# After:
camera = Camera3D.new()
parent.add_child(camera)
camera.look_at(target_pos)
```

## Verification
Run `godot --path . 2>&1 | head -30` and check for parse/runtime errors.

## Notes
- See also: godot46-environment-enum-migration skill for ToneMapper enum changes
- When fixing a project with multiple issues, fix parse errors first (they prevent
  the script from loading at all), then address runtime errors
- The `--headless` flag is useful for checking parse errors without opening a window
