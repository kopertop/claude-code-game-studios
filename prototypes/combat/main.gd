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

var pause_overlay: CanvasLayer
var pause_label: Label
var pause_hint: Label
var pause_resume_btn: Button
var is_paused: bool = false
var controller_disconnected: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	session_start = Time.get_ticks_msec() / 1000.0
	_build_arena()
	_spawn_player()
	_setup_hud()
	_spawn_enemies()
	_build_pause_overlay()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	if Input.get_connected_joypads().is_empty():
		_pause_for_controller("No controller detected")

func _build_pause_overlay() -> void:
	pause_overlay = CanvasLayer.new()
	pause_overlay.layer = 10
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	pause_overlay.add_child(bg)

	pause_label = Label.new()
	pause_label.text = "PAUSED"
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_label.set_anchors_preset(Control.PRESET_CENTER)
	pause_label.position = Vector2(-200, -50)
	pause_label.size = Vector2(400, 60)
	pause_label.add_theme_font_size_override("font_size", 48)
	pause_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	pause_overlay.add_child(pause_label)

	pause_hint = Label.new()
	pause_hint.text = "Press + to resume"
	pause_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_hint.set_anchors_preset(Control.PRESET_CENTER)
	pause_hint.position = Vector2(-200, 10)
	pause_hint.size = Vector2(400, 30)
	pause_hint.add_theme_font_size_override("font_size", 18)
	pause_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))
	pause_overlay.add_child(pause_hint)

	pause_resume_btn = Button.new()
	pause_resume_btn.text = "Continue without controller"
	pause_resume_btn.set_anchors_preset(Control.PRESET_CENTER)
	pause_resume_btn.position = Vector2(-100, 50)
	pause_resume_btn.size = Vector2(200, 36)
	pause_resume_btn.visible = false
	pause_resume_btn.pressed.connect(_on_resume_without_controller)
	pause_overlay.add_child(pause_resume_btn)

	add_child(pause_overlay)
	pause_overlay.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if controller_disconnected:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_overlay.visible = is_paused
	if is_paused:
		pause_label.text = "PAUSED"
		pause_hint.text = "Press + to resume"
		pause_resume_btn.visible = false
	controller_disconnected = false

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected and Input.get_connected_joypads().is_empty():
		_pause_for_controller("Controller disconnected")
	elif connected and controller_disconnected:
		_resume_from_controller_pause()

func _pause_for_controller(reason: String) -> void:
	controller_disconnected = true
	is_paused = true
	get_tree().paused = true
	pause_overlay.visible = true
	pause_label.text = reason.to_upper()
	pause_hint.text = "Reconnect controller to resume"
	pause_resume_btn.visible = true

func _resume_from_controller_pause() -> void:
	controller_disconnected = false
	is_paused = false
	get_tree().paused = false
	pause_overlay.visible = false

func _on_resume_without_controller() -> void:
	controller_disconnected = false
	is_paused = false
	get_tree().paused = false
	pause_overlay.visible = false

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
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)

	player.combat_system.damage_dealt.connect(_on_damage_tracked)

func _setup_hud() -> void:
	hud = CanvasLayer.new()
	hud.set_script(load("res://combat_hud.gd"))
	hud.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(enemy)
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.hp_changed.connect(func(_c, _m): pass)

func _on_enemy_died(_enemy: Node3D) -> void:
	enemies_killed += 1
	respawn_timer = RESPAWN_DELAY

func _on_damage_tracked(_target: Node3D, amount: float, _crit: bool, _dtype: int) -> void:
	total_damage += amount

func _process(delta: float) -> void:
	if is_paused:
		return
	var alive_enemies = get_tree().get_nodes_in_group("enemies").filter(
		func(e): return not (e.has_method("is_dead") and e.is_dead())
	)
	if alive_enemies.size() == 0:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_spawn_enemies()
			respawn_timer = RESPAWN_DELAY
