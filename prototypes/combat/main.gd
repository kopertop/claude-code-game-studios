# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does WoW-style GCD rotation feel fun on a gamepad in Godot 4.6?
# Date: 2026-03-22
extends Node3D

var player_scene: PackedScene
var enemy_scene: PackedScene
var player: CharacterBody3D
var hud: CanvasLayer
var enemies_killed: int = 0
var total_damage: float = 0.0
var session_start: float = 0.0
var respawn_timer: float = 0.0
const RESPAWN_DELAY: float = 5.0

func _ready() -> void:
	session_start = Time.get_ticks_msec() / 1000.0
	_build_arena()
	_spawn_player()
	_setup_hud()
	_spawn_enemies()

func _build_arena() -> void:
	# Ground plane
	var ground = StaticBody3D.new()
	var ground_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(60, 60)
	ground_mesh.mesh = plane
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.15, 0.18, 0.12)
	ground_mesh.material_override = ground_mat
	ground.add_child(ground_mesh)

	var ground_col = CollisionShape3D.new()
	var ground_shape = WorldBoundaryShape3D.new()
	ground_col.shape = ground_shape
	ground.add_child(ground_col)
	add_child(ground)

	# Ambient light
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.03, 0.08)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.2, 0.15, 0.25)
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = RenderingServer.ENV_TONE_MAPPER_ACES
	env.environment = environment
	add_child(env)

	# Directional light (moonlight feel)
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(0.6, 0.55, 0.8)
	sun.light_energy = 0.8
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	# Arena pillars for cover / visual reference
	for i in range(8):
		var angle = i * TAU / 8
		var pos = Vector3(cos(angle) * 15, 0, sin(angle) * 15)
		_spawn_pillar(pos)

func _spawn_pillar(pos: Vector3) -> void:
	var body = StaticBody3D.new()
	body.position = pos

	var mesh_node = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.8
	cyl.height = 4.0
	mesh_node.mesh = cyl
	mesh_node.position.y = 2.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.25, 0.35)
	mesh_node.material_override = mat
	body.add_child(mesh_node)

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.8
	shape.height = 4.0
	col.shape = shape
	col.position.y = 2.0
	body.add_child(col)

	add_child(body)

func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(load("res://player.gd"))
	player.position = Vector3(0, 0, 0)
	player.add_to_group("player")
	add_child(player)

	player.combat_system.damage_dealt.connect(_on_damage_tracked)

func _setup_hud() -> void:
	hud = CanvasLayer.new()
	hud.set_script(load("res://combat_hud.gd"))
	add_child(hud)
	hud.connect_player(player)
	hud.update_slot_colors()

func _spawn_enemies() -> void:
	var positions = [
		Vector3(8, 0, 0),
		Vector3(-8, 0, 5),
		Vector3(5, 0, -10),
	]
	for pos in positions:
		_spawn_enemy_at(pos)

func _spawn_enemy_at(pos: Vector3) -> void:
	var enemy = CharacterBody3D.new()
	enemy.set_script(load("res://enemy.gd"))
	enemy.position = pos
	add_child(enemy)
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.hp_changed.connect(func(_c, _m): pass)

func _on_enemy_died(_enemy: Node3D) -> void:
	enemies_killed += 1
	respawn_timer = RESPAWN_DELAY

func _on_damage_tracked(_target: Node3D, amount: float, _crit: bool, _dtype: int) -> void:
	total_damage += amount

func _process(delta: float) -> void:
	var alive_enemies = get_tree().get_nodes_in_group("enemies").filter(
		func(e): return not (e.has_method("is_dead") and e.is_dead())
	)
	if alive_enemies.size() == 0:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_spawn_enemies()
			respawn_timer = RESPAWN_DELAY
