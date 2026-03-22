# Camera System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-22
> **Implements Pillar**: Pillar 5 — Couch-Ready Controller Experience

## Overview

The Camera System provides a third-person orbit camera that freely rotates around
the player character using the right stick. It handles collision avoidance with
geometry, soft lock-on targeting for combat, automatic centering, zoom control,
and cutscene camera overrides. The player controls the camera directly via the
right stick at all times during gameplay -- the camera never wrestles control away
except during cutscenes (which are always pausable).

## Player Fantasy

The camera should feel like a **loyal cinematographer** -- always showing the
player exactly what they need to see without being asked. During exploration, it
frames the world beautifully. During combat, it keeps the target visible. During
cutscenes, it tells the story. The player should rarely think about the camera --
and when they do adjust it, the response should be instant and smooth. A bad
camera is the fastest way to ruin a 3D game; a good camera is invisible.

## Detailed Design

### Core Rules

**1. Orbit Camera Behavior**
- Camera orbits on a sphere around the player character
- Right stick horizontal = yaw (rotate around player, 360 degrees, wraps)
- Right stick vertical = pitch (tilt up/down, clamped to MIN_PITCH / MAX_PITCH)
- Camera always looks at a point slightly above player center (shoulder height)
- Player character does NOT rotate with the camera -- only movement direction
  is camera-relative (Player Controller GDD)

**2. Camera Distance**
- Default distance: CAM_DEFAULT_DISTANCE from player
- No player-controlled zoom in base game (simplicity for gamepad)
- Camera pulls closer when geometry is between camera and player (collision)
- Camera smoothly returns to default distance when obstruction clears

**3. Collision Avoidance**
- Raycast from look-at point to desired camera position each frame
- If geometry is hit, camera snaps to hit point (closer to player)
- When obstruction clears, camera lerps back to default distance at CAM_RETURN_SPEED
- Camera never clips through geometry -- always stays on the player's side of walls
- Minimum distance clamp: CAM_MIN_DISTANCE (prevents camera inside player model)

**4. Soft Lock-On (Combat)**
- L1 toggles soft lock-on to nearest enemy
- When locked on:
  - Camera look-at point shifts to midpoint between player and target
  - Camera auto-rotates slowly to keep target in frame (not instant snap)
  - Player character faces target while stationary (strafe movement)
  - Target indicator appears on locked enemy
- R1 cycles to next target (nearest to current target)
- Lock-on breaks when: target dies, target moves out of LOCK_ON_MAX_RANGE,
  player presses L1 again, or player enters non-combat context
- Right stick still works during lock-on (player can override camera angle)

**5. Auto-Center**
- R3 (right stick click) instantly centers camera behind the player character
- Camera smoothly lerps to behind-player position over CENTER_DURATION
- Moving forward without touching right stick slowly drifts camera behind
  player at AUTO_CENTER_SPEED (very slow, doesn't fight player if they touched
  the right stick recently)
- Auto-center disabled for AUTO_CENTER_DELAY after any right stick input

**6. Cutscene Camera**
- During cutscene context (Input System), gameplay camera is disabled
- Cutscene cameras are pre-authored sequences (AnimationPlayer on Camera3D)
- On cutscene end, camera smoothly transitions back to gameplay position
  over CUTSCENE_RETURN_DURATION
- Pause during cutscene freezes the camera in place

**7. Camera Sensitivity**
- Right stick sensitivity is adjustable in Settings (separate X and Y sensitivity)
- Y-axis invert option available in Settings
- Sensitivity scales linearly with stick deflection (more deflection = faster rotation)

