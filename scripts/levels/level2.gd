extends LevelBase
## Nivel 2 — "Las Ofrendas Infinitas" (docs/04, docs/12 §8.2). Contaminación 35 %, doble realidad.
## Misión: encender la veladora mayor de las tres ofrendas despierta la pirámide de archiveros y
## hace aparecer la letra O. Amenaza: la primera manifestación de El Olvidado; iluminarlo de
## lleno lo hace chillar y reaparecer más cerca (docs/12 §6).

signal offering_lit(index: int)
signal pyramid_awake

const WARM: Color = Color(1.0, 0.55, 0.18)
const OFFERINGS: int = 3
## Segundos de "realidad" tras encender cada ofrenda antes de que la mente vuelva a tapar la nave.
const REAL_SECONDS: float = 26.0
const MANIFEST_SECONDS: float = 25.0
const LETTER_SIZE: float = 2.6

var altar: LetterAltar = null
var lit_count: int = 0
var manifestations: int = 0

var _lit: Array[bool] = [false, false, false]
var _flames: Array[Node3D] = []
var _spots: Array[Interactable] = []
var _trails: Array[Array] = []
var _pyramid_candles: Array[Node3D] = []
var _relapse_in: float = -1.0
var _manifest_left: float = 0.0
var _random_pending: bool = false
var _random_in: float = 0.0
var _taken: bool = false
var _finishing: bool = false


func _ready() -> void:
	super()
	player.flashlight.available = true
	player.flashlight.turn(true)
	player.sprint_enabled = true
	player.camera.far = 120.0
	set_touch_button(&"flashlight_visible", true)
	set_touch_button(&"sprint_visible", true)
	# Niebla cerrada (tipo Silent Hill): la nave no se abarca de un vistazo.
	fog_real_color = Color(0.13, 0.115, 0.1)
	fog_real_density = 0.12
	add_mist(Color(0.13, 0.115, 0.1), 0.55, 22, 14.0)
	set_reality(0.0)

	_build_documents()
	_build_painted_signs()
	_build_offerings()
	_build_pyramid()
	_build_audio()
	spawn_entity("res://resources/entity/profile_level2.tres")
	entity.screeched.connect(func() -> void: Game.caption("[chillido de estática]"))

	var saved: String = spawn_at_checkpoint("start", -PI * 0.5)
	# El estado del nivel se reconstruye según el checkpoint: lo encendido sigue encendido.
	var restored: int = {"r1": 1, "r2": OFFERINGS}.get(saved, 0)
	for index: int in restored:
		_light_offering(index, true)
	if restored == 0:
		hud.show_line("Otra vez la oficina. ¿O es lo que yo quiero ver?", 4.0)


func _process(delta: float) -> void:
	super(delta)
	if altar != null:
		update_letter_fx(altar)
	_update_reality(delta)
	_update_manifestation(delta)
	for index: int in _flames.size():
		# Las veladoras mayores aún apagadas laten apenas: se dejan encontrar.
		if not _lit[index]:
			_set_flame(_flames[index], 0.25 + 0.2 * sin(Time.get_ticks_msec() * 0.003 + index))


# --- Construcción --------------------------------------------------------------------------

func _build_documents() -> void:
	for id: String in ["d07", "d08", "d09"]:
		add_document(marker(id), "res://resources/documents/%s.tres" % id, 2.4)


## Rótulos de plantilla pintados en las columnas: la oficina que esto fue sigue dando órdenes.
func _build_painted_signs() -> void:
	var texts: Array[String] = ["LOS ARCHIVOS\nNUNCA\nMUEREN", "AQUÍ\nTAMBIÉN\nSIGUES", "TODO\nEXPEDIENTE\nVUELVE", "NADIE\nSE VA\nDEL TODO"]
	for index: int in texts.size():
		var at: Vector3 = marker("paint_%d" % index)
		var facing: Vector3 = marker("paint_%d_n" % index) - at
		var label: Label3D = Label3D.new()
		label.text = texts[index]
		label.font = SIGN_FONT
		label.font_size = 120
		label.pixel_size = 0.0021
		label.line_spacing = -18.0
		label.outline_size = 0
		label.modulate = Color(0.05, 0.045, 0.04, 0.82)
		add_child(label)
		label.global_position = at
		label.rotation.y = atan2(facing.x, facing.z)


