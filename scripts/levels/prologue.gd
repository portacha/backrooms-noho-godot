extends LevelBase
## Prólogo — "La Oficina de la Realidad" (docs/14). Sin amenaza, sin linterna, sin sprint.

const HUM: AudioStream = preload("res://assets/audio/ambient/office_hum_loop.ogg")
const TONE: AudioStream = preload("res://assets/audio/ambient/painting_tone_loop.ogg")
const FALL: AudioStream = preload("res://assets/audio/sfx/fall.ogg")
const MONITOR_OFF: AudioStream = preload("res://assets/audio/sfx/monitor_off.wav")
const LOCKED_DOOR: AudioStream = preload("res://assets/audio/sfx/distant_knock.wav")
const FAN: AudioStream = preload("res://assets/audio/ambient/computer_fan_loop.ogg")
const LIGHT_FLICKER: AudioStream = preload("res://assets/audio/sfx/light_flicker.wav")
const POSTERS: Texture2D = preload("res://assets/textures/office_posters.png")
const PAINTING_SHADER: Shader = preload("res://shaders/painting.gdshader")
const PAINTING_TEXTURE: Texture2D = preload("res://assets/textures/painting_a.png")
const SCREEN_TEXTURE: Texture2D = preload("res://assets/textures/screen_lock.png")

const HUM_DB: float = -8.0
const HUM_BOARDROOM_DB: float = -20.0
const SILENT_DB: float = -60.0
const TONE_MAX_DB: float = -9.0
const PAINTING_SIZE: Vector2 = Vector2(2.4, 1.8)
const PAINTING_ENERGY: float = 1.15
const PAINTING_HOLD_ENERGY: float = 2.2
## Mirar el cuadro de cerca basta: a los 3 s empieza la transición y, si se sostiene la mirada
## 1,5 s más, la caída. Apartar la vista lo corta todo (docs/14 §6.2).
const GAZE_RANGE: float = 3.2
const GAZE_TIME: float = 3.0
const TRANSITION_TIME: float = 1.5
const GAZE_CUT_TIME: float = 0.4
const FALL_DB: float = -2.0
## Ventiladores de los terminales: apenas audibles, solo cerca de un equipo.
const FAN_DB: float = -24.0
const FAN_NEAR: float = 2.0
const FAN_FAR: float = 7.0
const POSTER_SIZE: Vector2 = Vector2(0.42, 0.54)
const POSTER_GRID: Vector2i = Vector2i(3, 2)
const BRAND_BLUE: Color = Color("1f5fff")
const LIGHTS_LINE: String = "Estas luces… ¿algún día las arreglarán?"
## Fallo de los tubos del pasillo: pares (duración en s, nivel de luz), al compás de `light_flicker.wav`.
const FLICKER_STEPS: PackedVector2Array = [
	Vector2(0.05, 1.0), Vector2(0.16, 0.15), Vector2(0.09, 1.0), Vector2(0.07, 0.0), Vector2(0.11, 0.9),
	Vector2(0.30, 0.3), Vector2(0.17, 1.0), Vector2(0.06, 0.1), Vector2(0.11, 1.0), Vector2(0.22, 0.0),
	Vector2(0.16, 0.85), Vector2(0.05, 0.2), Vector2(0.17, 1.0), Vector2(0.34, 0.35),
]
const MAX_SWAPS: int = 3
const SWAP_COOLDOWN: float = 4.0
const IDLE_HINT_DELAY: float = 8.0
## Amarillo liminal: la caída termina en el primer color del Nivel 1 (docs/14 §7).
const LIMINAL_YELLOW: Color = Color(0.74, 0.64, 0.24)

var _painting: MeshInstance3D = null
var _painting_material: ShaderMaterial = null
var _hum: AudioStreamPlayer = null
var _tone: AudioStreamPlayer = null
var _fan: AudioStreamPlayer = null
var _fall_audio: AudioStreamPlayer = null
var _computers: Array[Vector3] = []
var _gaze: float = 0.0
var _hold_ratio: float = 0.0
var _transition: float = 0.0
var _base_fov: float = 75.0
var _lights_noticed: bool = false
var _detours_flickered: Dictionary[int, bool] = {}
var _junction: Vector3 = Vector3.ZERO
var _falling: bool = false
var _swaps: int = 0
var _swap_cooldown: float = 0.0
var _variant: float = 0.0
var _idle_time: float = 0.0
var _has_moved: bool = false
var _boardroom_z: float = 0.0


