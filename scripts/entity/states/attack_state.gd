extends EntityState
var elapsed: float = 0.0
var finished: bool = false
func enter(_previous: StringName) -> void:
	elapsed = 0.0
	finished = false
	entity.velocity = Vector3.ZERO
	entity.player.set_cutscene(true)
	entity.face(entity.player.global_position)
	entity.play_audio(entity.voice, "screech.ogg")
	Game.caption("[chillido]")
func can_exit() -> bool:
	return false
func physics_update(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	entity.player.steer_look(entity.global_position + Vector3.UP * 2.3, minf(1.0, delta * 12.0))
	if elapsed >= 1.0 and elapsed - delta < 1.0 and entity.screen_fx != null:
		entity.screen_fx.fade_color = Color.BLACK
		entity.screen_fx.fade_to(1.0, 0.3)
	if elapsed >= 1.3:
		entity.steps.stop()
		entity.breath.stop()
		entity.voice.stop()
	if elapsed >= 1.8:
		finished = true
		entity.caught_player.emit()
		if entity.report_capture:
			Game.player_caught()
