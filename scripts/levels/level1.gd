extends LevelBase
## Nivel 1 — "El Laberinto de Papel Tapiz" (docs/04, docs/12 §8.1).
## Paranoia aprendida: la amenaza es solo audio (pasos espejo). Aquí no se puede morir.

const HUM: AudioStream = preload("res://assets/audio/ambient/fluorescent_hum_loop.ogg")
const CANDLES: AudioStream = preload("res://assets/audio/ambient/candles_loop.ogg")
const SWELL: AudioStream = preload("res://assets/audio/sfx/letter_swell.ogg")
const KNOCK: AudioStream = preload("res://assets/audio/sfx/distant_knock.wav")
const PETALS_TEXTURE: Texture2D = preload("res://assets/textures/petals.png")
const FAR_STEPS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/footstep_far_01.wav"),
	preload("res://assets/audio/sfx/footstep_far_02.wav"),
	preload("res://assets/audio/sfx/footstep_far_03.wav"),
	preload("res://assets/audio/sfx/footstep_far_04.wav"),
	preload("res://assets/audio/sfx/footstep_far_05.wav"),
	preload("res://assets/audio/sfx/footstep_far_06.wav"),
]

const HUM_DB: float = -11.0
const MIRROR_TRIGGER_RADIUS: float = 4.5
## El pasillo en bucle devuelve al jugador tres celdas atrás, hasta tres veces (docs/07).
const LOOP_SHIFT: float = 6.0
const LOOP_REPEATS: int = 3
const NEON: Color = Color(1.0, 0.36, 0.72)

var _mirror: MirrorSteps = null
var _mirror_points: Array[Vector3] = []
var _letter: Node3D = null
var _letter_spot: Interactable = null
var _letter_base_y: float = 0.0
var _letter_taken: bool = false
var _hold_ratio: float = 0.0
var _hum: AudioStreamPlayer = null
var _candles: AudioStreamPlayer3D = null
var _contamination: Array[MeshInstance3D] = []
var _loop_trigger: Vector3 = Vector3.ZERO
var _loop_count: int = 0
var _last_z: float = 0.0
var _knocked: bool = false
var _time: float = 0.0


func _ready() -> void:
	super()
	player.global_position = marker("start")
	# Aterriza mirando la alfombra (docs/14 §7): levantar la vista es el primer gesto.
	player.set_view(-PI * 0.5, -1.1)
	player.sprint_enabled = true
	player.flashlight.available = false
	set_touch_button(&"sprint_visible", true)
	set_touch_button(&"flashlight_visible", false)
	player.controls_enabled = false
	get_tree().create_timer(1.6).timeout.connect(func() -> void: player.controls_enabled = true)

	_hum = add_loop(HUM, HUM_DB)
	_build_flashlight_pickup()
	_build_documents()
	build_signs({"recepcion": "RECEPCIÓN", "hrecepcion": "RECEPCIÓN"}, Color(0.17, 0.12, 0.05))
	_build_petals()
	_build_letter()
	_build_mirror_steps()
	_loop_trigger = marker("loop_trigger")
	_last_z = player.global_position.z
	player.interactor.hold_progress_changed.connect(_on_hold_progress_changed)


func _process(delta: float) -> void:
	_time += delta
	if _letter_taken:
		return
	_update_letter()
	_update_mirror_triggers()
	_update_loop()


func _build_flashlight_pickup() -> void:
	var at: Vector3 = marker("flashlight")
	# La linterna "brilla sola" en la recepción: tutorial diegético (docs/13 §12).
	var body: Node3D = Node3D.new()
	var spot: Interactable = add_interactable(at, 2.2)
	spot.add_child(body)
	spawn_model("flashlight", body, 0.5, 3.0)
	body.rotation_degrees.y = 25.0
	spot.interacted.connect(func() -> void:
		spot.enabled = false
		spot.queue_free()
		player.flashlight.available = true
		player.flashlight.turn(true)
		set_touch_button(&"flashlight_visible", true)
		if not is_touch():
			hud.show_hint("F — linterna · Shift — correr", 5.0))


func _build_documents() -> void:
	add_document(marker("d04"), "res://resources/documents/d04.tres", 2.2)
	add_document(marker("d05"), "res://resources/documents/d05.tres", 2.2)
	var scratch_spot: DocumentPickup = add_document(marker("d06"), "res://resources/documents/d06.tres", 2.4)
	var scratch: Label3D = Label3D.new()
	scratch.text = "NO LOS JUNTES"
	scratch.font_size = 44
	scratch.pixel_size = 0.004
	scratch.modulate = Color(0.16, 0.12, 0.05, 0.85)
	scratch.outline_size = 0
	scratch.shaded = true
	scratch.rotation = Vector3(0.0, PI, deg_to_rad(-3.0))
	scratch_spot.add_child(scratch)


