# SFX System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-22
> **Implements Pillar**: Pillar 5 — Couch-Ready Controller (audio feedback for actions), Pillar 6 — Epic Storytelling (cinematic audio)

## Overview

The SFX System manages all non-music sound effects -- ability sounds, combat
impacts, footsteps, UI feedback, ambient environment, voice lines, and cutscene
audio. It provides a centralized audio bus architecture with priority-based
channel management, spatial 3D audio for world sounds, and 2D audio for UI and
HUD feedback. Every interaction in the game references SFX by ID; the system
handles playback, mixing, and resource management.

## Player Fantasy

Great sound design is invisible -- the player doesn't think "nice SFX" but
instead feels the **weight of every sword swing, the crunch of every critical
hit, the satisfying click of every menu selection**. Sound is the fastest
feedback channel (faster than visuals) and is critical for making the ability
rotation feel impactful. A fireball without a whoosh-BOOM is just a particle
effect. Combat without audio feels like hitting air.

## Detailed Design

### Core Rules

**1. Audio Bus Architecture**

| Bus | Purpose | Default Volume | Spatial |
|-----|---------|---------------|---------|
| Master | Top-level mix | 100% | N/A |
| SFX | All gameplay sound effects | 80% | Mixed |
| Combat | Ability sounds, impacts, combat feedback | 100% (child of SFX) | 3D |
| Ambient | Environmental loops (wind, water, birds) | 60% (child of SFX) | 3D |
| UI | Menu clicks, notifications, HUD feedback | 70% (child of SFX) | 2D |
| Voice | NPC dialogue, cutscene VO, barks | 90% (child of SFX) | Mixed |
| Music | (Owned by Music System, separate GDD) | 50% | 2D |

All buses are independently adjustable in Settings.

**2. Sound Playback**
- Sounds referenced by ID (e.g., `"sfx_sword_hit_01"`)
- AudioStreamPlayer (2D) for UI, notifications, player feedback
- AudioStreamPlayer3D for world sounds with distance attenuation
- Polyphony limit per sound ID: MAX_POLYPHONY (prevent audio spam from rapid hits)
- Priority system: higher-priority sounds preempt lower-priority when channels are full

**3. Priority Levels**

| Priority | Examples | Behavior |
|----------|---------|----------|
| Critical | Death SFX, Near-Death heartbeat, Legendary fanfare | Never preempted, always plays |
| High | Ability fire, ability impact, boss VO | Preempts Medium/Low |
| Medium | Footsteps, gathering, ambient events | Preempts Low |
| Low | Background ambient detail, distant sounds | Can be dropped if channels full |

**4. Spatial Audio**
- 3D sounds attenuate with distance (linear falloff)
- Max audible distance: AUDIO_MAX_DISTANCE (sounds beyond this are silent)
- Sounds directional: left/right panning based on source position relative to camera
- Doppler effect disabled (unnecessary for RPG, adds processing cost)

**5. Sound Variations**
- Each SFX ID can reference multiple audio files (variations)
- On play, a random variation is selected (prevents repetitive audio)
- Pitch randomization: +/- PITCH_VARIANCE on each play
- Example: `"sfx_footstep_grass"` has 4 variations, each pitch-shifted slightly

**6. Pause Behavior**
- All gameplay audio pauses on game pause (time_scale=0)
- UI audio bus remains active (menu sounds during pause)
- Music fades to low volume (owned by Music System, not SFX)

**7. Near-Death Audio**
- When Near-Death context active (Input System):
  - Heartbeat loop plays on Critical priority (never preempted)
  - All other SFX play at reduced rate (time_scale=0.3 affects playback)
  - Ability SFX still fire but stretched by slow-mo
- On Near-Death exit (survive): heartbeat stops, relief exhale SFX
- On Near-Death exit (death): heartbeat flatline SFX

### States and Transitions

