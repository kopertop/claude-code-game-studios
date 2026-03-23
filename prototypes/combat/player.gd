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
signal dodge_performed()

const MOVE_SPEED: float = 7.0
const CAST_MOVE_MULTIPLIER: float = 0.5
const DODGE_SPEED: float = 18.0
const DODGE_DURATION: float = 0.4
const DODGE_COOLDOWN: float = 1.0
const DODGE_IFRAMES: float = 0.3
const GRAVITY: float = 20.0
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

var combat_system: CombatSystem
var abilities: Array[AbilityData] = []
var hotbar: Dictionary = {}

var camera_pivot: Node3D
var camera: Camera3D
var camera_yaw: float = 0.0
var camera_pitch: float = -0.3
var mesh: MeshInstance3D

var nearest_enemy: Node3D = null

func _ready() -> void:
	combat_system = CombatSystem.new()
	add_child(combat_system)

	abilities = WarlockAbilities.create_all()
	hotbar[0] = abilities[0]  # basic attack
	for i in range(1, abilities.size()):
		hotbar[i] = abilities[i]

	_setup_visuals()
	_setup_camera()

	combat_system.cast_started.connect(_on_cast_started)
	combat_system.cast_cancelled.connect(_on_cast_cancelled)

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
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 2.0, 0)
	add_child(camera_pivot)

	camera = Camera3D.new()
	camera.position = Vector3(0, 2.0, 6.0)
	camera_pivot.add_child(camera)
	camera.look_at(Vector3(0, 1.0, 0))

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	_update_movement(delta)
	_update_dodge(delta)
	_update_mana_regen(delta)
	_update_input()
	_find_nearest_enemy()

func _update_camera(delta: float) -> void:
	var cam_x = Input.get_axis("camera_left", "camera_right")
	var cam_y = Input.get_axis("camera_up", "camera_down")
	camera_yaw -= cam_x * 3.0 * delta
	camera_pitch -= cam_y * 2.0 * delta
	camera_pitch = clampf(camera_pitch, -1.2, 0.2)

	camera_pivot.global_position = global_position + Vector3(0, 2.0, 0)
	camera_pivot.rotation = Vector3.ZERO
	camera_pivot.rotate_y(camera_yaw)
	camera_pivot.rotate_x(camera_pitch)

func _update_movement(delta: float) -> void:
	if is_dodging:
		return

	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)

	var speed = MOVE_SPEED
	if combat_system.casting:
		speed *= CAST_MOVE_MULTIPLIER

	if input_dir.length() > 0.1:
		var forward = -camera_pivot.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		var right = camera_pivot.global_transform.basis.x
		right.y = 0
		right = right.normalized()

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
	else:
		velocity.y = 0

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
	if current_mana < max_mana:
		current_mana = minf(max_mana, current_mana + MANA_REGEN_RATE * delta)
		resource_changed.emit(current_mana, max_mana)

func _update_input() -> void:
	if Input.is_action_just_pressed("dodge") and dodge_cooldown_timer <= 0 and not is_dodging:
		_perform_dodge()
		return

	var r2 = Input.is_action_pressed("modifier_r2")
	var l2 = Input.is_action_pressed("modifier_l2")

	if not r2 and not l2:
		if Input.is_action_just_pressed("basic_attack"):
			_activate_slot(0)
		return

	if r2:
		if Input.is_action_just_pressed("face_a"):
			_activate_slot(1)
		elif Input.is_action_just_pressed("face_b"):
			_activate_slot(2)
		elif Input.is_action_just_pressed("face_x"):
			_activate_slot(3)
		elif Input.is_action_just_pressed("face_y"):
			_activate_slot(4)
	elif l2:
		if Input.is_action_just_pressed("face_a"):
			_activate_slot(5)
		elif Input.is_action_just_pressed("face_b"):
			_activate_slot(6)

func _activate_slot(slot: int) -> void:
	if not hotbar.has(slot):
		return
	var ability: AbilityData = hotbar[slot]
	ability_slot_activated.emit(slot)
	combat_system.try_use_ability(ability, nearest_enemy)

func _perform_dodge() -> void:
	if combat_system.casting:
		combat_system.cancel_cast()

	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)

	if input_dir.length() > 0.1:
		var forward = -camera_pivot.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		var right = camera_pivot.global_transform.basis.x
		right.y = 0
		right = right.normalized()
		dodge_direction = (forward * -input_dir.y + right * input_dir.x).normalized()
	else:
		dodge_direction = -mesh.global_transform.basis.z
		dodge_direction.y = 0
		dodge_direction = dodge_direction.normalized()

	is_dodging = true
	dodge_timer = DODGE_DURATION
	dodge_cooldown_timer = DODGE_COOLDOWN
	dodge_performed.emit()

func _find_nearest_enemy() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist = 999.0
	nearest_enemy = null
	for e in enemies:
		if not e is Node3D:
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist < closest_dist:
			closest_dist = dist
			nearest_enemy = e

func _on_cast_started(_ability: AbilityData, _duration: float) -> void:
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

func take_damage(amount: float) -> void:
	if is_invulnerable:
		return
	current_hp = maxf(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)

func heal(amount: float) -> void:
	current_hp = minf(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func get_armor() -> float:
	return 50.0

func get_resistance() -> float:
	return 30.0
