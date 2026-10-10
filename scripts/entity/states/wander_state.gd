extends EntityState
var destination: Vector3
func enter(_previous: StringName) -> void:
	destination = entity.global_position
func physics_update(delta: float) -> void:
	if not entity.profile.wander_enabled or entity.manifested:
		return
	if entity.global_position.distance_to(destination) < 0.8 or entity.agent.is_navigation_finished():
		destination = EntityNav.random_point(entity.region)
	entity.move_to(destination, entity.speed(&"Wander"), delta)
