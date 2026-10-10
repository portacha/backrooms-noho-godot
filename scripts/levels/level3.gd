extends LevelBase
## El Pasaje de las Calaveras: agua, refugios y cazador con presupuesto por tramo.

const WATER_LEVEL: float = 0.14

var altar: LetterAltar = null
var drained: bool = false
var hunter_started: bool = false
var chase_count: int = 0
var loop_count: int = 0
var _segment: int = 0
var _last_state: StringName = &"Wander"
var _last_position: Vector3 = Vector3.ZERO
var _loop_armed: bool = false
var _finishing: bool = false
var _water: Node3D = null
var _wall: Node3D = null
var _broken: Node3D = null
var _wall_collision: CollisionShape3D = null
var _documents: Array[DocumentPickup] = []
var _hint: Array[MeshInstance3D] = []
var _reality_step: int = 0
var _glimpse_in: float = 30.0
var _budget_spent: bool = false
var _budget_relocated: bool = false


func _ready() -> void:
	super()
	player.flashlight.available = true
	player.flashlight.turn(true)
	player.sprint_enabled = true
	set_touch_button(&"flashlight_visible", true)
	set_touch_button(&"sprint_visible", true)
	_build_water()
	_build_wall()
	for id: String in ["d10", "d11", "d12"]:
		var path: String = "res://resources/documents/%s.tres" % id
		if ResourceLoader.exists(path):
			var document: DocumentPickup = add_document(marker(id), path, 2.4)
			if id == "d10":
				document.document = document.document.duplicate() as DocumentData
				document.document.body += "\nEn el conducto los pasos se quedan afuera. Aquí la luz no falla."
			_documents.append(document)
			if id == "d10":
				_add_paper(document)
	if ResourceLoader.exists("res://assets/models/letter_h.glb"):
		altar = add_letter("letter_h", "letter", 0.0)
	else:
		altar = LetterAltar.new()
		add_child(altar)
		push_warning("Modelo pendiente: letter_h")
	altar.taken.connect(_take_letter)
	spawn_entity("res://resources/entity/profile_level3.tres")
	entity.state_changed.connect(_on_state_changed)
	player.noise_made.connect(_on_noise)
	var saved: String = spawn_at_checkpoint("start", PI)
	# Estado de realidad que corresponde al punto de reaparición.
	set_reality(0.0)
	for beat: Dictionary in REALITY_BEATS:
		if player.global_position.z >= float(beat["z"]):
			_reality_step += 1
			set_reality(beat["to"])
	_last_position = player.global_position
	if saved == "r1" or saved == "r2":
		hunter_started = true
		_segment = 1 if saved == "r1" else 2
		_relocate_hunter()
	else:
		Game.set_checkpoint("start")
	if saved != "r1" and saved != "r2":
		add_checkpoint("r1", "cp_r1", 2.0)
	if saved != "r2":
		add_checkpoint("r2", "cp_r2", 2.0)
	checkpoint_reached.connect(_on_checkpoint)
	var ambience: AudioStream = load_audio("res://assets/audio/ambient/level3_tunnel_loop.ogg")
	if ambience != null:
		add_loop(ambience, -12.0)
	if Game.wants_petal_hint():
		_show_refuge_hint()


func _process(delta: float) -> void:
	super(delta)
	_update_reality(delta)
	update_letter_fx(altar)
	if not hunter_started and player.global_position.z >= marker("hunter_gate").z:
		hunter_started = true
		_relocate_hunter()
	if not drained:
		_update_loop()
	if drained and not _finishing and player.global_position.distance_to(marker("exit")) < 1.5:
		_finishing = true
		cut_all_audio()
		finish_level()


func _physics_process(_delta: float) -> void:
	var at: Vector3 = player.global_position
	# Anticipa el dintel con el borde de la cápsula, también al entrar de lado.
	var low: bool = in_zone(at, "duct")
	for offset: Vector3 in [Vector3(0.4, 0, 0), Vector3(-0.4, 0, 0), Vector3(0, 0, 0.4), Vector3(0, 0, -0.4)]:
		low = low or in_zone(at + offset, "duct")
	if low:
		player.set_crouched(true)
	elif player.is_crouched:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.9, at + Vector3.UP * 1.9, 1, [player.get_rid()])
		if player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			player.set_crouched(false)
	player.in_water = not drained and in_zone(at, "water")
	if entity != null and in_zone(at, "duct"):
		player.flashlight.set_threat.call_deferred(INF, false)
		if entity.current_state() == &"Chase":
			entity.force_state(&"Wander")
	if _budget_spent and entity != null and entity.active:
		# No se recorta una persecución permitida; se enfría después de perder el rastro.
		if entity.current_state() not in [&"Chase", &"Attack"]:
			entity.profile.chase_enabled = false
			entity.profile.attack_enabled = false
			entity.profile.stagnation_ambush = false
			entity.stimulus = 0.0
			if not entity.pressure_frozen and not in_zone(at, "duct"):
				entity.force_state(&"Wander")
				if not _budget_relocated and not player.camera.is_position_in_frustum(entity.global_position + Vector3.UP):
					_relocate_hunter()
					_budget_relocated = true


