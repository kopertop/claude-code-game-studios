# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (primary), C++ via GDExtension (performance-critical)
- **Rendering**: Forward+ (default for 3D)
- **Physics**: Jolt (Godot 4.6 default)
- **Vibe-Coding**: Godogen (github.com/htdt/godogen)

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables/Functions**: snake_case (e.g., `move_speed`, `take_damage()`)
- **Signals**: snake_case past tense (e.g., `health_changed`, `quest_completed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Platform Targets

- **Primary**: PC (Laptop)
- **Secondary**: iPad (with game controller)
- **Stretch**: Nintendo Switch
- **Input**: Gamepad-first (controller-native UI and controls)

## Performance Budgets

- **Target Framerate**: 60fps (PC/iPad), 30fps (Switch)
- **Frame Budget**: 16.6ms (PC/iPad), 33.3ms (Switch)
- **Draw Calls**: <500 (Switch constraint drives this)
- **Memory Ceiling**: 2GB (Switch constraint)

## Testing

- **Framework**: GUT (Godot Unit Test)
- **Minimum Coverage**: 80% for gameplay systems, balance formulas
- **Required Tests**: Balance formulas, gameplay systems, ability rotation timing

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- Godogen (vibe-coding workflow)
- [Others TBD — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]
