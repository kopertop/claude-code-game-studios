# Sprint 1 — Foundation & Core Systems

## Sprint Goal

Stand up the production Unity project and implement the foundation layer systems
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
| S1-01 | Create production Unity project in `src/` | — | S | None | Unity 6 HDRP project in src/, opens and runs clean, HDRP configured |
| S1-02 | Implement Input System | #1 Input | M | S1-01 | Input Actions asset, L2 modifier pattern, remappable, controller disconnect detection |
| S1-03 | Implement Character Stats | #14 Char Stats | M | S1-01 | Base stats, derived stats, stat modification API, NUnit tests on formulas |
| S1-04 | Implement Pause System | #4 Pause | S | S1-01, S1-02 | Pause/resume, Time.timeScale handling, overlay, controller disconnect auto-pause |
| S1-05 | Implement Player Controller | #2 Player | M | S1-02 | Movement (run/walk/crouch), jump, dodge with i-frames, mesh rotation, collision |
| S1-06 | Implement Camera System | #3 Camera | S | S1-02, S1-05 | Orbit camera, zoom, no pitch, follows player, level with ground |
| S1-07 | Set up Unity Test Framework | — | S | S1-01 | Test runner works, example test passes, CI-ready structure |

### Should Have

| ID | Task | System | Est. | Dependencies | Acceptance Criteria |
|----|------|--------|------|-------------|-------------------|
| S1-08 | Implement Health & Resource System | #7 H&R | M | S1-03 | HP/Mana pools, regen rules (no combat regen), damage/heal API, events, NUnit tests |
| S1-09 | Implement Ability Database (data layer) | #16 AbilityDB | M | S1-03 | ScriptableObject AbilityData, load from config, target types, damage types, all fields from prototype |
| S1-10 | ADR: Production architecture patterns | — | S | S1-01 | Document: GameObject hierarchy, event patterns, data-driven config approach, test strategy |

### Nice to Have

| ID | Task | System | Est. | Dependencies | Acceptance Criteria |
|----|------|--------|------|-------------|-------------------|
| S1-11 | Implement SFX System (stub) | #34 SFX | S | S1-01 | Audio Mixer groups, placeholder audio events, volume settings |
| S1-12 | Scene/Zone scaffold | #5 Scenes | S | S1-04 | Basic scene loader, zone transition skeleton, arena test scene |

## Carryover from Previous Sprint

N/A — First sprint.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Architecture over-engineering | Medium | High | Reference prototype — keep it simple, iterate later |
| Unity HDRP performance overhead | Low | Medium | Profile early, HDRP has good profiling tools |
| Prototype assumptions wrong in production | Low | High | Prototype CONCEPT.md documents all validated decisions |

## Dependencies on External Factors

- Unity 6 LTS installed and working on macOS Tahoe
- Unity Test Framework package (built-in)

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] Production project runs and shows a controllable player character
- [ ] Camera orbits and zooms correctly
- [ ] Pause system works with controller disconnect
- [ ] Character stats load from data and have NUnit test coverage
- [ ] Input system supports the validated L2-modifier controller layout
- [ ] No S1 or S2 bugs in delivered features
- [ ] At least 1 ADR documenting production architecture choices
- [ ] Code follows project coding standards (XML doc comments on public APIs)

## Notes

This sprint deliberately does NOT include combat (damage, abilities, enemies).
That's Sprint 2. The goal here is a rock-solid foundation that everything else
builds on — if the Input System or Character Stats are wrong, everything downstream
breaks.

The prototype in `prototypes/combat/` (Godot/GDScript) serves as the reference for
game feel and tuning values. `CONCEPT.md` has all validated tuning values. Production
code should match the prototype's feel while meeting production quality standards.

## Effort Key

- S = 1 session (~2-4 hours focused work)
- M = 2-3 sessions
- L = 4+ sessions