func _ready() -> void:
	super()
	player.global_position = marker("start")
	player.set_view(PI, -0.12)
	player.sprint_enabled = false
	player.flashlight.available = false
	set_touch_button(&"sprint_visible", false)
	set_touch_button(&"flashlight_visible", false)
	_boardroom_z = marker("boardroom_door").z
	_junction = marker("junction")
	_base_fov = player.camera.fov
	# Los tubos de los pasillos lucen fijos hasta que el guion los hace fallar.
	RenderingServer.global_shader_parameter_set(&"flicker_override", 1.0)

	_hum = add_loop(HUM, HUM_DB)
	_tone = add_loop(TONE, SILENT_DB)
	_fan = add_loop(FAN, SILENT_DB)
	for node: Node in geo.get_node("Markers").get_children():
		if node.name.begins_with("pc_"):
			_computers.append((node as Node3D).global_position)
	_build_painting()
	_build_posters()
	_build_my_screen()
	_build_documents()
	build_signs({"juntas": "SALA DE JUNTAS", "hjuntas": "SALA DE JUNTAS"}, Color(0.05, 0.1, 0.08))


func _process(delta: float) -> void:
	if _falling:
		return
	_update_idle_hint(delta)
	_update_gaze(delta)
	_update_lights()
	_update_audio(delta)
	_update_painting(delta)


func _build_painting() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = PAINTING_SIZE
	_painting_material = ShaderMaterial.new()
	_painting_material.shader = PAINTING_SHADER
	_painting_material.set_shader_parameter(&"painting_tex", PAINTING_TEXTURE)
	_painting_material.set_shader_parameter(&"energy", PAINTING_ENERGY)
	_painting_material.set_shader_parameter(&"variant", 0.0)
	_painting_material.set_shader_parameter(&"stretch", 0.0)
	_painting = MeshInstance3D.new()
	_painting.mesh = quad
	_painting.material_override = _painting_material
	add_child(_painting)
	_painting.global_position = marker("painting")


## Lienzos de los cuadros de pasillo: una sola malla y un solo material sobre el atlas.
func _build_posters() -> void:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell: Vector2 = Vector2.ONE / Vector2(POSTER_GRID)
	var index: int = 0
	while has_marker("art_%d" % index):
		var at: Vector3 = marker("art_%d" % index)
		var facing: Vector3 = (marker("art_%d_n" % index) - at).normalized()
		var half_right: Vector3 = Vector3.UP.cross(facing) * POSTER_SIZE.x * 0.5
		var half_up: Vector3 = Vector3.UP * POSTER_SIZE.y * 0.5
		var slot: int = index % (POSTER_GRID.x * POSTER_GRID.y)
		var uv: Vector2 = Vector2(slot % POSTER_GRID.x, slot / POSTER_GRID.x) * cell
		var corners: Array[Vector3] = [at - half_right + half_up, at + half_right + half_up, at + half_right - half_up, at - half_right - half_up]
		var uvs: Array[Vector2] = [uv, uv + Vector2(cell.x, 0.0), uv + cell, uv + Vector2(0.0, cell.y)]
		for corner: int in [0, 1, 2, 0, 2, 3]:
			surface.set_normal(facing)
			surface.set_uv(uvs[corner])
			surface.add_vertex(corners[corner])
		index += 1
	if index == 0:
		return
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = POSTERS
	# Bajo el aplique, el papel se ve cálido y algo por debajo del blanco de los muros.
	material.albedo_color = Color(0.8, 0.76, 0.68)
	var posters: MeshInstance3D = MeshInstance3D.new()
	posters.mesh = surface.commit()
	posters.material_override = material
	add_child(posters)


## El terminal del jugador: se bloquea por inactividad a los 3 s (docs/14 §5, beat 2).
func _build_my_screen() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.3, 0.225)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.BLACK
	material.emission_enabled = true
	material.emission = Color(0.55, 0.75, 0.95)
	material.emission_energy_multiplier = 1.4
	var screen: MeshInstance3D = MeshInstance3D.new()
	screen.mesh = quad
	screen.material_override = material
	add_child(screen)
	screen.global_position = marker("my_screen")

	var tween: Tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(func() -> void:
		play_sound(MONITOR_OFF, -4.0)
		material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		material.emission_texture = SCREEN_TEXTURE
		material.emission = Color.WHITE)
	tween.tween_property(material, "emission_energy_multiplier", 0.9, 0.5)


