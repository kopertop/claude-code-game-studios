# PROTOTYPE - NOT FOR PRODUCTION
extends Node3D

var target: Node3D
var speed: float = 15.0
var color: Color = Color.WHITE
var on_hit: Callable
var miss_range: float = 40.0
var hit: bool = false

var mesh: MeshInstance3D
var trail_particles: GPUParticles3D

func _ready() -> void:
	_setup_visuals()

func _setup_visuals() -> void:
	mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	add_child(mesh)

	trail_particles = GPUParticles3D.new()
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.direction = Vector3(0, 0, 0)
	particle_mat.spread = 10.0
	particle_mat.initial_velocity_min = 0.5
	particle_mat.initial_velocity_max = 1.0
	particle_mat.gravity = Vector3.ZERO
	particle_mat.scale_min = 0.3
	particle_mat.scale_max = 0.6
	particle_mat.color = Color(color.r, color.g, color.b, 0.6)
	trail_particles.process_material = particle_mat
	trail_particles.amount = 12
	trail_particles.lifetime = 0.3
	trail_particles.speed_scale = 2.0
	var trail_mesh = SphereMesh.new()
	trail_mesh.radius = 0.06
	trail_mesh.height = 0.12
	trail_particles.draw_pass_1 = trail_mesh
	add_child(trail_particles)

func _process(delta: float) -> void:
	if hit:
		return
	if not target or not is_instance_valid(target):
		queue_free()
		return

	var target_pos = target.global_position + Vector3(0, 1.0, 0)
	var dir = (target_pos - global_position).normalized()
	global_position += dir * speed * delta

	var dist = global_position.distance_to(target_pos)
	if dist < 0.6:
		hit = true
		if on_hit.is_valid():
			on_hit.call()
		_explode()
	elif dist > miss_range:
		queue_free()

func _explode() -> void:
	trail_particles.emitting = false
	mesh.visible = false
	var flash = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	flash.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 6.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = mat
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "scale", Vector3(2.0, 2.0, 2.0), 0.2)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
