# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does WoW-style GCD rotation feel fun on a gamepad in Godot 4.6?
# Date: 2026-03-22
extends CharacterBody3D

signal hp_changed(current: float, maximum: float)
signal enemy_died(enemy: Node3D)
signal debuff_changed()

const MOVE_SPEED: float = 3.0
const ATTACK_RANGE: float = 2.5
const ATTACK_COOLDOWN: float = 2.0
const AGGRO_RANGE: float = 15.0
const DEAGGRO_RANGE: float = 40.0
const ATTACK_DAMAGE: float = 25.0

var max_hp: float = 800.0
var current_hp: float = 800.0
var attack_timer: float = 0.0
var is_aggro: bool = false
var player: Node3D = null
var dead: bool = false
var debuffs: Array = []

var mesh: MeshInstance3D
var hp_bar: Node

func _ready() -> void:
	add_to_group("enemies")
	_setup_visuals()

func _setup_visuals() -> void:
	mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 2.0, 1.0)
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.15, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.05, 0.0)
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	mesh.position.y = 1.0
	add_child(mesh)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 2.0, 1.0)
	collision.shape = shape
	collision.position.y = 1.0
	add_child(collision)

func _physics_process(delta: float) -> void:
	if dead:
		return

	_tick_debuffs(delta)

	if not player:
		_find_player()
		return

	var dist = global_position.distance_to(player.global_position)

	if not is_aggro:
		if dist < AGGRO_RANGE:
			is_aggro = true
	else:
		if dist > DEAGGRO_RANGE:
			is_aggro = false
			return

	if not is_aggro:
		return

	if dist > ATTACK_RANGE:
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0
		velocity = dir * MOVE_SPEED
		mesh.look_at(player.global_position, Vector3.UP)
		mesh.rotation.x = 0
		mesh.rotation.z = 0
	else:
		velocity = Vector3.ZERO

	move_and_slide()

	attack_timer -= delta
	if attack_timer <= 0 and dist <= ATTACK_RANGE:
		_attack()
		attack_timer = ATTACK_COOLDOWN

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _attack() -> void:
	if player and player.has_method("take_damage"):
		var dmg = ATTACK_DAMAGE * (1.0 - get_damage_reduction())
		player.take_damage(dmg, self)
		_flash_attack()

func _flash_attack() -> void:
	if mesh and mesh.material_override:
		var mat: StandardMaterial3D = mesh.material_override
		var original = mat.emission_energy_multiplier
		mat.emission_energy_multiplier = 3.0
		var tween = create_tween()
		tween.tween_property(mat, "emission_energy_multiplier", original, 0.3)

func apply_debuff(debuff: Dictionary) -> void:
	for i in range(debuffs.size()):
		if debuffs[i].id == debuff.id:
			debuffs[i] = debuff
			debuff_changed.emit()
			return
	debuffs.append(debuff)
	debuff_changed.emit()

func _tick_debuffs(delta: float) -> void:
	if debuffs.is_empty():
		return
	var changed = false
	var to_remove: Array = []
	for i in range(debuffs.size()):
		var d = debuffs[i]
		d.remaining -= delta
		if d.remaining <= 0:
			to_remove.append(i)
			changed = true
			continue
		if d.dot_damage > 0 and d.dot_interval > 0:
			d.dot_timer -= delta
			if d.dot_timer <= 0:
				d.dot_timer += d.dot_interval
				take_damage(d.dot_damage)
	for i in range(to_remove.size() - 1, -1, -1):
		debuffs.remove_at(to_remove[i])
	if changed:
		debuff_changed.emit()

func get_damage_reduction() -> float:
	var reduction = 0.0
	for d in debuffs:
		reduction += d.get("damage_reduction", 0.0)
	return clampf(reduction, 0.0, 0.9)

func get_lifesteal_bonus() -> float:
	var bonus = 0.0
	for d in debuffs:
		bonus += d.get("lifesteal_on_hit", 0.0)
	return bonus

func take_damage(amount: float) -> void:
	if dead:
		return
	current_hp = maxf(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	is_aggro = true
	_flash_hit()
	if current_hp <= 0:
		_die()

func _flash_hit() -> void:
	if mesh and mesh.material_override:
		var mat: StandardMaterial3D = mesh.material_override
		var orig_color = mat.albedo_color
		mat.albedo_color = Color.WHITE
		var tween = create_tween()
		tween.tween_property(mat, "albedo_color", orig_color, 0.15)

func _die() -> void:
	dead = true
	enemy_died.emit(self)
	var tween = create_tween()
	tween.tween_property(mesh, "scale", Vector3(1.0, 0.1, 1.0), 0.5)
	tween.tween_callback(queue_free).set_delay(1.0)

func is_dead() -> bool:
	return dead

func get_armor() -> float:
	return 80.0

func get_resistance() -> float:
	return 40.0
