extends EntityState
func physics_update(delta: float) -> void:
	if entity.has_sight:
		entity.last_known = entity.player.global_position
	entity.move_to(entity.last_known, entity.speed(&"Chase"), delta)
	if not entity.has_sight and entity.agent.is_navigation_finished():
		machine.transition(&"Investigate")
