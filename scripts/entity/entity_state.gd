class_name EntityState
extends Node
## Contrato común de los estados por nodos.
var entity: CharacterBody3D
var machine: Node
func enter(_previous: StringName) -> void:
	pass
func exit() -> void:
	pass
func can_exit() -> bool:
	return true
func update(_delta: float) -> void:
	pass
func physics_update(_delta: float) -> void:
	pass
