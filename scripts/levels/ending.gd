extends LevelBase
## Final — "El retorno y el gafete" (docs/11 §9, docs/13 §6.4 y §11).
## Sin control del jugador: la misma sala de juntas del prólogo, el cuadro ya sin
## color, un cabeceo lento hasta el gafete y la pantalla de resolución.
## Reutiliza `scenes/levels/generated/prologue.scn` tal cual; no la regenera.

signal badge_framed
signal resolution_opened

const GREY_TEXTURE: Texture2D = preload("res://assets/textures/painting_grey.png")
const PAINTING_SHADER: Shader = preload("res://shaders/painting.gdshader")
const SILENCE_LOOP: AudioStream = preload("res://assets/audio/ambient/office_silence_loop.ogg")
const RESOLUTION_SCENE: PackedScene = preload("res://scenes/ui/resolution_screen.tscn")

const PAINTING_SIZE: Vector2 = Vector2(2.4, 1.8)
const PAINTING_ENERGY: float = 1.15
const SILENCE_DB: float = -60.0
## El hilo de silencio apenas se oye tras unos segundos.
const SILENCE_AUDIBLE_DB: float = -28.0
const BLACK_HOLD: float = 0.5
const REVEAL_TIME: float = 2.0
const SILENCE_FADE_DELAY: float = 3.0
const NOD_START: float = 12.0
const NOD_TIME: float = 3.5
const BADGE_HOLD: float = 4.0
const FADE_TIME: float = 2.0
## Los primeros 3 s ni Esc ni el toque saltan la secuencia.
const SKIP_LOCK: float = 3.0
## El gafete cuelga del cuello, de cara a la cámara (sur). Origen del modelo = arriba,
## junto al cordón; el cuerpo cuelga debajo.
const BADGE_POS: Vector3 = Vector3(21.0, 1.155, 3.02)
const BADGE_TOP: Vector3 = Vector3(21.0, 1.34, 3.02)

## Lienzo gris, para la verificación.
var painting: MeshInstance3D = null
var badge: Node3D = null
var resolution: ResolutionScreen = null

var _time: float = 0.0
var _silence: AudioStreamPlayer = null
var _badge_pivot: Node3D = null
var _nod_tween: Tween = null
var _start_pitch: float = -0.12
var _badge_pitch: float = -0.9
var _nod_done: bool = false
var _finished: bool = false


func _ready() -> void:
	super()
	# De pie frente al cuadro, encuadre idéntico al de la mirada del prólogo pero resuelto.
	player.global_position = Vector3(marker("mirror_frame").x, 0.0, marker("mirror_frame").z)
	player.sprint_enabled = false
	player.flashlight.available = false
	player.steer_look(marker("painting"), 1.0)
	player.set_cutscene(true)
	_start_pitch = player.head.rotation.x
	set_touch_button(&"sprint_visible", false)
	set_touch_button(&"flashlight_visible", false)
	set_can_pause(false)
	var reticle: Node = hud.get_node_or_null("Reticle")
	if reticle is CanvasItem:
		(reticle as CanvasItem).hide()
	# Luz de oficina estable: los tubos lucen fijos, todo normal. Demasiado normal.
	RenderingServer.global_shader_parameter_set(&"flicker_override", 1.0)
	_build_painting()
	_build_badge()
	# Entra desde negro tras medio segundo de silencio absoluto: ningún sonido de juego.
	screen_fx.fade = 1.0
	var reveal: Tween = create_tween()
	reveal.tween_interval(BLACK_HOLD)
	reveal.tween_property(screen_fx, "fade", 0.0, REVEAL_TIME)
	_silence = add_loop(SILENCE_LOOP, SILENCE_DB)
	get_tree().create_timer(SILENCE_FADE_DELAY).timeout.connect(_fade_silence_in)
	get_tree().create_timer(NOD_START).timeout.connect(_begin_nod)


func _process(delta: float) -> void:
	super(delta)
	_time += delta
	if _badge_pivot != null:
		# El gafete cuelga: leve balanceo diegético (no es cámara, no se reduce).
		_badge_pivot.rotation.x = sin(_time * 1.1) * 0.04
		_badge_pivot.rotation.z = sin(_time * 0.87 + 1.3) * 0.05


func _unhandled_input(event: InputEvent) -> void:
	if _finished or _time < SKIP_LOCK:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		skip_to_resolution()
	elif event is InputEventMouseButton and event.pressed:
		skip_to_resolution()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		skip_to_resolution()


