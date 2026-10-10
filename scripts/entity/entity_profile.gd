class_name EntityProfile
extends Resource
## Disparadores por nivel; las magnitudes provienen del ajuste estándar, Game.difficulty.
enum LightReaction { NONE, AMBUSH, INVESTIGATE }
@export var wander_enabled: bool = true
@export var investigate_enabled: bool = true
@export var chase_enabled: bool = true
@export var ambush_enabled: bool = true
@export var attack_enabled: bool = true
@export var light_reaction: LightReaction = LightReaction.INVESTIGATE
@export var speed_scale: float = 1.0
@export var radius_scale: float = 1.0
@export var stagnation_ambush: bool = true
@export var starts_hidden: bool = false
