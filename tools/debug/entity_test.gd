extends Node3D
## Prueba de integración con navegación y colisiones reales, sin cambiar escenas del juego.
var entity: Olvidado
var player: Player
var screen_fx: ScreenFx
var errors: Array[String] = []
var original_difficulty: Difficulty.Id
var screams: int = 0
var relocations: int = 0
var captures: int = 0
var forbidden_seen: bool = false
var monitor_zones: bool = false
var _watchdog: float = 0.0
func _ready() -> void:
	seed(20261009)
	_run.call_deferred()
func check(value: bool, message: String) -> void:
	if not value:
		errors.append(message)
		print("ENTITY TEST FAIL: " + message)
func frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame
func _physics_process(_delta: float) -> void:
	_watchdog += _delta
	if _watchdog > 70.0:
		print("ENTITY TEST FAIL: tiempo máximo")
		get_tree().quit(1)
	if monitor_zones and is_instance_valid(entity) and entity.forbidden(entity.global_position):
		forbidden_seen = true
func _run() -> void:
	original_difficulty = Game.selected_difficulty()
	Game.select_difficulty(Difficulty.Id.NORMAL)
	if not ResourceLoader.exists("res://scenes/levels/generated/entity_arena.scn"):
		print("ENTITY TEST FAIL: falta construir entity_arena")
		get_tree().quit(1)
		return
	var geo: Node3D = (load("res://scenes/levels/generated/entity_arena.scn") as PackedScene).instantiate() as Node3D
	add_child(geo)
	player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	add_child(player)
	player.global_position = Vector3(33, 0, 5)
	player.controls_enabled = false
	entity = (load("res://scenes/entity/olvidado.tscn") as PackedScene).instantiate() as Olvidado
	entity.profile = load("res://resources/entity/profile_level3.tres") as EntityProfile
	entity.profile = entity.profile.duplicate() as EntityProfile
	entity.report_capture = false
	entity.safe_zones = [AABB(Vector3(2, -1, 18), Vector3(6, 4, 6))]
	entity.hide_zones = [AABB(Vector3(32, -1, 24), Vector3(4, 4, 4))]
	add_child(entity)
	entity.global_position = Vector3(5, 0, 5)
	screen_fx = (load("res://scenes/ui/screen_fx.tscn") as PackedScene).instantiate() as ScreenFx
	add_child(screen_fx)
	entity.setup(player, geo, screen_fx)
	entity.screeched.connect(func() -> void: screams += 1)
	entity.relocated.connect(func(_at: Vector3) -> void: relocations += 1)
	entity.caught_player.connect(func() -> void: captures += 1)
	var body_materials: Dictionary[int, bool] = {}
	for node: Node in entity.model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		body_materials[mesh.material_override.get_instance_id()] = true
	check(body_materials.size() == 1, "modelo usa un solo material compartido")
	await frames(20)
	var start: Vector3 = entity.global_position
	await frames(120)
	check(entity.global_position.distance_to(start) > 0.5, "patrulla se desplaza")
	entity.manifest_at(Vector3(9, 0, 5), false)
	player.global_position = Vector3(13, 0, 5)
	entity.rotation.y = PI / 2.0
	player.footstep.emit(Game.difficulty.noise_sprint)
	player.footstep.emit(Game.difficulty.noise_sprint)
	await frames(2)
	check(entity.current_state() == &"Investigate", "ruido cercano → Investigate")
	entity.face(player.global_position)
	entity.add_stimulus(100, player.global_position)
	var before: float = entity.global_position.distance_to(player.global_position)
	await frames(20)
	check(entity.current_state() == &"Chase", "LOS + estímulo → Chase")
	check(entity.global_position.distance_to(player.global_position) < before - 0.5, "persecución se acerca")
	entity.manifest_at(Vector3(9, 0, 9), false)
	player.global_position = Vector3(15, 0, 9)
	entity.face(player.global_position)
	entity.add_stimulus(100.0, player.global_position)
	await frames(3)
	check(not entity.has_sight and entity.current_state() == &"Investigate", "un pilar bloquea LOS: investiga sin Chase")
	entity.pressure_frozen = true
	var frozen: float = entity.stimulus
	var position_before: Vector3 = entity.global_position
	await frames(20)
	check(entity.stimulus == frozen and entity.global_position.is_equal_approx(position_before), "presión congelada")
	entity.pressure_frozen = false
	monitor_zones = true
	for destination: Vector3 in [Vector3(5, 0, 21), Vector3(35, 0, 27)]:
		entity.teleport_to(Vector3(17, 0, 17))
		player.global_position = destination
		entity.stimulus = 100
		entity.force_state(&"Chase")
		await frames(660)
		check(entity.current_state() != &"Attack" and entity.current_state() != &"Chase", "refugio impide captura y persecución")
		check(entity.stimulus == 0.0, "escucha termina sin estímulo")
	check(not forbidden_seen, "no entra en remanso ni conducto")
	monitor_zones = false
	player.global_position = Vector3(21, 0, 11)
	entity.profile = (load("res://resources/entity/profile_level2.tres") as EntityProfile).duplicate() as EntityProfile
	entity.relocation_points = [Vector3(29, 0, 11), Vector3(33, 0, 11)]
	entity.manifest_at(Vector3(7, 0, 11))
	player.flashlight.available = true
	player.flashlight.turn(true)
	player.steer_look(entity.global_position + Vector3.UP * 2.25, 1.0)
	# Un vistazo breve y el haz periférico no consumen el susto.
	await frames(30)
	player.flashlight.turn(false)
	await frames(3)
	check(screams == 0 and entity.current_state() == &"Wander", "vistazo breve seguro")
	player.flashlight.turn(true)
	player.steer_look(entity.global_position + Vector3(0, 2.25, 6), 1.0)
	await frames(90)
	check(screams == 0, "luz periférica segura")
	player.steer_look(entity.global_position + Vector3.UP * 2.25, 1.0)
	var old_distance: float = entity.global_position.distance_to(player.global_position)
	var old_relocations: int = relocations
	await frames(170)
	check(screams == 1, "linterna sostenida emite un chillido")
	check(relocations > old_relocations and entity.active, "reaparece tras emboscada")
	check(entity.global_position.distance_to(player.global_position) < old_distance, "reubicación más cerca")
	check(not player.camera.is_position_in_frustum(entity.global_position + Vector3.UP * 1.3), "reubicación fuera del frustum")
	player.flashlight.turn(false)
	entity.pressure_frozen = true
	get_tree().paused = true
	var pause_position: Vector3 = entity.global_position
	await get_tree().create_timer(0.05, true).timeout
	check(entity.global_position == pause_position, "pausa congela entidad")
	get_tree().paused = false
	Game.select_difficulty(Difficulty.Id.EASY)
	var easy_speed: float = entity.speed(&"Chase")
	Game.select_difficulty(Difficulty.Id.HARD)
	check(entity.speed(&"Chase") > easy_speed, "velocidades Fácil/Difícil")
	entity.profile = (load("res://resources/entity/profile_level3.tres") as EntityProfile).duplicate() as EntityProfile
	# Medición física con el mismo objetivo en ambas dificultades.
	player.global_position = Vector3(33, 0, 5)
	var travelled: Array[float] = []
	for difficulty_id: Difficulty.Id in [Difficulty.Id.EASY, Difficulty.Id.HARD]:
		Game.select_difficulty(difficulty_id)
		entity.pressure_frozen = false
		entity.teleport_to(Vector3(19, 0, 5))
		entity.stimulus = 100.0
		entity.face(player.global_position)
		entity.force_state(&"Chase")
		await frames(40)
		travelled.append(entity.global_position.distance_to(Vector3(19, 0, 5)))
	check(travelled[1] > travelled[0] + 0.2, "velocidad física Difícil mayor que Fácil")
	print("ENTITY SPEED easy=%.3f hard=%.3f" % [travelled[0], travelled[1]])
	entity.pressure_frozen = false
	entity.manifest_at(player.global_position + Vector3(1, 0, 0))
	await frames(2)
	check(entity.current_state() == &"Attack", "distancia <1,5 m → Attack")
	entity.force_state(&"Wander")
	check(entity.current_state() == &"Attack", "Attack terminal")
	await frames(120)
	check(captures == 1, "captura emite caught_player una vez")
	check(not player.controls_enabled, "captura toma cámara")
	check(is_equal_approx(screen_fx.fade, 1.0), "captura termina en negro")
	print("ENTITY TEST OK" if errors.is_empty() else "ENTITY TEST FAIL (%d)" % errors.size())
	var result: int = 0 if errors.is_empty() else 1
	Game.select_difficulty(original_difficulty)
	for audio: Node in find_children("*", "AudioStreamPlayer", true, false) + find_children("*", "AudioStreamPlayer3D", true, false):
		audio.call("stop")
		audio.set("stream", null)
	await frames(6)
	entity.queue_free()
	player.queue_free()
	screen_fx.queue_free()
	geo.queue_free()
	await frames(3)
	get_tree().quit(result)