## Salta al fundido y la resolución. La prueba lo usa tras enmarcar el gafete.
func skip_to_resolution() -> void:
	if _finished or _time < SKIP_LOCK:
		return
	if not _nod_done:
		_nod_done = true
		if _nod_tween != null:
			_nod_tween.kill()
		player.set_view(0.0, _badge_pitch)
		player.camera.rotation.z = 0.0
		badge_framed.emit()
	_finish()


## Centro del gafete en el mundo, para la verificación del encuadre.
func badge_center() -> Vector3:
	if _badge_pivot == null:
		return BADGE_POS + Vector3(0.0, 0.065, 0.0)
	return _badge_pivot.global_position + Vector3(0.0, -0.12, 0.0)


## El mismo lienzo del prólogo, pero ya sin color (docs/11 §9.4).
func _build_painting() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = PAINTING_SIZE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = PAINTING_SHADER
	material.set_shader_parameter(&"painting_tex", GREY_TEXTURE)
	material.set_shader_parameter(&"energy", PAINTING_ENERGY)
	material.set_shader_parameter(&"variant", 0.0)
	material.set_shader_parameter(&"stretch", 0.0)
	painting = MeshInstance3D.new()
	painting.mesh = quad
	painting.material_override = material
	add_child(painting)
	painting.global_position = marker("painting")


## El gafete D16: modelo `badge_noho` (el pétalo va en el modelo) + tres `Label3D`.
func _build_badge() -> void:
	_badge_pivot = Node3D.new()
	add_child(_badge_pivot)
	_badge_pivot.global_position = BADGE_TOP
	badge = spawn_model("badge_noho", _badge_pivot, 1.5, 1.2)
	badge.position = BADGE_POS - BADGE_TOP
	# La cara mira al sur (+z), hacia la cámara: el texto va un poco por delante.
	# Alturas de las piezas del modelo (pantalla y placa del nombre).
	_add_badge_label("NOHO", Vector3(0.0, -0.074, 0.010), 32, 0.0006, Color(0.75, 0.88, 1.0))
	_add_badge_label("COLABORADOR VIGENTE", Vector3(0.0, -0.093, 0.010), 16, 0.0004, Color(0.85, 0.85, 0.84))
	_add_badge_label("NOHO", Vector3(0.0, -0.105, 0.010), 16, 0.0005, Color(0.9, 0.9, 0.88))
	var eye: Vector3 = player.camera.global_position
	var target: Vector3 = badge_center()
	var flat: Vector2 = Vector2(target.x - eye.x, target.z - eye.z)
	_badge_pitch = atan2(target.y - eye.y, flat.length())


func _add_badge_label(text: String, at: Vector3, font_size: int, pixel: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font = SIGN_FONT
	label.font_size = font_size
	label.pixel_size = pixel
	label.outline_size = 0
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_pivot.add_child(label)
	label.position = at
	label.rotation.y = 0.0


func _fade_silence_in() -> void:
	if _silence == null or not is_instance_valid(_silence):
		return
	var tween: Tween = create_tween()
	tween.tween_property(_silence, "volume_db", SILENCE_AUDIBLE_DB, 4.0)


## La cámara baja sola hasta el pecho (docs/13 §3.4: el gafete es automático).
func _begin_nod() -> void:
	if _finished or _nod_done:
		return
	_nod_tween = create_tween()
	_nod_tween.tween_method(_apply_nod, 0.0, 1.0, NOD_TIME)
	_nod_tween.tween_callback(_on_nod_done)


func _apply_nod(weight: float) -> void:
	var eased: float = smoothstep(0.0, 1.0, weight)
	player.set_view(0.0, lerpf(_start_pitch, _badge_pitch, eased))
	if not Game.reduced_camera_motion:
		# Vaivén leve durante el cabeceo; con movimiento reducido, solo el giro.
		player.camera.rotation.z = sin(weight * TAU) * deg_to_rad(1.2) * (1.0 - weight * 0.3)


func _on_nod_done() -> void:
	player.camera.rotation.z = 0.0
	_nod_done = true
	badge_framed.emit()
	get_tree().create_timer(BADGE_HOLD).timeout.connect(func() -> void:
		if not _finished:
			_finish())


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _nod_tween != null:
		_nod_tween.kill()
	var tween: Tween = create_tween()
	tween.tween_property(screen_fx, "fade", 1.0, FADE_TIME)
	tween.tween_callback(_open_resolution)


func _open_resolution() -> void:
	screen_fx.fade = 1.0
	if _silence != null and is_instance_valid(_silence):
		_silence.stop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	resolution = RESOLUTION_SCENE.instantiate() as ResolutionScreen
	add_child(resolution)
	# Ella llama a `Game.finish_game()` y rompe el silencio con el audio de marca.
	resolution.open()
	resolution_opened.emit()