## Doble realidad (docs/04, contaminación 50 %). El nivel abre como un pasillo más de backrooms;
## la primera calavera lo rompe. Tras cada respiro la mente vuelve a poner la oficina —se camina
## sobre "alfombra" que salpica— y un apagón la retira cuando llega el cazador. Entre medias,
## recaídas de medio segundo. En persecución no hay consuelo: todo es real.
const REALITY_BEATS: Array[Dictionary] = [
	{"z": 36.0, "to": 1.0, "how": "flicker"},
	{"z": 96.0, "to": 0.0, "how": "blackout"},
	{"z": 150.0, "to": 1.0, "how": "blackout"},
	{"z": 246.0, "to": 0.0, "how": "flicker"},
	{"z": 284.0, "to": 1.0, "how": "blackout"},
]


func _update_reality(delta: float) -> void:
	if drained:
		return
	var z: float = player.global_position.z
	while _reality_step < REALITY_BEATS.size() and z >= float(REALITY_BEATS[_reality_step]["z"]):
		var beat: Dictionary = REALITY_BEATS[_reality_step]
		_reality_step += 1
		if _reality_step < REALITY_BEATS.size() and z >= float(REALITY_BEATS[_reality_step]["z"]):
			continue
		if beat["how"] == "blackout":
			blackout_reality(beat["to"])
		else:
			flicker_reality(beat["to"])
	if entity != null and entity.current_state() in [&"Chase", &"Attack"]:
		if reality < 0.5:
			flicker_reality(1.0, 0.5)
		return
	_glimpse_in -= delta
	if _glimpse_in <= 0.0 and _reality_step > 0 and not hud.is_reading:
		_glimpse_in = randf_range(22.0, 48.0)
		glimpse_reality(1.0 - roundf(reality), randf_range(0.25, 0.7))


## Agua: una malla a ras de 0,14 m sobre las celdas inundadas. Como no pasa por el horneado, su
## "reflejo" se calcula aquí por vértice con las mismas luces que horneó el constructor.
func _build_water() -> void:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/water_surface.gdshader") as Shader
	material.set_shader_parameter("petals_tex", load("res://assets/textures/water_marigold.png"))
	material.set_shader_parameter("carpet_tex", load("res://assets/textures/backrooms_carpet.png"))
	var lights: Array = geo.get_meta("lights", [])
	var size: float = geo.get_meta("cell_size")
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cell: Vector2i in zone_cells("water"):
		var corners: Array[Vector3] = []
		for offset: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
			corners.append(Vector3((cell.x + offset.x) * size, 0.0, (cell.y + offset.y) * size))
		for index: int in [0, 1, 2, 0, 2, 3]:
			tool.set_color(_water_light(corners[index], lights))
			tool.set_normal(Vector3.UP)
			tool.add_vertex(corners[index])
	var surface: MeshInstance3D = MeshInstance3D.new()
	surface.name = "Agua"
	surface.mesh = tool.commit()
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)
	surface.global_position = geo.global_position + Vector3(0.0, WATER_LEVEL, 0.0)
	_water = surface


## Luz que llega a un punto del agua (sin oclusión: el túnel ya separa unas luces de otras).
func _water_light(at: Vector3, lights: Array) -> Color:
	var total: Color = Color(0, 0, 0, 0)
	for light: Dictionary in lights:
		var position_light: Vector3 = light["pos"]
		var radius: float = light["radius"]
		var distance: float = position_light.distance_to(at)
		if distance >= radius:
			continue
		var falloff: float = 1.0 - distance / radius
		# Los tubos de backrooms van aparte, en alfa, como en el horneado.
		if bool(light.get("flicker", false)):
			total.a += float(light["energy"]) * falloff * falloff
		else:
			var colour: Color = (light["color"] as Color) * float(light["energy"]) * falloff * falloff
			total += Color(colour.r, colour.g, colour.b, 0.0)
	return total


## Carga opcional de modelos ajenos, sin preload ni sustitutos primitivos.
func _optional_model(model: String, parent: Node3D) -> Node3D:
	if not ResourceLoader.exists("res://assets/models/%s.glb" % model):
		push_warning("Modelo pendiente: " + model)
		return Node3D.new()
	return spawn_model(model, parent, 0.05, 0.9)


func _build_wall() -> void:
	_wall = Node3D.new()
	add_child(_wall)
	_wall.position = marker("wall") + Vector3(0.0, 1.35, 0.0)
	_wall.rotation.y = PI
	_optional_model("clay_wall_panel", _wall)
	_broken = Node3D.new()
	add_child(_broken)
	_broken.position = marker("wall") + Vector3(0.0, 1.35, 0.0)
	_broken.rotation.y = PI
	_optional_model("clay_wall_broken", _broken)
	_broken.hide()
	var body: StaticBody3D = StaticBody3D.new()
	_wall.add_child(body)
	_wall_collision = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(2, 2.7, 0.3)
	_wall_collision.shape = shape
	body.add_child(_wall_collision)


