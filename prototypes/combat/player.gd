# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does WoW-style GCD rotation feel fun on a gamepad in Godot 4.6?
# Date: 2026-03-22
extends CharacterBody3D

const CombatSystem = preload("res://combat_system.gd")
const AbilityData = preload("res://ability_data.gd")
const WarlockAbilities = preload("res://warlock_abilities.gd")

signal hp_changed(current: float, maximum: float)
signal resource_changed(current: float, maximum: float)
signal ability_slot_activated(slot_index: int)
signal target_changed(new_target: Node3D)
signal spellbar_changed(bar_index: int, bar_name: String)
signal dodge_performed()

const SPEED_RUN: float = 7.0
const SPEED_WALK: float = 3.0
const SPEED_CROUCH: float = 2.0
const CAST_MOVE_MULTIPLIER: float = 0.5
const DODGE_SPEED: float = 18.0
const DODGE_DURATION: float = 0.4
const DODGE_COOLDOWN: float = 1.0
const DODGE_IFRAMES: float = 0.3
const GRAVITY: float = 20.0
const JUMP_VELOCITY: float = 8.0
const MANA_REGEN_RATE: float = 5.0

var max_hp: float = 500.0
var current_hp: float = 500.0
var max_mana: float = 200.0
var current_mana: float = 200.0

var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var is_dodging: bool = false
var is_invulnerable: bool = false
var is_running: bool = true
var is_crouching: bool = false

var combat_system: Node
var basic_attack_ability = null
var major_spell_ability = null
var spellbars: Array = [{}, {}, {}, {}]
var spellbar_names: Array = ["Default", "Utility", "Custom", "Potions"]
var active_spellbar: int = 0
var hotbar: Dictionary = {}

var camera: Camera3D
var camera_yaw: float = 0.0
var camera_distance: float = 8.0
const CAMERA_MIN_DIST: float = 3.0
const CAMERA_MAX_DIST: float = 18.0
const CAMERA_HEIGHT: float = 5.0
const CAMERA_ZOOM_SPEED: float = 8.0
var mesh: MeshInstance3D

var target_locked: Node3D = null
var target_indicator: Node3D = null

func _ready() -> void:
	combat_system = CombatSystem.new()
	add_child(combat_system)

	var abilities = WarlockAbilities.create_all()
	basic_attack_ability = abilities[0]
	major_spell_ability = abilities[7]

	spellbars[0] = {0: abilities[1], 1: abilities[2], 2: abilities[3], 3: abilities[4]}
	spellbars[1] = {0: abilities[5], 1: abilities[6]}

	_sync_hotbar()
	_setup_visuals()
	_setup_camera()
	_create_target_indicator()

	combat_system.cast_started.connect(_on_cast_started)
	combat_system.cast_cancelled.connect(_on_cast_cancelled)

func _sync_hotbar() -> void:
	hotbar = spellbars[active_spellbar].duplicate()
	spellbar_changed.emit(active_spellbar, spellbar_names[active_spellbar])

func _switch_spellbar(index: int) -> void:
	if index == active_spellbar:
		return
	active_spellbar = index
	_sync_hotbar()

func _setup_visuals() -> void:
	mesh = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	mesh.mesh = capsule
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.1, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.05, 0.3)
	mat.emission_energy_multiplier = 0.5
	mesh.material_override = mat
	mesh.position.y = 0.9
	add_child(mesh)

	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.top_level = true
	add_child(camera)
	_position_camera()

func _create_target_indicator() -> void:
	target_indicator = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	target_indicator.mesh = quad
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = _generate_reticle_texture()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.1)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	target_indicator.material_override = mat
	target_indicator.visible = false
	get_parent().call_deferred("add_child", target_indicator)

func _generate_reticle_texture() -> ImageTexture:
	var size = 128
	var center = size / 2.0
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col = Color(1.0, 0.15, 0.1, 1.0)
	var outer_r = 48.0
	var inner_r = 20.0
	var line_w = 3.0
	var cross_inner = 38.0
	var cross_outer = 62.0
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var dist = sqrt(dx * dx + dy * dy)
			var pixel = Color(0, 0, 0, 0)
			if abs(dist - outer_r) < line_w:
				pixel = col
			elif abs(dist - inner_r) < line_w:
				pixel = col
			elif absf(dx) < line_w and (dist > cross_inner and dist < cross_outer):
				pixel = col
			elif absf(dy) < line_w and (dist > cross_inner and dist < cross_outer):
				pixel = col
			if pixel.a > 0:
				img.set_pixel(x, y, pixel)
	var tex = ImageTexture.create_from_image(img)
	return tex

