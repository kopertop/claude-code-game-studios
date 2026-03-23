# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does WoW-style GCD rotation feel fun on a gamepad in Godot 4.6?
# Date: 2026-03-22
extends CanvasLayer

const AbilityData = preload("res://ability_data.gd")

var player: Node = null
var hp_bar: ProgressBar
var hp_label: Label
var mana_bar: ProgressBar
var mana_label: Label
var ability_slots: Array[Control] = []
var cast_bar_container: Control
var cast_bar: ProgressBar
var cast_label: Label
var gcd_overlay_timer: float = 0.0
var gcd_overlay_duration: float = 0.0
var target_hp_bar: ProgressBar
var target_label: Label
var damage_number_container: Control
var debug_label: Label

func _ready() -> void:
	_build_ui()

func connect_player(p: Node) -> void:
	player = p
	player.hp_changed.connect(_on_hp_changed)
	player.resource_changed.connect(_on_resource_changed)
	player.combat_system.gcd_started.connect(_on_gcd_started)
	player.combat_system.gcd_ended.connect(_on_gcd_ended)
	player.combat_system.ability_fired.connect(_on_ability_fired)
	player.combat_system.ability_failed.connect(_on_ability_failed)
	player.combat_system.cast_started.connect(_on_cast_started)
	player.combat_system.cast_progress_updated.connect(_on_cast_progress)
	player.combat_system.cast_cancelled.connect(_on_cast_cancelled)
	player.combat_system.damage_dealt.connect(_on_damage_dealt)
	player.combat_system.healing_done.connect(_on_healing_done)
	player.dodge_performed.connect(_on_dodge)

	_on_hp_changed(player.current_hp, player.max_hp)
	_on_resource_changed(player.current_mana, player.max_mana)

func _build_ui() -> void:
	# HP Bar
	var hp_container = _make_bar_container(Vector2(20, 20), Vector2(300, 30))
	hp_bar = hp_container.get_child(0)
	hp_bar.max_value = 100
	hp_bar.value = 100
	_style_bar(hp_bar, Color(0.2, 0.7, 0.2), Color(0.1, 0.2, 0.1))
	hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.position = Vector2(0, 2)
	hp_label.size = Vector2(300, 30)
	hp_container.add_child(hp_label)

	# Mana Bar
	var mana_container = _make_bar_container(Vector2(20, 55), Vector2(300, 22))
	mana_bar = mana_container.get_child(0)
	mana_bar.max_value = 100
	mana_bar.value = 100
	_style_bar(mana_bar, Color(0.15, 0.25, 0.8), Color(0.05, 0.08, 0.25))
	mana_label = Label.new()
	mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mana_label.position = Vector2(0, 0)
	mana_label.size = Vector2(300, 22)
	mana_label.add_theme_font_size_override("font_size", 13)
	mana_container.add_child(mana_label)

	# Ability hotbar
	var hotbar_panel = Control.new()
	hotbar_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar_panel.position = Vector2(-245, -90)
	hotbar_panel.size = Vector2(490, 70)
	add_child(hotbar_panel)

	var slot_labels = ["X:Fel Strike", "R2+A:Shadow Bolt", "R2+B:Curse", "R2+X:Immolate", "R2+Y:Cleave", "L2+A:Drain", "L2+B:Dark Pact"]
	for i in range(7):
		var slot = _make_ability_slot(i, slot_labels[i])
		slot.position = Vector2(i * 70, 0)
		hotbar_panel.add_child(slot)
		ability_slots.append(slot)

	# Cast bar
	cast_bar_container = Control.new()
	cast_bar_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	cast_bar_container.position = Vector2(-150, -130)
	cast_bar_container.size = Vector2(300, 25)
	cast_bar_container.visible = false
	add_child(cast_bar_container)

	cast_bar = ProgressBar.new()
	cast_bar.size = Vector2(300, 25)
	cast_bar.max_value = 1.0
	cast_bar.value = 0.0
	cast_bar.show_percentage = false
	_style_bar(cast_bar, Color(1.0, 0.8, 0.0), Color(0.2, 0.15, 0.0))
	cast_bar_container.add_child(cast_bar)

	cast_label = Label.new()
	cast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cast_label.size = Vector2(300, 25)
	cast_label.add_theme_font_size_override("font_size", 13)
	cast_bar_container.add_child(cast_label)

	# Target HP (above screen center)
	var target_container = Control.new()
	target_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	target_container.position = Vector2(-150, 20)
	target_container.size = Vector2(300, 40)
	add_child(target_container)

	target_label = Label.new()
	target_label.text = "No Target"
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.size = Vector2(300, 20)
	target_container.add_child(target_label)

	target_hp_bar = ProgressBar.new()
	target_hp_bar.position = Vector2(0, 20)
	target_hp_bar.size = Vector2(300, 18)
	target_hp_bar.max_value = 100
	target_hp_bar.value = 100
	target_hp_bar.show_percentage = false
	_style_bar(target_hp_bar, Color(0.8, 0.15, 0.1), Color(0.25, 0.05, 0.02))
	target_container.add_child(target_hp_bar)

	# Damage numbers container
	damage_number_container = Control.new()
	damage_number_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(damage_number_container)

	# Debug info
	debug_label = Label.new()
	debug_label.position = Vector2(20, 680)
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(debug_label)