## Polvo naranja en los rincones (docs/04). Tras la letra aparece mucho más: contaminación 5 %.
func _build_petals() -> void:
	var index: int = 0
	while has_marker("petals_%d" % index):
		var at: Vector3 = marker("petals_%d" % index)
		_add_petals(at + _corner_offset(at) * 0.55, 1.1 + 0.35 * (index % 3), false)
		_add_petals(at - _corner_offset(at) * 0.2, 1.9, true)
		index += 1
	var altar: Vector3 = marker("altar")
	for i: int in 14:
		var angle: float = TAU * i / 14.0
		_add_petals(altar + Vector3(cos(angle) * 4.6, 0.0, sin(angle) * 2.9), 2.2, true)


func _add_petals(at: Vector3, size: float, contamination: bool) -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(size, size)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = PETALS_TEXTURE
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission_texture = PETALS_TEXTURE
	material.emission_energy_multiplier = 0.22
	material.roughness = 1.0
	var petals: MeshInstance3D = MeshInstance3D.new()
	petals.mesh = quad
	petals.material_override = material
	petals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(petals)
	petals.global_position = at + Vector3(0.0, 0.012 + 0.002 * _contamination.size(), 0.0)
	petals.rotation = Vector3(-PI * 0.5, fmod(at.x * 12.9898 + at.z * 78.233, TAU), 0.0)
	if contamination:
		petals.hide()
		_contamination.append(petals)


## Dirección hacia la esquina de la celda que tiene muro en ambos lados.
func _corner_offset(at: Vector3) -> Vector3:
	var rows: PackedStringArray = geo.get_meta("rows")
	var size: float = geo.get_meta("cell_size")
	var column: int = floori(at.x / size)
	var row: int = floori(at.z / size)
	for direction: Vector2i in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		if _is_wall(rows, column + direction.x, row) and _is_wall(rows, column, row + direction.y):
			return Vector3(direction.x, 0.0, direction.y)
	return Vector3(1.0, 0.0, 1.0)


func _is_wall(rows: PackedStringArray, column: int, row: int) -> bool:
	if row < 0 or row >= rows.size() or column < 0 or column >= rows[row].length():
		return true
	return rows[row][column] == "#"


## La N: tres barras de neón flotando sobre el mostrador de veladoras.
func _build_letter() -> void:
	var at: Vector3 = marker("letter")
	_letter_base_y = at.y
	_letter = Node3D.new()
	add_child(_letter)
	_letter.global_position = at
	# Letra de neón modelada (`letter_n.glb`); el frente mira al norte, hacia la entrada.
	var model: Node3D = spawn_model("letter_n", _letter, 2.6, 2.6)
	model.rotation.y = PI
	_tint_letter(model)
	var halo_material: StandardMaterial3D = StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_material.albedo_color = Color(NEON.r, NEON.g, NEON.b, 0.3)
	var falloff: Gradient = Gradient.new()
	falloff.set_color(0, Color.WHITE)
	falloff.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var falloff_texture: GradientTexture2D = GradientTexture2D.new()
	falloff_texture.gradient = falloff
	falloff_texture.fill = GradientTexture2D.FILL_RADIAL
	falloff_texture.fill_from = Vector2(0.5, 0.5)
	falloff_texture.fill_to = Vector2(1.0, 0.5)
	halo_material.albedo_texture = falloff_texture
	halo_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	# Halo: no es un objeto, es el resplandor del neón (un disco aditivo que mira a cámara).
	var halo_mesh: QuadMesh = QuadMesh.new()
	halo_mesh.size = Vector2(1.5, 1.5)
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.mesh = halo_mesh
	halo.material_override = halo_material
	_letter.add_child(halo)

	_letter_spot = add_interactable(at, 2.6, 1.5)
	_letter_spot.interacted.connect(_take_letter)

	_candles = AudioStreamPlayer3D.new()
	_candles.stream = CANDLES
	_candles.volume_db = -4.0
	_candles.unit_size = 3.0
	_candles.max_distance = 16.0
	add_child(_candles)
	_candles.global_position = at
	_candles.play()