func _get_move_speed() -> float:
	if is_crouching:
		return SPEED_CROUCH
	elif is_running:
		return SPEED_RUN
	else:
		return SPEED_WALK

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	_update_movement(delta)
	_update_dodge(delta)
	_update_mana_regen(delta)
	_update_input()
	_update_target_indicator(delta)

func _get_camera_forward() -> Vector3:
	return Vector3(-sin(camera_yaw), 0, -cos(camera_yaw)).normalized()

func _get_camera_right() -> Vector3:
	return Vector3(cos(camera_yaw), 0, -sin(camera_yaw)).normalized()

func _position_camera() -> void:
	var offset = Vector3(0, 0, camera_distance).rotated(Vector3.UP, camera_yaw)
	camera.global_position = global_position + Vector3(0, CAMERA_HEIGHT, 0) + offset
	camera.look_at(global_position + Vector3(0, 1.0, 0))

func _update_camera(delta: float) -> void:
	var cam_x = Input.get_axis("camera_left", "camera_right")
	var cam_y = Input.get_axis("camera_up", "camera_down")
	camera_yaw -= cam_x * 3.0 * delta
	camera_distance = clampf(camera_distance + cam_y * CAMERA_ZOOM_SPEED * delta, CAMERA_MIN_DIST, CAMERA_MAX_DIST)
	_position_camera()

func _update_movement(delta: float) -> void:
	if is_dodging:
		return

	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)

	var speed = _get_move_speed()
	if combat_system.casting:
		speed *= CAST_MOVE_MULTIPLIER

	if input_dir.length() > 0.1:
		var forward = _get_camera_forward()
		var right = _get_camera_right()

		var move_dir = (forward * -input_dir.y + right * input_dir.x).normalized()
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed

		var target_rot = atan2(move_dir.x, move_dir.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_rot, 10.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 5.0 * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	move_and_slide()

func _update_dodge(delta: float) -> void:
	dodge_cooldown_timer = maxf(0, dodge_cooldown_timer - delta)

	if is_dodging:
		dodge_timer -= delta
		is_invulnerable = dodge_timer > (DODGE_DURATION - DODGE_IFRAMES)
		velocity = dodge_direction * DODGE_SPEED
		velocity.y = 0 if is_on_floor() else velocity.y - GRAVITY * delta
		move_and_slide()
		if dodge_timer <= 0:
			is_dodging = false
			is_invulnerable = false

func _update_mana_regen(delta: float) -> void:
	if target_locked:
		return
	if current_mana < max_mana:
		current_mana = minf(max_mana, current_mana + MANA_REGEN_RATE * delta)
		resource_changed.emit(current_mana, max_mana)

func _update_input() -> void:
	# Target cycling (R2/L2)
	if Input.is_action_just_pressed("target_next"):
		_cycle_target(1)
	if Input.is_action_just_pressed("target_prev"):
		_cycle_target(-1)

	# Clear dead/invalid target
	if target_locked and (not is_instance_valid(target_locked) or (target_locked.has_method("is_dead") and target_locked.is_dead())):
		_set_target(null)

	# Spellbar switching (D-pad)
	if Input.is_action_just_pressed("dpad_up"):
		_switch_spellbar(0)
	elif Input.is_action_just_pressed("dpad_left"):
		_switch_spellbar(1)
	elif Input.is_action_just_pressed("dpad_right"):
		_switch_spellbar(2)
	elif Input.is_action_just_pressed("dpad_down"):
		_switch_spellbar(3)

	# Stick clicks
	if Input.is_action_just_pressed("lstick_click"):
		is_running = not is_running
	if Input.is_action_just_pressed("rstick_click"):
		is_crouching = not is_crouching
		is_running = false if is_crouching else is_running

	# Inventory
	if Input.is_action_just_pressed("inventory"):
		pass

	var l2 = Input.is_action_pressed("shoulder_l1")
	var r2_just = Input.is_action_just_pressed("shoulder_r1")

	# L2 + R1 bumper = Major Spell (ultimate)
	if l2 and Input.is_action_just_pressed("target_next") and major_spell_ability:
		_try_use_ability_smart(major_spell_ability)
		return

	# R2 = always basic attack (even if L2 held)
	if r2_just:
		if basic_attack_ability:
			_try_use_ability_smart(basic_attack_ability)
		return

	# L2 + face buttons = spell slots
	if l2:
		if Input.is_action_just_pressed("face_a"):
			_activate_spell_slot(0)
		elif Input.is_action_just_pressed("face_b"):
			_activate_spell_slot(1)
		elif Input.is_action_just_pressed("face_x"):
			_activate_spell_slot(2)
		elif Input.is_action_just_pressed("face_y"):
			_activate_spell_slot(3)
		return

	# Face buttons alone = physical actions
	if Input.is_action_just_pressed("face_a"):
		_perform_jump()
	if Input.is_action_just_pressed("face_b"):
		_perform_dodge()
	if Input.is_action_just_pressed("face_y"):
		_set_target(null)
	if Input.is_action_just_pressed("face_x"):
		pass

func _activate_spell_slot(slot: int) -> void:
	if not hotbar.has(slot):
		return
	_try_use_ability_smart(hotbar[slot])

func _perform_jump() -> void:
	if is_on_floor() and not is_dodging:
		velocity.y = JUMP_VELOCITY

func _perform_dodge() -> void:
	if dodge_cooldown_timer > 0 or is_dodging:
		return
	if combat_system.casting:
		combat_system.cancel_cast()

	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)

	if input_dir.length() > 0.1:
		var forward = _get_camera_forward()
		var right = _get_camera_right()
		dodge_direction = (forward * -input_dir.y + right * input_dir.x).normalized()
	else:
		dodge_direction = -mesh.global_transform.basis.z
		dodge_direction.y = 0
		dodge_direction = dodge_direction.normalized()

	is_dodging = true
	dodge_timer = DODGE_DURATION
	dodge_cooldown_timer = DODGE_COOLDOWN
	dodge_performed.emit()