func _process(delta: float) -> void:
	if gcd_overlay_duration > 0:
		gcd_overlay_timer -= delta
		var gcd_pct = gcd_overlay_timer / gcd_overlay_duration
		for i in range(ability_slots.size()):
			var overlay = ability_slots[i].get_node_or_null("GCDOverlay")
			if overlay and player and player.hotbar.has(i):
				var ability = player.hotbar[i]
				if ability.gcd_trigger and not ability.is_off_gcd:
					overlay.visible = gcd_pct > 0
					overlay.size.y = 60 * maxf(0, gcd_pct)
				else:
					overlay.visible = false
		if gcd_overlay_timer <= 0:
			gcd_overlay_duration = 0
			for slot in ability_slots:
				var ov = slot.get_node_or_null("GCDOverlay")
				if ov:
					ov.visible = false

	# Update cooldown overlays
	if player:
		for i in range(ability_slots.size()):
			if not player.hotbar.has(i):
				continue
			var ability = player.hotbar[i]
			var cd_label = ability_slots[i].get_node_or_null("CDLabel")
			var remaining = player.combat_system.get_cooldown_remaining(ability.id)
			if remaining > 0 and cd_label:
				cd_label.text = "%.1f" % remaining
				cd_label.visible = true
			elif cd_label:
				cd_label.visible = false

	# Update target info
	if player and player.nearest_enemy:
		var enemy = player.nearest_enemy
		if enemy.has_method("is_dead") and not enemy.is_dead():
			target_label.text = "Enemy"
			target_hp_bar.value = (enemy.current_hp / enemy.max_hp) * 100
		else:
			target_label.text = "No Target"
			target_hp_bar.value = 0
	else:
		target_label.text = "No Target"

	# Debug
	if player:
		var gcd_text = "GCD: %.2f" % player.combat_system.gcd_timer if player.combat_system.gcd_active else "GCD: Ready"
		var cast_text = "Casting" if player.combat_system.casting else "Idle"
		debug_label.text = "%s | %s | FPS: %d" % [gcd_text, cast_text, Engine.get_frames_per_second()]

func _make_bar_container(pos: Vector2, bar_size: Vector2) -> Control:
	var container = Control.new()
	container.position = pos
	container.size = bar_size
	add_child(container)

	var bar = ProgressBar.new()
	bar.size = bar_size
	bar.show_percentage = false
	container.add_child(bar)
	return container

func _style_bar(bar: ProgressBar, fill_color: Color, bg_color: Color) -> void:
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg_style)

