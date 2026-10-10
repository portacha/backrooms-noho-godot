extends Node
## Prueba integral del Umbral: lectura, pétalos, caídas, carrera y silencio.

var _fails: int = 0
var _target: String = ""
var _cross_time: float = 0.0
var _game_time: float = 0.0
var _completed: bool = false

func _process(delta: float) -> void:
	_game_time += delta

func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	Game.scene_changing.connect(func(path: String) -> void: _target = path)
	get_tree().create_timer(180.0).timeout.connect(func() -> void:
		print("LEVEL4 TEST FAIL: tiempo agotado")
		get_tree().quit(1))
	await _run()
	_check(_completed, "la prueba completa terminó sin abortar")
	print("LEVEL4 TEST %s (%d fallos)" % ["OK" if _fails == 0 else "FAIL", _fails])
	Game.finish_game()
	get_tree().quit(_fails)

func _check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		_fails += 1

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _run() -> void:
	if not ResourceLoader.exists("res://scenes/levels/generated/level4.scn"):
		_check(false, "falta reconstruir la geometría del Nivel 4")
		return
	Game.finish_game()
	Game.goto_scene(Game.LEVEL_4_SCENE)
	await _wait(2.0)
	var level: LevelBase = get_tree().current_scene as LevelBase
	if level == null:
		_check(false, "escena del nivel cargada")
		return
	var player: Player = level.player
	var entity: Olvidado = level.entity
	entity.report_capture = false
	_check(player.sprint_enabled and player.flashlight.available, "sprint y linterna disponibles")
	for id: String in ["start", "cp_start", "cp_r1", "cp_altar", "letter", "door", "neon", "d13", "d14", "d15", "presence", "chase_from", "bridge_0", "bridge_1", "bridge_2", "bridge_3"]:
		_check(level.has_marker(id), "marcador " + id)
	var lights: int = 0
	for node: Node in level.find_children("*", "Light3D", true, false):
		lights += 1
	_check(lights == 1, "única luz dinámica = linterna")
	var materials: Dictionary = {}
	for node: Node in level.geo.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		for surface: int in mesh.mesh.get_surface_count():
			var mat: Material = mesh.get_active_material(surface)
			if mat != null:
				materials[mat.get_instance_id()] = true
	print("INFO materiales de la geometría horneada: %d" % materials.size())
	var overlay: DocumentOverlay = level.hud.get_node("DocumentOverlay")
	for id: String in ["d13", "d14", "d15"]:
		var at: Vector3 = level.marker(id)
		player.respawn_at(Vector3(at.x, 0, at.z - 1.1), PI)
		await _wait(0.1)
		player.steer_look(at, 1.0)
		await _wait(0.2)
		_check(player.interactor.focus is DocumentPickup, "foco en " + id)
		player.interactor.press()
		await _wait(0.2)
		_check(overlay.visible and overlay.document != null and overlay.document.id == StringName(id.to_upper()), "lectura " + id)
		overlay.close()
	# La placa no abre la salida antes de obtener la O.
	player.respawn_at(level.marker("door"), PI)
	await _wait(0.2)
	_check(not bool(level.get("crossing")), "puerta bloqueada antes de la O")
	var trail: PackedVector3Array = level.get("_trail_points")
	_check(trail.size() > 40, "sendero seguro muestreado")
	var reveal_index: int = 6
	var petals_at: Vector3 = trail[reveal_index]
	_check(float((level.get("_reveals") as PackedFloat32Array)[reveal_index]) == 0.0, "pétalos invisibles sin linterna")
	player.respawn_at(Vector3(petals_at.x, 0.0, petals_at.z - 2.0), PI)
	player.flashlight.turn(true)
	await _wait(0.1)
	player.steer_look(petals_at, 1.0)
	await _wait(0.7)
	_check(float((level.get("_reveals") as PackedFloat32Array)[reveal_index]) > 0.8, "el haz revela pétalos")
	player.flashlight.turn(false)
	await _wait(1.0)
	_check(float((level.get("_reveals") as PackedFloat32Array)[reveal_index]) > 0.4, "el brillo decae despacio")
	for id: int in 4:
		player.respawn_at(level.marker("bridge_%d" % id), PI)
		await _wait(0.15)
		_check(int(level.get("current_bridge")) == id, "registra inicio del puente %d" % id)
		player.global_position.y = -7.0
		await _wait(0.5)
		_check(player.global_position.distance_to(level.marker("bridge_%d" % id)) < 0.4 and not Game.is_dead, "caída retorna al puente %d sin muerte" % id)
	player.respawn_at(level.marker("presence_trigger"), PI)
	await _wait(0.3)
	_check(bool(level.get("presence_seen")) and entity.visible, "única presencia distante")
	await _wait(2.7)
	_check(not entity.visible, "presencia desaparece sin persecución")
	# Reconstrucción en checkpoint: letra aún pendiente tras reintento.
	Game.checkpoint_scene = Game.LEVEL_4_SCENE
	Game.checkpoint_id = "altar"
	Game.goto_scene(Game.LEVEL_4_SCENE)
	await _wait(2.0)
	level = get_tree().current_scene as LevelBase
	player = level.player
	entity = level.entity
	entity.report_capture = false
	var altar: LetterAltar = level.get("altar") as LetterAltar
	_check(not altar.is_taken and player.global_position.distance_to(level.marker("cp_altar")) < 0.4, "reintento en altar conserva O pendiente")
	level.connect("door_crossed", func() -> void: _cross_time = _game_time)
	var letter: Vector3 = level.marker("letter")
	player.respawn_at(Vector3(letter.x, 0, letter.z - 1.4), PI)
	await _wait(0.1)
	player.steer_look(letter, 1.0)
	await _wait(0.2)
	_check(player.interactor.focus == altar.spot, "foco en la última O")
	player.interactor.press()
	await _wait(1.7)
	_check(altar.is_taken and not player.controls_enabled, "ritual por interacción sostenida")
	await _wait(3.3)
	_check(bool(level.get("chase_started")) and entity.enraged and player.controls_enabled, "furia y carrera final")
	var budget: float = 25.0
	Input.action_press("sprint")
	Input.action_press("move_forward")
	while budget > 0.0 and is_instance_valid(level) and not bool(level.get("crossing")):
		await get_tree().physics_frame
		budget -= get_physics_process_delta_time()
		if budget < 21.0 and is_instance_valid(level):
			_check_flashlight_once(player)
	Input.action_release("move_forward")
	Input.action_release("sprint")
	_check(is_instance_valid(level) and bool(level.get("crossing")), "sprint real llega a la puerta sin captura")
	if is_instance_valid(level) and bool(level.get("crossing")):
		await _wait(0.3)
		_check(level.screen_fx.fade == 1.0, "negro absoluto al cruzar")
		var silent: bool = true
		for node: Node in level.find_children("*", "", true, false):
			if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
				silent = silent and not bool(node.get("playing"))
		_check(silent, "todos los reproductores detenidos")
		await _wait(0.25)
		_check(is_instance_valid(level) and level.screen_fx.fade == 1.0, "silencio y negro se sostienen medio segundo")
		await _wait(0.4)
		var expected: String = Game.ENDING_SCENE if ResourceLoader.exists(Game.ENDING_SCENE) else Game.MENU_SCENE
		_check(_target == expected and get_tree().current_scene.scene_file_path == expected, "transición a " + expected.get_file())
		_check(_game_time - _cross_time >= 0.5, "al menos 0,5 s antes de siguiente escena")
	# Pararse en la recta permite la captura; correr fue comprobado arriba.
	Game.checkpoint_scene = Game.LEVEL_4_SCENE
	Game.checkpoint_id = "altar"
	Game.goto_scene(Game.LEVEL_4_SCENE)
	await _wait(2.0)
	level = get_tree().current_scene as LevelBase
	entity = level.entity
	entity.report_capture = false
	level.player.respawn_at(Vector3(61, 0, 73), PI)
	level.call("_start_chase")
	var left: float = Game.difficulty.final_chase_seconds + 8.0
	while left > 0.0 and entity.current_state() != &"Attack":
		await _wait(0.2)
		left -= 0.2
	_check(entity.current_state() == &"Attack", "detenerse permite captura en la carrera")
	_completed = true

var _flash_checked: bool = false
func _check_flashlight_once(player: Player) -> void:
	if not _flash_checked:
		_flash_checked = true
		_check(player.flashlight.ratio == 0.0, "linterna muerta tras tres segundos de carrera")