func _build_documents() -> void:
	add_document(marker("d01"), "res://resources/documents/d01.tres", 2.4)
	add_document(marker("d03"), "res://resources/documents/d03.tres", 2.2)
	# La nota adhesiva de M., pegada en la esquina del terminal vecino. Es papel: una lámina.
	var note_spot: DocumentPickup = add_document(marker("d02_screen") + Vector3(0.15, 0.1, 0.012), "res://resources/documents/d02.tres", 2.2)
	var note_mesh: QuadMesh = QuadMesh.new()
	note_mesh.size = Vector2(0.085, 0.085)
	var note_material: StandardMaterial3D = StandardMaterial3D.new()
	note_material.albedo_color = Color(0.95, 0.87, 0.47)
	note_material.emission_enabled = true
	note_material.emission = Color(0.95, 0.87, 0.47)
	note_material.emission_energy_multiplier = 0.75
	var note: MeshInstance3D = MeshInstance3D.new()
	note.mesh = note_mesh
	note.material_override = note_material
	note.rotation_degrees.z = -6.0
	note_spot.add_child(note)

	# Marca diegética (docs/06): la caja del lienzo y el letrero de salida, apagado.
	_add_label("NOHO", marker("crate") + Vector3(0.0, 0.25, 0.0), 0.0, 150, Color(0.2, 0.13, 0.07))
	_add_label("FRÁGIL — NO RETIRAR", marker("crate") + Vector3(0.0, -0.12, 0.0), 0.0, 44, Color(0.2, 0.13, 0.07))
	# Rótulo de la recepción, sobre la placa del muro de listones.
	_add_label("NOHO", marker("logo"), PI, 170, BRAND_BLUE)
	_add_label("SALIDA", marker("exit_door") + Vector3(0.0, 1.22, -0.03), PI, 40, Color(0.45, 0.5, 0.46))
	_build_plaque()

	var exit_spot: Interactable = add_interactable(marker("exit_door"), 1.9)
	exit_spot.interacted.connect(func() -> void: play_sound(LOCKED_DOOR, 2.0))


