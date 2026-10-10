extends Node
## Prueba del Nivel 2: misión de las tres ofrendas, doble realidad, letra O y transición.

var _fails: int = 0


func _ready() -> void:
	# Deja de ser la escena actual para sobrevivir a los cambios de escena.
	await get_tree().process_frame
	get_tree().current_scene = null
	Game.finish_game()
	Game.goto_scene(Game.LEVEL_2_SCENE)
	await _wait(1.0)
	await _run()
	print("LEVEL2 TEST %s (%d fallos)" % ["OK" if _fails == 0 else "FAIL", _fails])
	Game.finish_game()
	get_tree().quit(_fails)


func _check(condition: bool, label: String) -> void:
	print(("OK   " if condition else "FAIL ") + label)
	if not condition:
		_fails += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _hold(player: Player, stand: Vector3, target: Vector3, seconds: float) -> bool:
	player.respawn_at(stand, 0.0)
	await _wait(0.2)
	player.steer_look(target, 1.0)
	await _wait(0.2)
	var focused: bool = player.interactor.focus != null
	player.interactor.press()
	await _wait(seconds)
	player.interactor.release()
	return focused


func _run() -> void:
	var level: Node = get_tree().current_scene
	_check(level.scene_file_path == Game.LEVEL_2_SCENE, "Nivel 2 cargado")
	var player: Player = level.get_node("Player")
	var entity: Olvidado = level.get("entity") as Olvidado
	entity.report_capture = false
	_check(player.flashlight.available and is_zero_approx(float(level.get("reality"))), "llega con linterna y en piel de backrooms")
	for id: String in ["d07", "d08", "d09", "letter", "pyramid", "cp_r1", "cp_r2", "offering_0", "offering_2", "manifest_5", "ambush_7"]:
		_check(bool(level.call("has_marker", id)), "marcador " + id)
	_check(level.get("altar") == null, "la letra no existe hasta despertar la pirámide")
	for index: int in 3:
		var candle: Vector3 = level.call("marker", "offering_%d" % index) + Vector3(0, 0.75, 0)
		var front: Vector3 = level.call("marker", "offering_%d_front" % index)
		var focused: bool = await _hold(player, front, candle, 1.6)
		_check(focused, "foco en la veladora mayor %d" % index)
		_check(int(level.get("lit_count")) == index + 1, "ofrenda %d encendida manteniendo" % index)
		await _wait(1.8)
		_check(float(level.get("reality")) > 0.9, "la nave se muestra real tras la ofrenda %d" % index)
		if index == 0:
			_check(Game.current_checkpoint() == "r1", "checkpoint r1 tras la primera ofrenda")
			await _wait(4.5)
			_check(int(level.get("manifestations")) == 1 and entity.visible, "primera manifestación guionizada")
			entity.vanish()
	_check(Game.current_checkpoint() == "r2", "checkpoint r2 con las tres encendidas")
	await _wait(4.2)
	var altar: LetterAltar = level.get("altar") as LetterAltar
	_check(altar != null and altar.size > 2.0, "la pirámide despierta y aparece la O")
	var letter: Vector3 = level.call("marker", "letter")
	var focused_letter: bool = await _hold(player, Vector3(letter.x, 0.0, letter.z + 4.2), letter, 1.8)
	_check(focused_letter and altar.is_taken, "letra O recogida manteniendo")
	await _wait(11.0)
	var after: String = get_tree().current_scene.scene_file_path
	_check(after == Game.LEVEL_3_SCENE, "transición al Nivel 3 (%s)" % after.get_file())
	# Reaparición: lo encendido sigue encendido.
	Game.checkpoint_scene = Game.LEVEL_2_SCENE
	Game.checkpoint_id = "r1"
	Game.goto_scene(Game.LEVEL_2_SCENE)
	await _wait(1.0)
	level = get_tree().current_scene
	_check(int(level.get("lit_count")) == 1, "reaparición en r1 con una ofrenda encendida")
