# Sprint 1 — Foundation & Core Systems

## Sprint Goal

Stand up the production Godot project and implement the foundation layer systems
so that Sprint 2 can build gameplay on top of a solid, testable architecture.

## Milestone

M1: First Playable

## Capacity

- Solo developer, estimated 5-7 focused sessions
- Buffer (20%): ~1 session reserved for unplanned work
- Available: ~5 sessions of productive output

## Tasks

### Must Have (Critical Path)

| ID | Task | System | Est. | Dependencies | Acceptance Criteria |
|----|------|--------|------|-------------|-------------------|
| S1-01 | Create production Godot project in `src/` | — | S | None | project.godot in src/, runs clean, matches engine config |
| S1-02 | Implement Input System | #1 Input | M | S1-01 | Action map loaded from config, L2 modifier pattern, remappable, controller disconnect detection |
| S1-03 | Implement Character Stats | #14 Char Stats | M | S1-01 | Base stats, derived stats, stat modification API, GUT tests on formulas |
| S1-04 | Implement Pause System | #4 Pause | S | S1-01, S1-02 | Pause/resume, PROCESS_MODE handling, overlay, controller disconnect auto-pause |
| S1-05 | Implement Player Controller | #2 Player | M | S1-02 | Movement (run/walk/crouch), jump, dodge with i-frames, mesh rotation, collision |
| S1-06 | Implement Camera System | #3 Camera | S | S1-02, S1-05 | Orbit camera, zoom, no pitch, follows player, level with ground |
| S1-07 | Set up GUT test framework | — | S | S1-01 | Test runner works, example test passes, CI-ready structure |

### Should Have

| ID | Task | System | Est. | Dependencies | Acceptance Criteria |
|----|------|--------|------|-------------|-------------------|
| S1-08 | Implement Health & Resource System | #7 H&R | M | S1-03 | HP/Mana pools, regen rules (no combat regen), damage/heal API, signals, GUT tests |
| S1-09 | Implement Ability Database (data layer) | #16 AbilityDB | M | S1-03 | AbilityData resource, load from config files, target types, damage types, all fields from prototype |
| S1-10 | ADR: Production architecture patterns | — | S | S1-01 | Document: node hierarchy, signal patterns, data-driven config approach, test strategy |

### Nice to Have

| ID | Task | System | Est. | Dependencies | Acceptance Criteria |
|----|------|--------|------|-------------|-------------------|
| S1-11 | Implement SFX System (stub) | #34 SFX | S | S1-01 | Bus structure, placeholder audio events, volume settings |
| S1-12 | Scene/Zone scaffold | #5 Scenes | S | S1-04 | Basic scene loader, zone transition skeleton, arena test scene |

## Carryover from Previous Sprint

N/A — First sprint.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Architecture over-engineering | Medium | High | Reference prototype — keep it simple, iterate later |
| GDScript static typing gaps | Low | Medium | Enforce typed: true in project settings from day 1 |
| Prototype assumptions wrong in production | Low | High | Prototype CONCEPT.md documents all validated decisions |

## Dependencies on External Factors

- Godot 4.6.1 stable (already verified in prototype)
- GUT addon (needs to be added to project)

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] Production project runs and shows a controllable player character
- [ ] Camera orbits and zooms correctly
- [ ] Pause system works with controller disconnect
- [ ] Character stats load from data and have GUT test coverage
- [ ] Input system supports the validated L2-modifier controller layout
- [ ] No S1 or S2 bugs in delivered features
- [ ] At least 1 ADR documenting production architecture choices
- [ ] Code follows project coding standards (static typing, doc comments on public APIs)

## Notes

This sprint deliberately does NOT include combat (damage, abilities, enemies).
That's Sprint 2. The goal here is a rock-solid foundation that everything else
builds on — if the Input System or Character Stats are wrong, everything downstream
breaks.

The prototype in `prototypes/combat/` serves as the reference implementation.
`CONCEPT.md` has all validated tuning values. Production code should match the
prototype's feel while meeting production quality standards.

## Effort Key

- S = 1 session (~2-4 hours focused work)
- M = 2-3 sessions
- L = 4+ sessions