func _build_offerings() -> void:
	for index: int in OFFERINGS:
		var at: Vector3 = marker("offering_%d" % index)
		var holder: Node3D = Node3D.new()
		add_child(holder)
		holder.global_position = at
		var flame: Node3D = spawn_model("candle_tall", holder, 0.25, 0.3)
		flame.scale = Vector3.ONE * 3.2
		_flames.append(flame)
		var spot: Interactable = add_interactable(at + Vector3(0.0, 0.75, 0.0), 2.6, 1.2)
		spot.interacted.connect(_light_offering.bind(index))
		_spots.append(spot)
		# Reguero de pétalos hacia el siguiente objetivo; aparece al encender esta ofrenda.
		var target: Vector3 = marker("offering_%d_front" % (index + 1)) if index + 1 < OFFERINGS else marker("pyramid")
		var from: Vector3 = marker("offering_%d_front" % index)
		var trail: Array = []
		var steps: int = int(from.distance_to(target) / 2.4)
		for step: int in range(1, steps):
			var point: Vector3 = from.lerp(target, float(step) / steps) + Vector3(sin(step * 1.7) * 0.5, 0.0, cos(step * 2.3) * 0.5)
			trail.append(add_petals(point, 0.7 + 0.25 * (step % 3), true))
		_trails.append(trail)


func _build_pyramid() -> void:
	var centre: Vector3 = marker("pyramid")
	# Veladoras de la cúspide: apagadas hasta que arden las tres ofrendas.
	for i: int in 8:
		var angle: float = i * TAU / 8.0
		var holder: Node3D = Node3D.new()
		add_child(holder)
		holder.global_position = centre + Vector3(cos(angle) * 0.75, 2.64 + 1.32 * float(i % 2 == 0) * 0.0, sin(angle) * 0.75)
		var candle: Node3D = spawn_model("candle_tall", holder, 0.1, 0.02)
		candle.scale = Vector3.ONE * 1.8
		_pyramid_candles.append(candle)


func _build_audio() -> void:
	var hall: AudioStream = load_audio("res://assets/audio/ambient/level2_hall_loop.ogg")
	if hall != null:
		add_loop(hall, -13.0)
	var copal: AudioStream = load_audio("res://assets/audio/ambient/copal_crackle_loop.ogg")
	if copal != null:
		for index: int in OFFERINGS:
			play_sound_at(copal, marker("offering_%d" % index), -9.0, 14.0)


# --- Misión --------------------------------------------------------------------------------

## Encender una ofrenda: la nave se muestra como es durante un rato, y la entidad se deja ver.
func _light_offering(index: int, restoring: bool = false) -> void:
	if _lit[index]:
		return
	_lit[index] = true
	lit_count += 1
	_spots[index].enabled = false
	_set_flame(_flames[index], 3.2)
	for petals: MeshInstance3D in _trails[index]:
		petals.show()
	if restoring:
		if lit_count == OFFERINGS:
			_wake_pyramid(true)
		return
	var ignite: AudioStream = load_audio("res://assets/audio/sfx/letter_ignite.ogg")
	if ignite != null:
		play_sound_at(ignite, _flames[index].global_position, -3.0, 20.0)
	Game.caption("[la veladora prende]")
	flicker_reality(1.0)
	offering_lit.emit(index)
	if lit_count == OFFERINGS:
		Game.set_checkpoint("r2")
		_wake_pyramid(false)
		return
	_relapse_in = REAL_SECONDS
	if lit_count == 1:
		Game.set_checkpoint("r1")
		# Primera manifestación, guionizada: lejos y de perfil, para aprender a apartar la luz.
		get_tree().create_timer(5.0).timeout.connect(_manifest.bind(_far_marker()))
	else:
		_random_pending = true
		_random_in = randf_range(10.0, 20.0)