func _make_ability_slot(index: int, label_text: String) -> Control:
	var slot = Control.new()
	slot.size = Vector2(60, 60)

	var bg = ColorRect.new()
	bg.size = Vector2(60, 60)
	bg.color = Color(0.15, 0.15, 0.2, 0.8)
	slot.add_child(bg)

	var icon = ColorRect.new()
	icon.name = "Icon"
	icon.position = Vector2(4, 4)
	icon.size = Vector2(52, 52)
	icon.color = Color(0.3, 0.3, 0.3)
	slot.add_child(icon)

	var gcd_overlay = ColorRect.new()
	gcd_overlay.name = "GCDOverlay"
	gcd_overlay.position = Vector2(4, 4)
	gcd_overlay.size = Vector2(52, 52)
	gcd_overlay.color = Color(0, 0, 0, 0.5)
	gcd_overlay.visible = false
	slot.add_child(gcd_overlay)

	var cd_lbl = Label.new()
	cd_lbl.name = "CDLabel"
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_lbl.position = Vector2(4, 4)
	cd_lbl.size = Vector2(52, 52)
	cd_lbl.add_theme_font_size_override("font_size", 18)
	cd_lbl.visible = false
	slot.add_child(cd_lbl)

	var name_lbl = Label.new()
	name_lbl.text = label_text.get_slice(":", 0)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(-5, -16)
	name_lbl.size = Vector2(70, 16)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	slot.add_child(name_lbl)

	return slot

func _on_hp_changed(current: float, maximum: float) -> void:
	hp_bar.value = (current / maximum) * 100
	hp_label.text = "%d / %d" % [int(current), int(maximum)]

func _on_resource_changed(current: float, maximum: float) -> void:
	mana_bar.value = (current / maximum) * 100
	mana_label.text = "%d / %d" % [int(current), int(maximum)]

func _on_gcd_started(duration: float) -> void:
	gcd_overlay_timer = duration
	gcd_overlay_duration = duration

func _on_gcd_ended() -> void:
	pass

func _on_ability_fired(ability: AbilityData, _target: Node3D) -> void:
	for i in range(ability_slots.size()):
		if player.hotbar.has(i) and player.hotbar[i].id == ability.id:
			var icon = ability_slots[i].get_node_or_null("Icon")
			if icon:
				var orig = ability.icon_color
				icon.color = Color.WHITE
				var tween = create_tween()
				tween.tween_property(icon, "color", orig, 0.2)
			break

func _on_ability_failed(reason: String, ability: AbilityData) -> void:
	for i in range(ability_slots.size()):
		if player.hotbar.has(i) and player.hotbar[i].id == ability.id:
			var icon = ability_slots[i].get_node_or_null("Icon")
			if icon:
				var orig = icon.color
				icon.color = Color(1, 0.2, 0.2)
				var tween = create_tween()
				tween.tween_property(icon, "color", orig, 0.3)
			break

func _on_cast_started(ability: AbilityData, duration: float) -> void:
	cast_bar_container.visible = true
	cast_bar.value = 0
	cast_label.text = ability.display_name

func _on_cast_progress(progress: float) -> void:
	cast_bar.value = progress

func _on_cast_cancelled() -> void:
	cast_bar_container.visible = false

func _on_damage_dealt(target: Node3D, amount: float, is_crit: bool, _dtype: int) -> void:
	cast_bar_container.visible = false
	if target and target is Node3D:
		_spawn_damage_number(target.global_position, amount, is_crit, false)

func _on_healing_done(target: Node3D, amount: float, is_crit: bool) -> void:
	if target and target is Node3D:
		_spawn_damage_number(target.global_position, amount, is_crit, true)

func _on_dodge() -> void:
	pass

func _spawn_damage_number(world_pos: Vector3, amount: float, is_crit: bool, is_heal: bool) -> void:
	var lbl = Label.new()
	lbl.text = "%d" % int(amount)
	if is_crit:
		lbl.text += "!"
	lbl.add_theme_font_size_override("font_size", 24 if is_crit else 18)
	if is_heal:
		lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	elif is_crit:
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	else:
		lbl.add_theme_color_override("font_color", Color.WHITE)

	lbl.position = Vector2(640 + randf_range(-60, 60), 300 + randf_range(-30, 30))
	damage_number_container.add_child(lbl)

	var tween = create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 80, 1.0)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	tween.tween_callback(lbl.queue_free)

func update_slot_colors() -> void:
	if not player:
		return
	for i in range(ability_slots.size()):
		if player.hotbar.has(i):
			var icon = ability_slots[i].get_node_or_null("Icon")
			if icon:
				icon.color = player.hotbar[i].icon_color