### States and Transitions

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Free Orbit | Default, no lock-on | Lock-on activated, cutscene | Full right stick control, auto-center drift |
| Locked On | L1 pressed near enemy | Target dies, out of range, L1 again, non-combat | Look-at shifts to player-target midpoint, auto-rotates to keep target visible |
| Cutscene | Cutscene triggered | Cutscene ends | Pre-authored camera, gameplay cam disabled |
| Paused | Pause activated | Unpause | Camera frozen in place |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Input System** | Upstream | Reads right stick vector, L1 (lock toggle), R1 (cycle target), R3 (center). Reads current input context. |
| **Player Controller** | Upstream | Reads player position as orbit center. Player Controller reads camera forward for camera-relative movement. |
| **Ability Rotation Combat** | Downstream | Combat reads camera forward direction for ability targeting. Lock-on target shared with combat system. |
| **Cutscene System** | Upstream | Cutscene system takes camera control during cinematics. Returns control on end. |
| **Pause System** | Upstream | time_scale=0 freezes camera movement (auto-center, lerps). |
| **Settings System** | Upstream | Reads sensitivity, Y-invert, auto-center preferences. |
| **HUD System** | Downstream | Lock-on target indicator positioned based on camera projection. |

## Formulas

### Camera Rotation

```
yaw += right_stick.x * CAM_SENSITIVITY_X * delta
pitch += right_stick.y * CAM_SENSITIVITY_Y * delta * y_invert_sign
pitch = clamp(pitch, MIN_PITCH, MAX_PITCH)
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| CAM_SENSITIVITY_X | float | 120 deg/s | Horizontal rotation speed at full stick |
| CAM_SENSITIVITY_Y | float | 80 deg/s | Vertical rotation speed at full stick |
| MIN_PITCH | float | -80 deg | Can't look straight down |
| MAX_PITCH | float | 60 deg | Can't look straight up (past top of head) |

### Camera Position

```
cam_offset = Vector3(0, CAM_HEIGHT_OFFSET, CAM_DEFAULT_DISTANCE)
cam_offset = cam_offset.rotated(Vector3.UP, yaw).rotated(right_axis, pitch)
cam_position = player_position + cam_offset
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| CAM_DEFAULT_DISTANCE | float | 8.0 meters | Distance from player |
| CAM_MIN_DISTANCE | float | 1.5 meters | Minimum distance (collision) |
| CAM_HEIGHT_OFFSET | float | 1.8 meters | Look-at height above player origin |

### Collision Snap and Return

```
if raycast_hit:
    current_distance = min(hit_distance - CAM_COLLISION_BUFFER, CAM_DEFAULT_DISTANCE)
else:
    current_distance = lerp(current_distance, CAM_DEFAULT_DISTANCE, CAM_RETURN_SPEED * delta)
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| CAM_COLLISION_BUFFER | float | 0.3m | Buffer so camera doesn't sit flush against walls |
| CAM_RETURN_SPEED | float | 3.0 | Lerp speed when returning to default distance |

### Lock-On Look-At

```
lock_on_look_at = lerp(player_position, target_position, LOCK_ON_MIDPOINT_BIAS)
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| LOCK_ON_MIDPOINT_BIAS | float | 0.3 | 0=look at player, 0.5=exact midpoint, 1=look at target |
| LOCK_ON_MAX_RANGE | float | 25.0m | Lock breaks beyond this distance |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Camera stuck in narrow corridor | Snaps very close to player. MIN_DISTANCE prevents going inside model. | Collision avoidance handles tight spaces |
| Lock-on target goes behind wall | Lock-on breaks after LOS_BREAK_DURATION if no line of sight | Don't lock onto invisible enemies |
| Multiple enemies equidistant for lock-on | Pick the one closest to screen center | Most intuitive selection |
| Lock-on during cutscene | Not possible -- cutscene context disables lock-on | Clean state separation |
| Player moves under low ceiling | Camera pushes down (pitch adjusts). If no room, distance shortens. | Always show the player |
| R3 center during lock-on | Center on target, not behind player | Lock-on context overrides center behavior |
| Camera underwater | No special underwater camera. Same orbit behavior. | Swimming doesn't change camera rules |
| Cutscene ends while camera is in unusual position | Smooth lerp from cutscene camera to gameplay camera over CUTSCENE_RETURN_DURATION | No jarring snap |

## Dependencies