func _wake_pyramid(restoring: bool) -> void:
	for i: int in _pyramid_candles.size():
		create_tween().tween_callback(_set_flame.bind(_pyramid_candles[i], 3.0)).set_delay(0.0 if restoring else 1.0 + i * 0.18)
	altar = add_letter("letter_o", "letter", 0.0, 6.2)
	altar.taken.connect(_take_letter)
	altar.size = LETTER_SIZE
	altar.set_neon(Color(1.0, 0.34, 0.26), 1.5)
	if not restoring:
		altar.size = 0.0
		create_tween().tween_property(altar, "size", LETTER_SIZE, 1.6).set_delay(2.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		hud.show_line("Ahí está. Arriba de todo.", 3.5)
	pyramid_awake.emit()


func _take_letter() -> void:
	_taken = true
	entity.vanish()
	play_letter_ritual(altar, _collapse, _after_ritual)


## Punto ciego del ritual: la ofrenda se viene abajo y la entidad se deja ver un instante.
func _collapse() -> void:
	var crash: AudioStream = load_audio("res://assets/audio/sfx/ofrenda_collapse.ogg")
	if crash != null:
		play_sound(crash, -2.0)
	Game.caption("[los archiveros se vienen abajo]")
	for candle: Node3D in _pyramid_candles:
		_set_flame(candle, 0.02)
	var centre: Vector3 = marker("pyramid")
	for i: int in 26:
		var angle: float = i * TAU / 26.0
		add_petals(centre + Vector3(cos(angle), 0.0, sin(angle)) * (4.5 + 2.0 * (i % 3)), 2.0)
	if manifestations < Game.difficulty.level2_manifestations:
		_manifest(_far_marker())


func _after_ritual() -> void:
	flicker_reality(1.0, 0.6)
	await get_tree().create_timer(5.0).timeout
	if not _finishing:
		_finishing = true
		entity.vanish()
		finish_level()


# --- Entidad -------------------------------------------------------------------------------

## Marcador de aparición lejano (16–30 m) y fuera del encuadre.
func _far_marker() -> Vector3:
	var best: Vector3 = marker("manifest_0")
	var best_score: float = -INF
	var index: int = 0
	while has_marker("manifest_%d" % index):
		var at: Vector3 = marker("manifest_%d" % index)
		var distance: float = at.distance_to(player.global_position)
		var score: float = -absf(distance - 20.0) - (30.0 if player.camera.is_position_in_frustum(at + Vector3.UP) else 0.0) - (40.0 if distance < 14.0 else 0.0)
		if score > best_score:
			best_score = score
			best = at
		index += 1
	return best


func _manifest(at: Vector3) -> void:
	if _finishing or hud.is_reading or manifestations >= Game.difficulty.level2_manifestations:
		return
	manifestations += 1
	_manifest_left = MANIFEST_SECONDS
	entity.manifest_at(at, false)
	# De perfil: mira perpendicular a la línea con el jugador.
	var to_player: Vector3 = player.global_position - at
	entity.rotation.y = atan2(to_player.x, to_player.z) + PI * 0.5
	entity.force_state(&"Wander")
	Game.caption("[huesos secos — lejos]")


func _update_manifestation(delta: float) -> void:
	if _random_pending and not hud.is_reading and _manifest_left <= 0.0:
		_random_in -= delta
		if _random_in <= 0.0:
			_random_pending = false
			_manifest(_far_marker())
	if _manifest_left > 0.0:
		_manifest_left -= delta
		var away: bool = entity.global_position.distance_to(player.global_position) > 34.0
		if (_manifest_left <= 0.0 or away) and entity.current_state() != &"Attack":
			_manifest_left = 0.0
			if not player.camera.is_position_in_frustum(entity.global_position + Vector3.UP * 1.3):
				entity.vanish()
			else:
				_manifest_left = 2.0


# --- Doble realidad ------------------------------------------------------------------------

func _update_reality(delta: float) -> void:
	if _relapse_in > 0.0 and lit_count < OFFERINGS:
		_relapse_in -= delta
		# La mente no vuelve a tapar la nave mientras la entidad está a la vista.
		if _relapse_in <= 0.0:
			if _manifest_left > 0.0:
				_relapse_in = 3.0
			else:
				blackout_reality(0.0)
				hud.show_line("…la oficina. Solo es la oficina.", 3.0)


## Brillo de la llama (y del cuerpo de cera) de una veladora dinámica.
func _set_flame(root: Node3D, energy: float) -> void:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		for surface: int in instance.mesh.get_surface_count():
			var source: Material = instance.mesh.surface_get_material(surface)
			var material: StandardMaterial3D = instance.get_surface_override_material(surface) as StandardMaterial3D
			if material == null or source == null:
				continue
			if source.resource_name == "Flame":
				material.emission = WARM
				material.emission_energy_multiplier = energy
