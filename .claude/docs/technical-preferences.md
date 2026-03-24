# Technical Preferences

## Engine & Language

- **Engine**: Unity 6.4
- **Language**: C# (.NET)
- **Rendering**: HDRP (High Definition Render Pipeline)
- **Physics**: Unity Physics (PhysX backend)
- **Input**: Unity Input System (new)

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Public Methods**: PascalCase (e.g., `TakeDamage()`)
- **Private Fields**: _camelCase (e.g., `_moveSpeed`, `_currentHealth`)
- **Public Properties**: PascalCase (e.g., `MaxHealth`)
- **Local Variables**: camelCase (e.g., `damageAmount`)
- **Constants**: PascalCase (e.g., `MaxHealth`) or UPPER_SNAKE_CASE for config keys
- **Events/Delegates**: PascalCase past tense (e.g., `HealthChanged`, `QuestCompleted`)
- **Interfaces**: IPascalCase (e.g., `IDamageable`)
- **Files**: PascalCase matching class (e.g., `PlayerController.cs`)
- **Scenes**: PascalCase (e.g., `MainArena.unity`)
- **Prefabs**: PascalCase (e.g., `EnemySkeleton.prefab`)

## Platform Targets

- **Primary**: PC (Laptop)
- **Secondary**: iPad (with game controller)
- **Input**: Gamepad-first (controller-native UI and controls)

## Performance Budgets

- **Target Framerate**: 60fps (PC), 60fps (iPad)
- **Frame Budget**: 16.6ms
- **Draw Calls**: <1000 (batching via SRP Batcher)
- **Memory Ceiling**: 4GB

## Testing

- **Framework**: Unity Test Framework (NUnit-based)
- **Modes**: Edit Mode tests (unit) + Play Mode tests (integration)
- **Minimum Coverage**: 80% for gameplay systems, balance formulas
- **Required Tests**: Balance formulas, gameplay systems, ability rotation timing

## Forbidden Patterns

- [None configured yet -- add as architectural decisions are made]

## Allowed Libraries / Packages

- Unity Input System
- TextMeshPro
- [Others TBD -- add as dependencies are approved]

## Architecture Decisions Log

- [No ADRs yet -- use /architecture-decision to create one]