func _add_label(text: String, at: Vector3, yaw: float, font_size: int, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.002
	label.font = SIGN_FONT
	label.outline_size = 0
	label.modulate = color
	add_child(label)
	label.global_position = at
	label.rotation.y = yaw


## Placa junto al cuadro (D03, docs/14 §5 beat 7): el modelo `plaque` es solo marco +
## hoja en blanco; el texto lo escribe el nivel como en `build_signs`. La lectura completa
## vive en el overlay del documento; aquí el extracto corporativo que se lee a 1–2 m.
func _build_plaque() -> void:
	var ink: Color = Color(0.18, 0.13, 0.07)
	var z: float = 2.022
	_add_label("ACTA DE INSTALACIÓN", Vector3(23.4, 1.70, z), 0.0, 16, ink)
	_add_label("N.º 1142", Vector3(23.4, 1.63, z), 0.0, 18, ink)
	_add_label("PIEZA 2.4 × 1.8 m", Vector3(23.4, 1.55, z), 0.0, 14, ink)
	_add_label("NO PERDERSE - NO PRESTARSE", Vector3(23.4, 1.47, z), 0.0, 10, ink)
	_add_label("NO OLVIDARSE", Vector3(23.4, 1.43, z), 0.0, 11, ink)


func _update_idle_hint(delta: float) -> void:
	if _has_moved:
		return
	if player.velocity.length() > 0.3:
		_has_moved = true
		hud.hide_hint()
		return
	_idle_time += delta
	if _idle_time >= IDLE_HINT_DELAY and _idle_time - delta < IDLE_HINT_DELAY:
		hud.show_hint("arrastra para moverte y mirar" if is_touch() else "WASD — moverte · ratón — mirar · E — interactuar", 0.0)


func _update_audio(delta: float) -> void:
	var in_boardroom: bool = player.global_position.z < _boardroom_z
	var hum_target: float = HUM_BOARDROOM_DB if in_boardroom else HUM_DB
	# Durante el mantener, la oficina se queda en silencio (docs/14 §6.2).
	hum_target = lerpf(hum_target, SILENT_DB, _hold_ratio)
	_hum.volume_db = move_toward(_hum.volume_db, hum_target, 40.0 * delta)

	var tone_target: float = SILENT_DB
	if in_boardroom:
		var distance: float = player.camera.global_position.distance_to(_painting.global_position)
		var closeness: float = clampf(1.0 - (distance - 1.2) / 7.0, 0.0, 1.0)
		tone_target = lerpf(-34.0, TONE_MAX_DB, maxf(closeness, _hold_ratio))
	_tone.volume_db = move_toward(_tone.volume_db, tone_target, 30.0 * delta)

	var nearest: float = INF
	for computer: Vector3 in _computers:
		nearest = minf(nearest, player.camera.global_position.distance_to(computer))
	var fan_closeness: float = clampf(1.0 - (nearest - FAN_NEAR) / (FAN_FAR - FAN_NEAR), 0.0, 1.0)
	var fan_target: float = lerpf(SILENT_DB, FAN_DB, fan_closeness * (1.0 - _hold_ratio))
	_fan.volume_db = move_toward(_fan.volume_db, fan_target, 40.0 * delta)


## La mirada es el gesto: cerca del lienzo y con él en el centro de la pantalla, el tiempo corre.
func _update_gaze(delta: float) -> void:
	if player.controls_enabled and _looking_at_painting():
		_gaze += delta
	else:
		# Apartar la vista corta la transición y devuelve todo en 0,4 s.
		_gaze = move_toward(_gaze, 0.0, (GAZE_TIME + TRANSITION_TIME) * delta / GAZE_CUT_TIME)
	_hold_ratio = clampf(_gaze / GAZE_TIME, 0.0, 1.0)
	var transition: float = clampf((_gaze - GAZE_TIME) / TRANSITION_TIME, 0.0, 1.0)
	if not is_equal_approx(transition, _transition):
		_apply_transition(transition)
	if _gaze >= GAZE_TIME + TRANSITION_TIME:
		_fall()


func _looking_at_painting() -> bool:
	var origin: Vector3 = player.camera.global_position
	var center: Vector3 = _painting.global_position
	if player.global_position.z >= _boardroom_z or Vector2(center.x - origin.x, center.z - origin.z).length() > GAZE_RANGE:
		return false
	# El lienzo está en un plano de Z constante, de cara al sur.
	var forward: Vector3 = -player.camera.global_basis.z
	if forward.z > -0.01:
		return false
	var offset: Vector3 = origin + forward * ((center.z - origin.z) / forward.z) - center
	return absf(offset.x) <= PAINTING_SIZE.x * 0.5 and absf(offset.y) <= PAINTING_SIZE.y * 0.5


## Primer tiempo de la caída (docs/14 §7), todavía reversible: aberración, distorsión y FOV.
func _apply_transition(value: float) -> void:
	var rising: bool = value > _transition
	_transition = value
	var reduced: bool = Game.reduced_camera_motion
	screen_fx.aberration = value * (0.3 if reduced else 1.0)
	_painting_material.set_shader_parameter(&"stretch", value * 0.5)
	if not reduced:
		screen_fx.distortion = value * 0.75
		player.camera.fov = lerpf(_base_fov, 96.0, smoothstep(0.0, 1.0, value))
	if rising and _fall_audio == null:
		_fall_audio = play_sound(FALL, FALL_DB)
		_fall_audio.finished.connect(func() -> void: _fall_audio = null)
	elif _fall_audio != null and not rising:
		_fall_audio.volume_db = lerpf(SILENT_DB, FALL_DB, value)
		if value <= 0.0:
			_fall_audio.queue_free()
			_fall_audio = null


## Al pasar por el cruce donde la caja corta el paso, los tubos fallan y el oficinista lo comenta.
## En cada rodeo vuelven a fallar una vez, ya sin comentario.
func _update_lights() -> void:
	var offset: Vector3 = player.global_position - _junction
	if not _lights_noticed:
		if absf(offset.x) < 3.0 and absf(offset.z) < 1.2:
			_lights_noticed = true
			_flicker(FLICKER_STEPS.size(), true)
		return
	var side: int = signi(roundi(offset.x / 10.0))
	if side != 0 and offset.z < -3.0 and offset.z > -8.0 and not _detours_flickered.has(side):
		_detours_flickered[side] = true
		_flicker(6, false)


func _flicker(steps: int, with_line: bool) -> void:
	var sound: AudioStreamPlayer = play_sound(LIGHT_FLICKER, -12.0)
	var tween: Tween = create_tween()
	for i: int in steps:
		tween.tween_callback(RenderingServer.global_shader_parameter_set.bind(&"flicker_override", FLICKER_STEPS[i].y))
		tween.tween_interval(FLICKER_STEPS[i].x)
	tween.tween_callback(RenderingServer.global_shader_parameter_set.bind(&"flicker_override", 1.0))
	if with_line:
		tween.tween_callback(hud.show_line.bind(LIGHTS_LINE))
	else:
		tween.tween_callback(sound.stop)


func _update_painting(delta: float) -> void:
	var energy: float = lerpf(PAINTING_ENERGY, PAINTING_HOLD_ENERGY, _hold_ratio)
	_painting_material.set_shader_parameter(&"energy", energy)

	# "Cambia cuando lo miras de reojo": solo fuera de encuadre (docs/14 §6.1).
	_swap_cooldown = maxf(_swap_cooldown - delta, 0.0)
	var armed: bool = player.global_position.z < _boardroom_z and _swaps < MAX_SWAPS and _swap_cooldown <= 0.0
	if armed and not _painting_in_view():
		_swaps += 1
		_swap_cooldown = SWAP_COOLDOWN
		_variant = 1.0 - _variant
		_painting_material.set_shader_parameter(&"variant", _variant)
	elif _painting_in_view() and _swap_cooldown <= 0.0:
		# El contador de espera solo corre mientras se mira: un cambio por cada vez que se aparta la vista.
		_swap_cooldown = 0.01


func _painting_in_view() -> bool:
	var half: Vector3 = Vector3(PAINTING_SIZE.x * 0.5, PAINTING_SIZE.y * 0.5, 0.0)
	for corner: Vector3 in [Vector3.ZERO, half, -half, Vector3(half.x, -half.y, 0.0), Vector3(-half.x, half.y, 0.0)]:
		if player.camera.is_position_in_frustum(_painting.global_position + corner):
			return true
	return false


## La caída (docs/14 §7), ya sin vuelta atrás: a través del lienzo → amarillo liminal.
## La aberración, la distorsión y el FOV llegan al máximo en `_apply_transition`.
func _fall() -> void:
	_falling = true
	player.set_cutscene(true)
	set_can_pause(false)
	hud.hide()
	_hum.stop()
	_fan.stop()
	_painting_material.set_shader_parameter(&"energy", PAINTING_HOLD_ENERGY)

	var landing: Vector3 = Vector3(_painting.global_position.x, player.global_position.y, _painting.global_position.z + 0.3)
	screen_fx.fade_color = LIMINAL_YELLOW

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_tone, "volume_db", SILENT_DB, 1.5)
	tween.tween_method(func(value: float) -> void: _painting_material.set_shader_parameter(&"stretch", value), 0.5, 1.0, 1.5)
	# La cámara termina centrada en el encuadre espejo que repite el final (docs/14 §5.1).
	tween.tween_method(func(_value: float) -> void: player.steer_look(_painting.global_position, 0.12), 0.0, 1.0, 1.0)
	if not Game.reduced_camera_motion:
		tween.tween_method(_sway, 0.0, 1.0, 1.5)
	tween.tween_property(player, "global_position", landing, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(screen_fx, "fade", 1.0, 1.0).set_delay(0.7)
	tween.chain().tween_interval(1.3)
	tween.chain().tween_callback(func() -> void: Game.goto_scene(Game.LEVEL_1_SCENE, LIMINAL_YELLOW))


## Balanceo lento de ±6° y cabeza que se vence hacia delante.
func _sway(progress: float) -> void:
	player.camera.rotation.z = sin(progress * TAU * 1.25) * deg_to_rad(6.0) * (1.0 - progress * 0.4)
	player.head.rotation.x = lerpf(player.head.rotation.x, deg_to_rad(-14.0), progress * 0.2)
