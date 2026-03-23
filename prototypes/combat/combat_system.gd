# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does WoW-style GCD rotation feel fun on a gamepad in Godot 4.6?
# Date: 2026-03-22
extends Node

const AbilityData = preload("res://ability_data.gd")

signal ability_fired(ability: AbilityData, target: Node3D)
signal ability_failed(reason: String, ability: AbilityData)
signal gcd_started(duration: float)
signal gcd_ended()
signal cooldown_updated(ability_id: String, remaining: float, total: float)
signal cast_started(ability: AbilityData, duration: float)
signal cast_progress_updated(progress: float)
signal cast_cancelled()
signal damage_dealt(target: Node3D, amount: float, is_crit: bool, damage_type: int)
signal healing_done(target: Node3D, amount: float, is_crit: bool)

const BASE_GCD: float = 1.5
const MIN_GCD: float = 0.75
const GCD_QUEUE_WINDOW: float = 0.5
const MELEE_RANGE: float = 3.0
const ARMOR_CONSTANT: float = 500.0
const ARMOR_LEVEL_SCALING: float = 10.0
const BASE_CRIT_MULTIPLIER: float = 1.5

var gcd_timer: float = 0.0
var gcd_duration: float = BASE_GCD
var gcd_active: bool = false
var cooldowns: Dictionary = {}
var queued_ability: AbilityData = null
var casting: bool = false
var cast_timer: float = 0.0
var cast_ability: AbilityData = null
var cast_target: Node3D = null

var player_stats: Dictionary = {
	"power_level": 10,
	"might": 20,
	"intellect": 40,
	"finesse": 15,
	"physical_power": 20,
	"spell_power": 60,
	"crit_chance": 0.15,
	"attack_speed_bonus": 0.0,
	"armor": 50,
	"resistance": 30,
}

func get_effective_gcd() -> float:
	var spd = player_stats.get("attack_speed_bonus", 0.0)
	return clampf(BASE_GCD / (1.0 + spd), MIN_GCD, BASE_GCD)

func _process(delta: float) -> void:
	if gcd_active:
		gcd_timer -= delta
		if gcd_timer <= 0.0:
			gcd_active = false
			gcd_timer = 0.0
			gcd_ended.emit()
			if queued_ability:
				var qa = queued_ability
				queued_ability = null
				try_use_ability(qa, cast_target)

	for aid in cooldowns.keys():
		cooldowns[aid] -= delta
		if cooldowns[aid] <= 0.0:
			cooldowns.erase(aid)

	if casting:
		cast_timer += delta
		var progress = cast_timer / cast_ability.cast_time
		cast_progress_updated.emit(progress)
		if progress >= 1.0:
			_execute_ability(cast_ability, cast_target)
			casting = false
			cast_ability = null

func try_use_ability(ability: AbilityData, target: Node3D) -> bool:
	if cooldowns.has(ability.id):
		ability_failed.emit("On cooldown", ability)
		return false

	if not ability.is_off_gcd and gcd_active:
		if gcd_timer <= GCD_QUEUE_WINDOW:
			queued_ability = ability
			cast_target = target
			return false
		ability_failed.emit("GCD active", ability)
		return false

	var owner_node = get_parent()
	if owner_node and owner_node.has_method("get_current_resource"):
		var current = owner_node.get_current_resource()
		if current < ability.resource_cost:
			ability_failed.emit("Not enough mana", ability)
			return false

	if casting:
		cancel_cast()

	if ability.cast_time > 0.0:
		casting = true
		cast_timer = 0.0
		cast_ability = ability
		cast_target = target
		cast_started.emit(ability, ability.cast_time)
		return true

	_execute_ability(ability, target)
	return true

func cancel_cast() -> void:
	if casting:
		casting = false
		cast_ability = null
		cast_cancelled.emit()

func _execute_ability(ability: AbilityData, target: Node3D) -> void:
	var owner_node = get_parent()
	if owner_node and owner_node.has_method("consume_resource"):
		owner_node.consume_resource(ability.resource_cost)
	if ability.is_builder and owner_node and owner_node.has_method("add_resource"):
		owner_node.add_resource(ability.builder_amount)

	if ability.gcd_trigger and not ability.is_off_gcd:
		gcd_duration = get_effective_gcd()
		gcd_timer = gcd_duration
		gcd_active = true
		gcd_started.emit(gcd_duration)

	if ability.cooldown > 0.0:
		cooldowns[ability.id] = ability.cooldown

	ability_fired.emit(ability, target)

	if ability.base_damage > 0.0 and target:
		var result = calculate_damage(ability, player_stats, target)
		damage_dealt.emit(target, result.amount, result.is_crit, ability.damage_type)
		if target.has_method("take_damage"):
			target.take_damage(result.amount)

	if ability.base_healing > 0.0 and owner_node and owner_node.has_method("heal"):
		var heal_result = calculate_healing(ability, player_stats)
		healing_done.emit(owner_node, heal_result.amount, heal_result.is_crit)
		owner_node.heal(heal_result.amount)

func calculate_damage(ability: AbilityData, stats: Dictionary, target: Node3D) -> Dictionary:
	var scaling_stat = stats.get("spell_power", 0.0)
	if ability.damage_type == AbilityData.DamageType.PHYSICAL:
		scaling_stat = stats.get("physical_power", 0.0)

	var raw = ability.base_damage + (scaling_stat * ability.scaling_coefficient)
	var is_crit = false
	if ability.can_crit and randf() < stats.get("crit_chance", 0.0):
		raw *= BASE_CRIT_MULTIPLIER
		is_crit = true

	var target_armor = 50.0
	var target_resistance = 30.0
	if target.has_method("get_armor"):
		target_armor = target.get_armor()
	if target.has_method("get_resistance"):
		target_resistance = target.get_resistance()

	var reduction = 0.0
	var pl = stats.get("power_level", 1)
	if ability.damage_type == AbilityData.DamageType.PHYSICAL:
		reduction = target_armor / (target_armor + ARMOR_CONSTANT + pl * ARMOR_LEVEL_SCALING)
	else:
		reduction = target_resistance / (target_resistance + ARMOR_CONSTANT + pl * ARMOR_LEVEL_SCALING)

	var final_dmg = maxf(1.0, raw * (1.0 - reduction))
	return {"amount": final_dmg, "is_crit": is_crit}

func calculate_healing(ability: AbilityData, stats: Dictionary) -> Dictionary:
	var scaling_stat = stats.get("spell_power", 0.0)
	var raw = ability.base_healing + (scaling_stat * ability.scaling_coefficient)
	var is_crit = false
	if ability.can_crit and randf() < stats.get("crit_chance", 0.0):
		raw *= BASE_CRIT_MULTIPLIER
		is_crit = true
	return {"amount": raw, "is_crit": is_crit}

func is_ability_ready(ability: AbilityData) -> bool:
	if cooldowns.has(ability.id):
		return false
	if not ability.is_off_gcd and gcd_active:
		return false
	return true

func get_cooldown_remaining(ability_id: String) -> float:
	return cooldowns.get(ability_id, 0.0)