The SFX System is stateless -- it responds to play requests. The audio bus
volumes are persistent settings, not states.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Settings System** | Upstream | Reads per-bus volume settings. Reads spatial audio on/off. |
| **Ability Database** | Upstream | Abilities reference sfx_id for cast and impact sounds. |
| **Player Controller** | Upstream | Emits footstep events with surface type. Dodge whoosh. |
| **Combat / Damage Calc** | Upstream | Hit impact sounds, damage type variations. |
| **HUD System** | Upstream | UI interaction sounds (button clicks, tab switches). |
| **Input System** | Upstream | Near-Death heartbeat, modifier click, controller disconnect chime. |
| **Cutscene System** | Upstream | Voice lines and cinematic SFX during cutscenes. |
| **Dialogue System** | Upstream | NPC voice lines during conversations. |
| **Pause System** | Upstream | Pause freezes gameplay audio, UI audio stays active. |
| **Item Database** | Upstream | Item pickup sounds, rarity fanfares. |

## Formulas

### Distance Attenuation

```
volume = base_volume * max(0, 1 - (distance / AUDIO_MAX_DISTANCE))
```

| Variable | Default | Description |
|----------|---------|-------------|
| AUDIO_MAX_DISTANCE | 30.0m | Beyond this, sound is silent |
| base_volume | 1.0 | Source volume before attenuation |

### Pitch Randomization

```
final_pitch = base_pitch + random(-PITCH_VARIANCE, PITCH_VARIANCE)
```

| Variable | Default | Description |
|----------|---------|-------------|
| PITCH_VARIANCE | 0.05 | +/- 5% pitch variation per play |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| 20 enemies hit simultaneously | Priority system drops Low sounds, plays High impacts up to MAX_POLYPHONY per ID | Prevents audio distortion |
| Sound source destroyed mid-play | Sound finishes playing (fire and forget). No abrupt cutoff. | Clean audio |
| Volume set to 0 for a bus | Sounds still "play" but at zero volume. No errors. | Silent processing is cheap |
| Near-Death entered while sound playing | Sound continues but time-stretched by slow-mo | Consistent with time dilation |
| Pause during voice line | Voice pauses mid-word. Resumes on unpause. | Standard pause behavior |

## Dependencies

| System | Direction | Hard/Soft | Nature |
|--------|-----------|-----------|--------|
| **Settings System** | Upstream | Soft | Volume prefs. Uses defaults without. |
| **All gameplay systems** | Upstream | Soft | Receive play requests. SFX works without (just silent). |
| **Pause System** | Upstream | Hard | Must respect time_scale for gameplay audio. |

## Tuning Knobs

| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| AUDIO_MAX_DISTANCE | 30.0m | 15-60 | Larger = hear sounds from farther away |
| MAX_POLYPHONY | 4 per ID | 1-8 | Higher = more simultaneous instances of same sound |
| PITCH_VARIANCE | 0.05 | 0.0-0.15 | More variation = less repetitive, more chaotic |
| Total audio channels | 32 | 16-64 | More channels = richer soundscape, more CPU |

## Visual/Audio Requirements

N/A -- this system IS the audio infrastructure. All other systems' audio
requirements are fulfilled by this system.

## UI Requirements

| Information | Location | Condition |
|-------------|----------|-----------|
| Per-bus volume sliders | Settings > Audio | Settings menu |
| Spatial audio toggle | Settings > Audio | Settings menu |

## Acceptance Criteria

- [ ] Audio bus architecture works with independent per-bus volume control
- [ ] 3D spatial audio correctly pans based on source position relative to camera
- [ ] Distance attenuation fades to silence at AUDIO_MAX_DISTANCE
- [ ] Priority system preempts lower-priority sounds when channels full
- [ ] Sound variations randomize correctly (no obvious repetition)
- [ ] Pitch variance applied per-play within range
- [ ] Gameplay audio pauses on time_scale=0, UI audio stays active
- [ ] Near-Death heartbeat loop plays at Critical priority
- [ ] Polyphony limit prevents audio spam from rapid multi-hit abilities
- [ ] Settings volume changes apply in real-time
- [ ] Performance: audio processing < 2ms per frame for 32 channels

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Adaptive audio mixing (duck SFX during VO)? | Audio Director | During polish pass | Side-chain compression on Voice bus could auto-duck Combat |
| Reverb zones per environment? | Audio Director | During zone design | Cave reverb vs. open field. Adds immersion, adds complexity. |
| Haptic feedback paired with SFX? | UX Designer | During platform testing | PS5/Switch HD rumble could sync with impacts |
