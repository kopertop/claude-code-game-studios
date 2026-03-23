# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does WoW-style GCD rotation feel fun on a gamepad in Godot 4.6?
# Date: 2026-03-22
extends Resource

enum TargetType { SELF, SINGLE_ENEMY, AOE_AROUND_SELF, AOE_CONE }
enum DamageType { PHYSICAL, FIRE, SHADOW, ARCANE, NATURE, NONE }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var resource_cost: int = 0
@export var cast_time: float = 0.0
@export var gcd_trigger: bool = true
@export var cooldown: float = 0.0
@export var ability_range: float = 3.0
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var base_damage: float = 0.0
@export var scaling_coefficient: float = 1.0
@export var base_healing: float = 0.0
@export var can_crit: bool = true
@export var is_builder: bool = false
@export var builder_amount: int = 0
@export var is_off_gcd: bool = false
@export var icon_color: Color = Color.WHITE
@export var dot_tick_interval: float = 0.0
@export var dot_duration: float = 0.0
@export var lifesteal_pct: float = 0.0
@export var is_debuff: bool = false
@export var debuff_duration: float = 0.0
@export var debuff_damage_reduction: float = 0.0
@export var debuff_lifesteal_on_hit: float = 0.0
@export var debuff_dot_damage: float = 0.0
@export var debuff_dot_interval: float = 0.0
@export var projectile_speed: float = 0.0
@export var projectile_color: Color = Color.WHITE