| System | Direction | Hard/Soft | Nature |
|--------|-----------|-----------|--------|
| **Input System** | Upstream | Hard | Cannot rotate without right stick input |
| **Player Controller** | Upstream | Hard | Cannot orbit without player position |
| **Ability Rotation Combat** | Downstream | Soft | Combat uses camera forward for targeting |
| **Cutscene System** | Upstream | Soft | Cutscenes override camera. Camera works without cutscenes. |
| **Pause System** | Upstream | Hard | Must freeze with time_scale=0 |
| **Settings System** | Upstream | Soft | Sensitivity/invert prefs. Works with defaults. |
| **HUD System** | Downstream | Soft | Lock-on indicator uses camera projection |

## Tuning Knobs

| Parameter | Default | Safe Range | Increase | Decrease |
|-----------|---------|------------|----------|----------|
| CAM_SENSITIVITY_X | 120 deg/s | 60-240 | Faster rotation (twitchy) | Slower (sluggish) |
| CAM_SENSITIVITY_Y | 80 deg/s | 40-160 | Faster vertical | Slower vertical |
| CAM_DEFAULT_DISTANCE | 8.0m | 4.0-15.0 | Wider view, less detail | Tighter, more cinematic |
| CAM_HEIGHT_OFFSET | 1.8m | 1.0-3.0 | Higher camera angle | Lower, behind-shoulder feel |
| MIN_PITCH / MAX_PITCH | -80/60 | -89/89 | More vertical range | Restricted view angles |
| CAM_RETURN_SPEED | 3.0 | 1.0-8.0 | Snappier return from collision | Slower, smoother return |
| LOCK_ON_MIDPOINT_BIAS | 0.3 | 0.0-0.5 | Camera shows more of the enemy | Camera stays closer to player view |
| LOCK_ON_MAX_RANGE | 25.0m | 15-40 | Lock holds at distance | Lock breaks at closer range |
| AUTO_CENTER_SPEED | 0.5 deg/s | 0.0-2.0 | Camera auto-centers faster (may feel fighting player) | Slower or disabled |
| AUTO_CENTER_DELAY | 3.0s | 1.0-10.0 | Waits longer after stick input before auto-centering | Starts sooner |
| CUTSCENE_RETURN_DURATION | 0.5s | 0.2-1.5 | Faster snap back to gameplay | Smoother cinematic transition |

## Visual/Audio Requirements

| Event | Visual | Audio | Priority |
|-------|--------|-------|----------|
| Lock-on activated | Target indicator (circle/diamond) on enemy | Lock-on chime | HIGH |
| Lock-on target switch | Indicator moves to new target | Subtle click | MEDIUM |
| Lock-on break | Indicator fades | Disengage sound | LOW |
| R3 center camera | None (instant feel) | None | N/A |

## UI Requirements

| Information | Location | Condition |
|-------------|----------|-----------|
| Lock-on target indicator | Projected on locked enemy (screen space) | Lock-on active |
| Target HP bar | Above locked enemy or HUD top | Lock-on active |

## Acceptance Criteria

- [ ] Right stick orbits camera 360 degrees horizontally, pitch clamped vertically
- [ ] Camera follows player position with zero visible lag
- [ ] Camera never clips through geometry (collision raycast working)
- [ ] Camera smoothly returns to default distance after obstruction clears
- [ ] Soft lock-on activates on L1, keeps target in frame
- [ ] R1 cycles targets correctly (nearest to current)
- [ ] Lock-on breaks at max range or on target death
- [ ] R3 centers camera behind player (or on target during lock-on)
- [ ] Auto-center drift is slow and doesn't fight recent stick input
- [ ] Cutscene camera takes over cleanly and returns smoothly
- [ ] Camera sensitivity adjustable in Settings
- [ ] Y-axis invert option works correctly
- [ ] Performance: camera update within 0.5ms per frame
- [ ] Minimum distance clamp prevents camera inside player model

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Should lock-on change movement to strafe? | Game Designer | During Combat System GDD | Player Controller has this as open question too |
| Camera shake on big hits? | Art Director | During polish pass | Common in action games, may cause motion sickness |
| FOV adjustment in settings? | UX Designer | During Settings System GDD | Some players get motion sickness at default FOV |
| Should mounted movement change camera distance? | Game Designer | During Travel System GDD | Mounts are faster, may need wider camera |