func _tint_letter(model: Node3D) -> void:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		for surface: int in mesh_instance.mesh.get_surface_count():
			var material: StandardMaterial3D = mesh_instance.get_surface_override_material(surface) as StandardMaterial3D
			if material != null:
				material.emission = Color(1.0, 0.8, 0.9)


func _build_mirror_steps() -> void:
	_mirror = MirrorSteps.new()
	var voice: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	voice.name = "Voice"
	voice.unit_size = 7.0
	voice.max_distance = 40.0
	_mirror.add_child(voice)
	_mirror.step_sounds = FAR_STEPS
	add_child(_mirror)
	_mirror.setup(player)
	var index: int = 0
	while has_marker("mirror_%d" % index):
		_mirror_points.append(marker("mirror_%d" % index))
		index += 1


func _update_letter() -> void:
	_letter.position.y = _letter_base_y + sin(_time * 1.3) * 0.035
	_letter.rotation.y = sin(_time * 0.5) * 0.35
	var grow: float = 1.0 + _hold_ratio * 0.25
	_letter.scale = Vector3(grow, grow, grow)
	screen_fx.aberration = _hold_ratio * 0.35


func _update_mirror_triggers() -> void:
	if _mirror.active or not player.flashlight.available:
		return
	for i: int in _mirror_points.size():
		if player.global_position.distance_to(_mirror_points[i]) < MIRROR_TRIGGER_RADIUS:
			_mirror_points.remove_at(i)
			_mirror.start_event()
			if not _knocked and _mirror_points.size() <= 2:
				_knocked = true
				get_tree().create_timer(13.0).timeout.connect(func() -> void: play_sound(KNOCK, -2.0))
			return


## Pasillo que no termina: al cruzar el disparador hacia el norte, tres celdas atrás.
func _update_loop() -> void:
	var position_now: Vector3 = player.global_position
	var in_corridor: bool = absf(position_now.x - _loop_trigger.x) < 1.0
	var crossed: bool = _last_z >= _loop_trigger.z and position_now.z < _loop_trigger.z and _last_z - position_now.z < 1.0
	if in_corridor and _loop_count < LOOP_REPEATS and crossed:
		_loop_count += 1
		player.global_position.z += LOOP_SHIFT
	_last_z = player.global_position.z


func _on_hold_progress_changed(ratio: float) -> void:
	if player.interactor.focus == _letter_spot or ratio == 0.0:
		_hold_ratio = ratio


## Recoger la N es la transición (docs/12 §9): veladoras, perturbación y más contaminación.
func _take_letter() -> void:
	_letter_taken = true
	_letter_spot.enabled = false
	_mirror.active = false
	set_can_pause(false)
	player.controls_enabled = false
	play_sound(SWELL, -1.0)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_letter, "scale", Vector3.ZERO, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(screen_fx, "aberration", 1.0, 1.2)
	tween.tween_property(_hum, "volume_db", -60.0, 2.5)
	tween.tween_method(_shake, 1.0, 0.0, 1.4).set_delay(0.9)
	tween.tween_method(_set_world_light, 1.0, 0.25, 0.25).set_delay(1.2)
	tween.tween_callback(_reveal_contamination).set_delay(1.3)
	tween.tween_method(_set_world_light, 0.25, 0.8, 1.6).set_delay(1.6)
	tween.tween_property(screen_fx, "aberration", 0.15, 1.5).set_delay(1.4)
	tween.chain().tween_callback(func() -> void: player.controls_enabled = true)
	tween.chain().tween_interval(6.0)
	tween.chain().tween_callback(func() -> void: screen_fx.fade_color = Color.BLACK)
	tween.chain().tween_property(screen_fx, "fade", 1.0, 2.0)
	tween.chain().tween_callback(_finish)


func _reveal_contamination() -> void:
	for petals: MeshInstance3D in _contamination:
		petals.show()


func _set_world_light(value: float) -> void:
	RenderingServer.global_shader_parameter_set(&"world_light", value)


## Uno de los tres temblores de toda la partida (docs/13 §7).
func _shake(strength: float) -> void:
	if Game.reduced_camera_motion:
		return
	player.camera.h_offset = randf_range(-1.0, 1.0) * 0.05 * strength
	player.camera.v_offset = randf_range(-1.0, 1.0) * 0.05 * strength


func _finish() -> void:
	player.set_cutscene(true)
	_candles.stop()
	hud.show_end_card("N", "Has recuperado la primera letra.\nAlgo se acuerda de ti.\n\nContinuará — Nivel 2: Las Ofrendas Infinitas")
