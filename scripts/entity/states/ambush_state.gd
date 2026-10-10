extends EntityState
var remaining: float = 0.0
func enter(_previous: StringName) -> void:
	remaining = randf_range(0.6, 1.2)
	if entity.ambush_from_light and not entity._shriek_used:
		entity._shriek_used = true
		entity.screeched.emit()
		entity.vanish()
		entity.play_audio(entity.voice, "static_shriek.ogg")
	else:
		entity.vanish()
func physics_update(delta: float) -> void:
	remaining -= delta
	if remaining > 0.0:
		return
	var destination: Vector3 = entity.relocation_candidate()
	if destination != Vector3.INF and not entity.sheltered():
		entity.teleport_to(destination)
	else:
		entity.vanish()
	entity._gaze = 0.0
	entity._light_contact = false
	machine.transition(&"Wander")
