extends Node
## Recorrido de integración de Nivel 2, con focos y secuencias verificables.

var _fails: int = 0
var _level: Node
var _player: Player
var _overlay: DocumentOverlay
var _screech_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	_level = (load("res://scenes/levels/level2.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(_level)
	get_tree().current_scene = _level
	await _wait(2.0)
	_player = _level.get_node("Player")
	_overlay = _level.get_node("Hud/DocumentOverlay")
	_check(_level.scene_file_path.ends_with("level2.tscn"), "escena Nivel 2 carga")
	for key: String in ["start", "d07", "d08", "d09", "letter", "manifest_0", "manifest_1", "cp_r1", "cp_r2"]:
		_check(_level.call("has_marker", key), "marcador " + key)
	for id: String in ["d07", "d08", "d09"]:
		await _read_document(id)
	await _trigger_first_manifestation()
	await _trigger_random_manifestation()
	await _take_letter()
	_check(_level.get("_ritual"), "ritual de la O iniciado")
	await _wait(12.0)
	var altar: LetterAltar = _level.get("_altar")
	_check(altar.is_taken, "letra O recogida")
	_check(_level.get("_manifestations") >= 3, "manifestación guionizada tras la letra")
	_check(_level.get("_manifestations") <= Game.difficulty.level2_manifestations, "presupuesto de manifestaciones respetado")
	_check(_level.get("_mutations") <= 5, "mutaciones limitadas")
	var next_scene: String = Game.LEVEL_3_SCENE if ResourceLoader.exists(Game.LEVEL_3_SCENE) else Game.MENU_SCENE
	_check(get_tree().current_scene.scene_file_path == next_scene, "transición posterior a O: " + next_scene.get_file())
	if _fails == 0:
		print("LEVEL2 TEST OK")
	else:
		print("LEVEL2 TEST FAIL (%d fallos)" % _fails)
	get_tree().quit(_fails)

func _check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		_fails += 1

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _read_document(id: String) -> void:
	var at: Vector3 = _level.call("marker", id)
	_player.global_position = Vector3(at.x, 0.0, at.z + 0.85)
	_player.steer_look(at, 1.0)
	await _wait(0.25)
	_player.interactor.press()
	await _wait(0.25)
	_check(_overlay.visible and _overlay.document != null and String(_overlay.document.id).to_lower() == id, "documento " + id + " legible")
	_overlay.close()
	await _wait(0.35)

func _trigger_first_manifestation() -> void:
	var at: Vector3 = _level.call("marker", "manifest_0")
	_player.global_position = at + Vector3(0.0, 0.0, 7.0)
	await _wait(0.4)
	_check(_level.get("_manifestations") >= 1, "manifestación guionizada en planicie")
	var entity: Olvidado = _level.get("_entity")
	entity.screeched.connect(func() -> void: _screech_count += 1)
	entity.ambush_from_light = true
	entity.force_state(&"Ambush")
	await _wait(0.15)
	_check(_screech_count == 1, "chillido único al iluminar la entidad")
	entity.ambush_from_light = false
	_level.get("_entity").vanish()
	_level.set("_active_manifestation", false)
	await _wait(0.3)

func _trigger_random_manifestation() -> void:
	var at: Vector3 = _level.call("marker", "manifest_1")
	_player.global_position = at + Vector3(0.0, 0.0, 4.0)
	await _wait(0.4)
	_check(_level.get("_manifestations") >= 2, "manifestación aleatoria del tramo de ofrendas")
	_level.get("_entity").vanish()
	_level.set("_active_manifestation", false)
	await _wait(0.3)

func _take_letter() -> void:
	var at: Vector3 = _level.call("marker", "letter")
	_player.global_position = _level.call("marker", "altar") + Vector3(3.3, 0.0, 0.0)
	_player.steer_look(at, 1.0)
	await _wait(0.3)
	var altar: LetterAltar = _level.get("_altar")
	_check(altar.spot.interaction_range >= 4.5, "alcance amplio desde el pie")
	_player.interactor.press()
	await _wait(1.7)