func _try_use_ability_smart(ability) -> void:
	var needs_enemy = ability.target_type == AbilityData.TargetType.SINGLE_ENEMY
	if needs_enemy and (not target_locked or not is_instance_valid(target_locked)):
		combat_system.ability_failed.emit("No target", ability)
		return
	var target = target_locked if needs_enemy else null
	combat_system.try_use_ability(ability, target)

func _set_target(new_target: Node3D) -> void:
	target_locked = new_target
	target_changed.emit(new_target)

func _cycle_target(direction: int) -> void:
	var enemies = _get_valid_enemies()
	if enemies.is_empty():
		_set_target(null)
		return
	if target_locked == null or not is_instance_valid(target_locked):
		_set_target(enemies[0])
		return
	var idx = enemies.find(target_locked)
	if idx == -1:
		_set_target(enemies[0])
		return
	idx = (idx + direction) % enemies.size()
	if idx < 0:
		idx += enemies.size()
	_set_target(enemies[idx])

func _get_valid_enemies() -> Array:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid: Array = []
	for e in enemies:
		if e is Node3D and not (e.has_method("is_dead") and e.is_dead()):
			valid.append(e)
	valid.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	return valid

func _update_target_indicator(_delta: float) -> void:
	if target_locked and is_instance_valid(target_locked):
		target_indicator.visible = true
		target_indicator.global_position = target_locked.global_position + Vector3(0, 1.0, 0)
	else:
		target_indicator.visible = false

func _on_cast_started(_ability, _duration: float) -> void:
	pass

func _on_cast_cancelled() -> void:
	pass

func get_current_resource() -> float:
	return current_mana

func consume_resource(amount: int) -> void:
	current_mana = maxf(0, current_mana - amount)
	resource_changed.emit(current_mana, max_mana)

func add_resource(amount: int) -> void:
	current_mana = minf(max_mana, current_mana + amount)
	resource_changed.emit(current_mana, max_mana)

func take_damage(amount: float, attacker: Node3D = null) -> void:
	if is_invulnerable:
		return
	current_hp = maxf(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	if attacker and not target_locked:
		_set_target(attacker)

func heal(amount: float) -> void:
	current_hp = minf(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func get_armor() -> float:
	return 50.0

func get_resistance() -> float:
	return 30.0
