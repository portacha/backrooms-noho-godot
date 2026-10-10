extends Node
## Integración N3 con físicas, lectura, refugio, presupuesto y salida por el boquete.

var _fails: int = 0
var _target: String = ""
var _level: Node3D = null
var _saved_config: PackedByteArray = PackedByteArray()
var _had_config: bool = false


func _ready() -> void:
	if not OS.get_environment("WALK_POINTS").is_empty():
		_setup_walk_fixture()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_had_config = FileAccess.file_exists(Game.SAVE_PATH)
	if _had_config:
		_saved_config = FileAccess.get_file_as_bytes(Game.SAVE_PATH)
	get_tree().create_timer(55.0).timeout.connect(func() -> void:
		_restore_config()
		print("LEVEL3 TEST FAIL: tiempo máximo")
		get_tree().quit(1))
	await get_tree().process_frame
	get_tree().current_scene = null
	Game.deaths_in_segment = 0
	Game.checkpoint_scene = ""
	Game.checkpoint_id = ""
	Game.goto_scene("res://scenes/levels/level3.tscn")
	await _wait(2.5)
	_level = get_tree().current_scene as Node3D
	if _level == null or _level.scene_file_path != "res://scenes/levels/level3.tscn":
		_check(false, "carga del Nivel 3")
		get_tree().quit(1)
		return
	var level: Node = _level
	var player: Player = level.get_node("Player")
	var entity: Olvidado = level.get("entity") as Olvidado
	entity.report_capture = false
	_check(player.flashlight.available and not entity.active, "inicio sin cazador y con linterna")
	var materials: Dictionary[int, bool] = {}
	for node: Node in level.find_children("*", "GeometryInstance3D", true, false):
		if player.is_ancestor_of(node):
			continue
		var instance: GeometryInstance3D = node as GeometryInstance3D
		if instance.material_override != null:
			materials[instance.material_override.get_instance_id()] = true
		elif instance is MeshInstance3D:
			var mesh: MeshInstance3D = instance as MeshInstance3D
			for i: int in mesh.mesh.get_surface_count():
				var material: Material = mesh.get_active_material(i)
				if material != null:
					materials[material.get_instance_id()] = true
	print("INFO materiales distintos en escena: %d" % materials.size())
	for key: String in ["start", "cp_r1", "cp_r2", "d10", "d11", "d12", "letter", "wall", "exit", "hollow"]:
		_check(bool(level.call("has_marker", key)), "marcador " + key)
	_check((level.call("zone_cells", "duct") as Array).size() >= 24, "huecos a oscuras repartidos por el túnel")
	# A los huecos se entra caminando, de pie: sin dintel ni botón.
	player.respawn_at(Vector3(21, 0, 50), PI * 0.5)
	await _wait(0.1)
	Input.action_press("move_forward")
	await _wait(2.2)
	Input.action_release("move_forward")
	_check(bool(level.call("in_zone", player.global_position, "duct")) and not player.is_crouched, "entrada al hueco caminando, de pie")
	for id: String in ["d10", "d11", "d12"]:
		entity.vanish()
		var at: Vector3 = level.call("marker", id)
		var stand: Vector3 = Vector3(at.x, 0, at.z) + (Vector3(-1.0, 0, 0) if id == "d10" else Vector3(0, 0, -0.9))
		player.respawn_at(stand, 0)
		await _wait(0.3)
		player.steer_look(at, 1.0)
		await _wait(0.2)
		_check(player.interactor.focus is DocumentPickup, "foco " + id)
		player.interactor.press()
		await _wait(0.2)
		var overlay: DocumentOverlay = level.get_node("Hud/DocumentOverlay")
		_check(overlay.visible and overlay.document != null and String(overlay.document.id).to_lower() == id, "lectura " + id)
		overlay.close()
		await _wait(0.1)
	# Carrera sobre agua dentro del radio atrae de inmediato.
	player.respawn_at(Vector3(39, 0, 104), PI)
	await _wait(0.2)
	entity.teleport_to(Vector3(39, 0, 94))
	entity.pressure_frozen = false
	level.set("chase_count", 0)
	level.set("_budget_spent", false)
	player.is_sprinting = true
	player.noise_made.emit(Game.difficulty.noise_water_sprint, player.global_position)
	_check(entity.current_state() == &"Chase", "salpicadura atrae al cazador")
	entity.pressure_frozen = true
	player.is_sprinting = false
	player.respawn_at(Vector3(34, 0, 102), 0)
	await _wait(0.3)
	_check(entity.current_state() == &"Wander", "el hueco termina la persecución")
	await _wait(1.0)
	_check(player.flashlight.ratio > 0.9, "linterna estable dentro del refugio")
	_check(not entity.profile.chase_enabled, "presupuesto agotado impide otra persecución")
	entity.vanish()
	# Checkpoints restauran posición y estado del cazador al recargar.
	for id: String in ["r1", "r2"]:
		Game.set_checkpoint(id)
		Game.goto_scene("res://scenes/levels/level3.tscn")
		await _wait(0.8)
		level = get_tree().current_scene
		player = level.get_node("Player")
		entity = level.get("entity") as Olvidado
		entity.report_capture = false
		entity.pressure_frozen = true
		_check(player.global_position.distance_to(level.call("marker", "cp_" + id)) < 0.2, "restauración " + id)
		_check(bool(level.get("hunter_started")), "estado cazador restaurado " + id)
	entity.vanish()
	var letter: Vector3 = level.call("marker", "letter")
	player.respawn_at(Vector3(letter.x, 0, letter.z - 1.3), PI)
	await _wait(0.3)
	player.steer_look(letter, 1.0)
	await _wait(0.2)
	_check(player.interactor.focus != null, "foco letra H")
	player.interactor.press()
	await _wait(1.8)
	player.interactor.release()
	var altar: LetterAltar = level.get("altar") as LetterAltar
	_check(altar.is_taken, "letra H recogida manteniendo")
	await _wait(4.5)
	_check(bool(level.get("drained")) and not player.in_water, "agua drenada")
	_check((level.get("_water") as Node3D).visible == false, "planos de agua retirados")
	_check((level.get("_wall_collision") as CollisionShape3D).disabled and (level.get("_broken") as Node3D).visible, "pared rota sin colisión")
	_check(not entity.active, "entidad desvanecida")
	Game.scene_changing.connect(func(path: String) -> void: _target = path)
	# Cruza físicamente el boquete desde la cámara hasta el túnel.
	player.respawn_at(Vector3(37, 0, 149), 0)
	Input.action_press("move_forward")
	await _wait(4.8)
	Input.action_release("move_forward")
	await _wait(2.2)
	_check(_target == Game.LEVEL_4_SCENE or _target == Game.MENU_SCENE, "Game.next_level tras cruzar boquete")
	print("LEVEL3 TEST %s (%d fallos)" % ["OK" if _fails == 0 else "FAIL", _fails])
	_restore_config()
	get_tree().quit(0 if _fails == 0 else 1)


func _check(condition: bool, label: String) -> void:
	print(("OK   " if condition else "FAIL ") + label)
	if not condition:
		_fails += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _restore_config() -> void:
	if _had_config:
		var file: FileAccess = FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_buffer(_saved_config)
	elif FileAccess.file_exists(Game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.SAVE_PATH))


## El caminador genérico prueba colisiones; la amenaza se verifica en la integración.
func _setup_walk_fixture() -> void:
	var level: Node3D = (load("res://scenes/levels/level3.tscn") as PackedScene).instantiate() as Node3D
	add_child(level)
	var entity: Olvidado = level.get("entity") as Olvidado
	entity.vanish()
	entity.pressure_frozen = true
	level.set("hunter_started", true)
	var player: Player = level.get_node("Player")
	player.reparent(self, true)
