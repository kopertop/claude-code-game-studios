# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does WoW-style GCD rotation feel fun on a gamepad in Godot 4.6?
# Date: 2026-03-22
extends RefCounted

const AbilityData = preload("res://ability_data.gd")

static func create_all() -> Array[AbilityData]:
	var abilities: Array[AbilityData] = []

	# Basic Attack (X button, no modifier) - melee staff/weapon hit
	var basic = AbilityData.new()
	basic.id = "warlock_strike"
	basic.display_name = "Fel Strike"
	basic.description = "Melee weapon hit infused with shadow"
	basic.resource_cost = 0
	basic.cast_time = 0.0
	basic.gcd_trigger = true
	basic.cooldown = 0.0
	basic.ability_range = 3.0
	basic.target_type = AbilityData.TargetType.SINGLE_ENEMY
	basic.damage_type = AbilityData.DamageType.SHADOW
	basic.base_damage = 8.0
	basic.scaling_coefficient = 0.8
	basic.can_crit = true
	basic.is_builder = false
	basic.icon_color = Color(0.6, 0.2, 0.8)
	abilities.append(basic)

	# Slot 1 (R2+A): Shadow Bolt - bread and butter cast-time nuke
	var sbolt = AbilityData.new()
	sbolt.id = "shadow_bolt"
	sbolt.display_name = "Shadow Bolt"
	sbolt.description = "Hurls a bolt of shadow energy"
	sbolt.resource_cost = 20
	sbolt.cast_time = 1.8
	sbolt.gcd_trigger = true
	sbolt.cooldown = 0.0
	sbolt.ability_range = 25.0
	sbolt.target_type = AbilityData.TargetType.SINGLE_ENEMY
	sbolt.damage_type = AbilityData.DamageType.SHADOW
	sbolt.base_damage = 25.0
	sbolt.scaling_coefficient = 2.0
	sbolt.can_crit = true
	sbolt.icon_color = Color(0.4, 0.1, 0.6)
	abilities.append(sbolt)

	# Slot 2 (R2+B): Curse of Agony - instant DoT
	var coa = AbilityData.new()
	coa.id = "curse_of_agony"
	coa.display_name = "Curse of Agony"
	coa.description = "Curses the target, dealing shadow damage over time"
	coa.resource_cost = 15
	coa.cast_time = 0.0
	coa.gcd_trigger = true
	coa.cooldown = 0.0
	coa.ability_range = 25.0
	coa.target_type = AbilityData.TargetType.SINGLE_ENEMY
	coa.damage_type = AbilityData.DamageType.SHADOW
	coa.base_damage = 60.0
	coa.scaling_coefficient = 1.5
	coa.can_crit = false
	coa.dot_tick_interval = 2.0
	coa.dot_duration = 12.0
	coa.icon_color = Color(0.5, 0.0, 0.5)
	abilities.append(coa)

	# Slot 3 (R2+X): Immolate - instant fire damage + fire DoT
	var immo = AbilityData.new()
	immo.id = "immolate"
	immo.display_name = "Immolate"
	immo.description = "Burns the target with fel fire"
	immo.resource_cost = 18
	immo.cast_time = 0.0
	immo.gcd_trigger = true
	immo.cooldown = 0.0
	immo.ability_range = 25.0
	immo.target_type = AbilityData.TargetType.SINGLE_ENEMY
	immo.damage_type = AbilityData.DamageType.FIRE
	immo.base_damage = 15.0
	immo.scaling_coefficient = 1.2
	immo.can_crit = true
	immo.dot_tick_interval = 3.0
	immo.dot_duration = 15.0
	immo.icon_color = Color(1.0, 0.4, 0.0)
	abilities.append(immo)

	# Slot 4 (R2+Y): Fel Cleave - instant melee AoE (battle mage feel)
	var cleave = AbilityData.new()
	cleave.id = "fel_cleave"
	cleave.display_name = "Fel Cleave"
	cleave.description = "Swing weapon in a wide arc, hitting all nearby enemies"
	cleave.resource_cost = 30
	cleave.cast_time = 0.0
	cleave.gcd_trigger = true
	cleave.cooldown = 8.0
	cleave.ability_range = 4.0
	cleave.target_type = AbilityData.TargetType.AOE_AROUND_SELF
	cleave.damage_type = AbilityData.DamageType.PHYSICAL
	cleave.base_damage = 20.0
	cleave.scaling_coefficient = 1.5
	cleave.can_crit = true
	cleave.icon_color = Color(0.8, 0.2, 0.2)
	abilities.append(cleave)

	# Slot 5 (L2+A): Drain Life - channeled heal+damage
	var drain = AbilityData.new()
	drain.id = "drain_life"
	drain.display_name = "Drain Life"
	drain.description = "Drains life from target, healing you"
	drain.resource_cost = 25
	drain.cast_time = 2.5
	drain.gcd_trigger = true
	drain.cooldown = 6.0
	drain.ability_range = 20.0
	drain.target_type = AbilityData.TargetType.SINGLE_ENEMY
	drain.damage_type = AbilityData.DamageType.SHADOW
	drain.base_damage = 20.0
	drain.scaling_coefficient = 1.0
	drain.base_healing = 30.0
	drain.can_crit = true
	drain.icon_color = Color(0.2, 0.8, 0.2)
	abilities.append(drain)

	# Slot 6 (L2+B): Dark Pact - off-GCD shield (instant, defensive cooldown)
	var pact = AbilityData.new()
	pact.id = "dark_pact"
	pact.display_name = "Dark Pact"
	pact.description = "Sacrifice mana to shield yourself"
	pact.resource_cost = 40
	pact.cast_time = 0.0
	pact.gcd_trigger = false
	pact.is_off_gcd = true
	pact.cooldown = 15.0
	pact.ability_range = 0.0
	pact.target_type = AbilityData.TargetType.SELF
	pact.damage_type = AbilityData.DamageType.NONE
	pact.base_healing = 50.0
	pact.scaling_coefficient = 0.8
	pact.can_crit = false
	pact.icon_color = Color(0.3, 0.0, 0.5)
	abilities.append(pact)

	return abilities
