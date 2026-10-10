extends EntityState
var elapsed: float = 0.0
func enter(_previous: StringName) -> void:
	elapsed = 0.0
func physics_update(delta: float) -> void:
	elapsed += delta
	entity.move_to(entity.last_known, entity.speed(&"Investigate"), delta)
	if entity.stimulus < Game.difficulty.threshold_investigate or (elapsed > 6.0 and entity.agent.is_navigation_finished()):
		entity.stimulus = 0.0
		machine.transition(&"Wander")