func _on_checkpoint(id: String) -> void:
	if id == "r1" or id == "r2":
		_segment = 1 if id == "r1" else 2
		chase_count = 0
		_budget_spent = false
		_budget_relocated = false
		entity.profile.chase_enabled = true
		entity.profile.attack_enabled = true
		entity.profile.stagnation_ambush = true


func _on_state_changed(state: StringName) -> void:
	if state == &"Chase" and _last_state != &"Chase":
		if chase_count >= Game.difficulty.level3_chases_per_segment:
			entity.force_state.call_deferred(&"Wander")
		else:
			chase_count += 1
			_budget_spent = chase_count >= Game.difficulty.level3_chases_per_segment
	if _last_state == &"Chase" and state == &"Wander" and in_zone(player.global_position, "duct"):
		Game.caption("[respiración — en la boca del conducto]")
	_last_state = state


func _on_noise(radius: float, at: Vector3) -> void:
	if not hunter_started or drained or not player.in_water or not player.is_sprinting:
		return
	Game.caption("[salpicadura — fuerte]")
	if not _budget_spent and entity.global_position.distance_to(at) <= radius:
		entity.add_stimulus(Game.difficulty.threshold_chase * Game.chase_threshold_factor(), at)
		entity.force_state(&"Chase")


func _relocate_hunter() -> void:
	var candidate: Vector3 = marker("ambush_0")
	for i: int in 3:
		var at: Vector3 = marker("ambush_%d" % i)
		if at.distance_to(player.global_position) >= Game.difficulty.respawn_distance and not player.camera.is_position_in_frustum(at + Vector3.UP):
			candidate = at
			break
	entity.teleport_to(candidate)


func _update_loop() -> void:
	var at: Vector3 = player.global_position
	if at.distance_to(marker("loop_a")) < 2.0:
		_loop_armed = true
	var crossed: bool = _last_position.z < marker("loop_b").z and at.z >= marker("loop_b").z and at.distance_to(_last_position) < 1.0
	if _loop_armed and crossed and absf(at.x - marker("loop_b").x) < 1.6 and loop_count < 2:
		loop_count += 1
		player.global_position += marker("loop_a") - marker("loop_b")
	_last_position = player.global_position


func _take_letter() -> void:
	entity.vanish()
	play_letter_ritual(altar, _open_wall, _ritual_done)


func _open_wall() -> void:
	set_reality(1.0)
	_sound("clay_crack")
	_wall.hide()
	_broken.show()
	_wall_collision.set_deferred("disabled", true)
	_sound("water_drain")
	Game.caption("[el agua se vacía]")
	player.in_water = false
	drained = true
	var tween: Tween = create_tween()
	tween.tween_property(_water, "position:y", -0.3, 2.6)
	tween.tween_callback(_water.hide)


func _ritual_done() -> void:
	player.in_water = false


func _sound(id: String) -> void:
	var stream: AudioStream = load_audio("res://assets/audio/sfx/%s.ogg" % id)
	if stream != null:
		play_sound(stream, -4.0)


func _show_refuge_hint() -> void:
	# Busca por celdas transitables: los pétalos nunca atraviesan una pared.
	var start: Vector2i = cell_of(player.global_position)
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary[Vector2i, Vector2i] = {start: start}
	var rows: PackedStringArray = geo.get_meta("rows")
	var target: Vector2i = start
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		if cell in zone_cells("duct"):
			target = cell
			break
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if previous.has(next) or next.y < 0 or next.y >= rows.size() or next.x < 0 or next.x >= rows[next.y].length():
				continue
			if rows[next.y][next.x] in ["#", "b"]:
				continue
			previous[next] = cell
			queue.append(next)
	var route: Array[Vector2i] = [target]
	while target != start:
		target = previous[target]
		route.push_front(target)
	for i: int in range(1, route.size()):
		var from: Vector3 = cell_center(route[i - 1])
		var to: Vector3 = cell_center(route[i])
		for step: int in 3:
			_hint.append(add_petals(from.lerp(to, (step + 1) / 3.0), 0.35))
	if not _hint.is_empty():
		var material: Material = _hint[0].material_override
		for petals: MeshInstance3D in _hint:
			petals.material_override = material
	get_tree().create_timer(10.0).timeout.connect(func() -> void:
		for petals: MeshInstance3D in _hint:
			petals.hide())


## La carta mojada de D10: una hoja (superficie plana) sobre el escritorio hundido.
func _add_paper(document: DocumentPickup) -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.22, 0.3)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.62, 0.58, 0.44)
	material.emission_enabled = true
	material.emission = Color(0.62, 0.58, 0.44)
	material.emission_energy_multiplier = 0.25
	var paper: MeshInstance3D = MeshInstance3D.new()
	paper.mesh = quad
	paper.material_override = material
	paper.rotation = Vector3(-PI * 0.5, 0.4, 0.0)
	document.add_child(paper)
