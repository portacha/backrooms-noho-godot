class_name Player
extends CharacterBody3D
## Jugador en primera persona: caminar, correr (resistencia invisible) y mirar.
## Valores por defecto = perfil Intermedio (docs/12 §3.1). Feel de cámara: docs/13 §3.1 y §4.

## Emitida en cada paso; el radio audible alimenta el sistema de estímulos (docs/12 §3.3).
signal footstep(noise_radius: float)
signal hyperventilation_changed(active: bool)

const MOBILE_FOV: float = 70.0
const DESKTOP_FOV: float = 75.0
const PITCH_LIMIT: float = deg_to_rad(85.0)
const SETTLE_TIME: float = 0.2
const BREATH_SILENT_DB: float = -60.0

@export_group("Movimiento")
@export var walk_speed: float = 2.2
@export var sprint_speed: float = 4.2
@export var acceleration: float = 12.0
@export var deceleration: float = 16.0
## El prólogo se juega sin sprint (docs/12 §8.0).
@export var sprint_enabled: bool = true

@export_group("Resistencia")
@export var max_stamina: float = 100.0
## ~8,3 s de carrera continua (antes 5 s): el sprint es huida, no castigo.
@export var sprint_drain: float = 12.0
@export var regen_idle: float = 18.0
@export var regen_walking: float = 9.0
## Solo el agotamiento real dispara el jadeo fuerte; el cansancio previo avisa suave.
@export var hyperventilation_threshold: float = 20.0
@export var hyperventilation_linger: float = 2.5
## Toques cortos de sprint (< gracia) no consumen: reposicionarse no cansa.
@export var sprint_grace_seconds: float = 0.8
## Perfil Fácil: sin consumo y sin cues de respiración.
@export var infinite_stamina: bool = false

@export_group("Ruido")
@export var walk_noise_radius: float = 5.0
@export var sprint_noise_radius: float = 14.0
@export var hyperventilation_noise_factor: float = 1.5

@export_group("Cámara y confort")
@export_range(0.05, 1.0, 0.01) var mouse_sensitivity: float = 0.25
@export var invert_y: bool = false
## Elimina head-bob, roll y oscilaciones (docs/13 §4).
@export var reduced_camera_motion: bool = false
@export var head_bob_enabled: bool = true
## Fracción de la altura de cámara.
@export var bob_amplitude: float = 0.015
@export var sprint_roll_degrees: float = 1.5
## Metros recorridos por paso.
@export var walk_stride: float = 0.75
@export var sprint_stride: float = 1.1

@export_group("Audio")
@export var footstep_sounds: Array[AudioStream] = []
## Mezcla de terror: la respiración vive DEBAJO de pasos/ambiente, nunca encima.
## -6 dB la ponía como protagonista; -16 dB la deja presente sin enmascarar.
@export var breath_max_db: float = -16.0
## Cansancio previo: audible pero íntimo, sin penalizar sigilo.
@export var breath_tired_db: float = -28.0
@export var breath_tired_threshold: float = 65.0
## Fades orgánicos (dB/s): entrada lenta, cola natural. Sin pitch ni filtros
## (Web = todo pre-renderizado, docs/13 §9): solo automatización de volumen.
@export var breath_fade_in_db: float = 8.0
@export var breath_fade_out_db: float = 12.0

var stamina: float = 100.0
var is_sprinting: bool = false
var is_hyperventilating: bool = false
## Falso mientras se lee un documento: sin movimiento, mirada ni interacción.
var controls_enabled: bool = true:
	set(value):
		controls_enabled = value
		if is_node_ready():
			interactor.enabled = value

var _pitch: float = 0.0
var _stride_phase: float = 0.0
var _motion_weight: float = 0.0
var _sprint_weight: float = 0.0
var _linger_left: float = 0.0
var _last_step_index: int = -1
var _head_height: float = 0.0
var _has_move_input: bool = false
var _sprint_time: float = 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var _breath_player: AudioStreamPlayer = $BreathPlayer
@onready var interactor: Interactor = $Interactor
@onready var flashlight: Flashlight = $Head/Camera3D/Flashlight
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	stamina = max_stamina
	reduced_camera_motion = reduced_camera_motion or Game.reduced_camera_motion
	_head_height = _head.position.y
	_camera.fov = MOBILE_FOV if _is_touch_device() else DESKTOP_FOV
	_breath_player.volume_db = BREATH_SILENT_DB
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	var captured: bool = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and captured:
		if controls_enabled:
			_look((event as InputEventMouseMotion).relative)
	elif event is InputEventMouseButton and event.is_pressed() and not captured:
		# En Web el navegador solo concede el bloqueo del puntero tras un clic.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (global_basis * Vector3(input.x, 0.0, input.y)).normalized()
	var moving: bool = not direction.is_zero_approx()
	_has_move_input = moving

	_update_sprint(moving)
	_update_stamina(moving, delta)

	var speed: float = sprint_speed if is_sprinting else walk_speed
	var target: Vector3 = direction * speed * minf(input.length(), 1.0)
	var rate: float = acceleration if moving else deceleration
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z).move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

	_update_steps(delta)
	_update_camera(delta)
	_update_breath(delta)


## Giro de cámara en píxeles de arrastre. Lo usan el ratón y el arrastre táctil (docs/03).
func apply_look(relative: Vector2) -> void:
	if controls_enabled:
		_look(relative)


## Fija la mirada: `yaw` gira el cuerpo y `pitch` la cabeza (radianes).
func set_view(yaw: float, pitch: float) -> void:
	rotation.y = yaw
	_pitch = clampf(pitch, -PITCH_LIMIT, PITCH_LIMIT)
	_head.rotation.x = _pitch


## Acerca la mirada a un punto del mundo; `weight` 0–1 por llamada (docs/14 §6.2).
func steer_look(target: Vector3, weight: float) -> void:
	var offset: Vector3 = target - _camera.global_position
	if offset.is_zero_approx():
		return
	var yaw: float = atan2(-offset.x, -offset.z)
	var pitch: float = atan2(offset.y, Vector2(offset.x, offset.z).length())
	set_view(lerp_angle(rotation.y, yaw, weight), lerpf(_pitch, pitch, weight))


## Cede la cámara y el cuerpo a una secuencia guionizada (la caída, docs/14 §7).
func set_cutscene(active: bool) -> void:
	controls_enabled = not active
	set_physics_process(not active)
	if active:
		velocity = Vector3.ZERO
		_breath_player.stop()


func _look(relative: Vector2) -> void:
	var radians_per_pixel: float = deg_to_rad(mouse_sensitivity)
	rotate_y(-relative.x * radians_per_pixel)
	var pitch_sign: float = 1.0 if invert_y else -1.0
	_pitch = clampf(_pitch + relative.y * radians_per_pixel * pitch_sign, -PITCH_LIMIT, PITCH_LIMIT)
	_head.rotation.x = _pitch


func _update_sprint(moving: bool) -> void:
	var wants_sprint: bool = sprint_enabled and moving and is_on_floor() and Input.is_action_pressed("sprint")
	if is_sprinting:
		is_sprinting = wants_sprint and stamina > 0.0
	else:
		# Tras agotarse hay que soltar y volver a pulsar: correr es un esfuerzo, no un dash.
		is_sprinting = wants_sprint and stamina > 0.0 and Input.is_action_just_pressed("sprint")


func _update_stamina(moving: bool, delta: float) -> void:
	if infinite_stamina:
		stamina = max_stamina
		_sprint_time = 0.0
		_set_hyperventilating(false)
		return

	if is_sprinting:
		_sprint_time += delta
		# Gracia inicial sin consumo: los toques cortos no castigan.
		if _sprint_time > sprint_grace_seconds:
			stamina = maxf(stamina - sprint_drain * delta, 0.0)
	else:
		_sprint_time = 0.0
		var regen: float = regen_walking if moving else regen_idle
		stamina = minf(stamina + regen * delta, max_stamina)

	if stamina <= hyperventilation_threshold:
		_linger_left = hyperventilation_linger
		_set_hyperventilating(true)
	elif is_hyperventilating and not is_sprinting:
		_linger_left -= delta
		if _linger_left <= 0.0:
			_set_hyperventilating(false)


func _set_hyperventilating(active: bool) -> void:
	if is_hyperventilating == active:
		return
	is_hyperventilating = active
	hyperventilation_changed.emit(active)


func _update_steps(delta: float) -> void:
	var ground_speed: float = Vector3(velocity.x, 0.0, velocity.z).length()
	# Sin intención de moverse la fase se congela: la cámara se asienta sin oscilar.
	if not _has_move_input or not is_on_floor() or ground_speed < 0.3:
		return
	var stride: float = sprint_stride if is_sprinting else walk_stride
	_stride_phase += ground_speed * delta / stride
	if _stride_phase >= 1.0:
		_stride_phase = fmod(_stride_phase, 1.0)
		_play_footstep()


func _play_footstep() -> void:
	var radius: float = sprint_noise_radius if is_sprinting else walk_noise_radius
	if is_hyperventilating:
		radius *= hyperventilation_noise_factor
	footstep.emit(radius)

	if footstep_sounds.is_empty():
		return
	var index: int = randi() % footstep_sounds.size()
	if index == _last_step_index:
		index = (index + 1) % footstep_sounds.size()
	_last_step_index = index
	# Sin variación de pitch: en Web (modo Sample) todo va pre-renderizado (docs/13 §9).
	_footstep_player.stream = footstep_sounds[index]
	_footstep_player.volume_db = randf_range(-3.0, 0.0) + (2.0 if is_sprinting else 0.0)
	_footstep_player.play()


func _update_camera(delta: float) -> void:
	var ground_speed: float = Vector3(velocity.x, 0.0, velocity.z).length()
	var moving: bool = _has_move_input and is_on_floor() and ground_speed > 0.3
	var settle: float = delta / SETTLE_TIME
	_motion_weight = move_toward(_motion_weight, 1.0 if moving else 0.0, settle)
	_sprint_weight = move_toward(_sprint_weight, 1.0 if is_sprinting else 0.0, settle)

	var bob_active: bool = head_bob_enabled and not reduced_camera_motion
	var wave: float = sin(_stride_phase * TAU)
	var bob: float = wave * _head_height * bob_amplitude * _motion_weight if bob_active else 0.0
	var roll: float = 0.0
	if not reduced_camera_motion:
		# Un balanceo completo cada dos pasos (izquierda / derecha).
		roll = sin(_stride_phase * PI) * deg_to_rad(sprint_roll_degrees) * _sprint_weight * _motion_weight
	_head.position.y = _head_height + bob
	_camera.rotation.z = roll


func _update_breath(delta: float) -> void:
	var target_db: float = BREATH_SILENT_DB
	if is_hyperventilating:
		# Jadeo fuerte, pero mezclado 10 dB por debajo de antes: presencia sin grito.
		target_db = breath_max_db
	elif not infinite_stamina and stamina < breath_tired_threshold and (_has_move_input or is_sprinting):
		# Cansancio progresivo: de silencio a íntimo (-28 dB) a medida que baja
		# la resistencia. Avisa al cuerpo antes de penalizar al sigilo.
		var span: float = breath_tired_threshold - hyperventilation_threshold
		var tiredness: float = clampf((breath_tired_threshold - stamina) / maxf(span, 1.0), 0.0, 1.0)
		target_db = lerpf(BREATH_SILENT_DB, breath_tired_db, tiredness)
	var fade_speed: float = breath_fade_in_db if target_db > _breath_player.volume_db else breath_fade_out_db
	_breath_player.volume_db = move_toward(_breath_player.volume_db, target_db, fade_speed * delta)
	var audible: bool = _breath_player.volume_db > BREATH_SILENT_DB + 0.5
	if audible and not _breath_player.playing:
		_breath_player.play()
	elif not audible and _breath_player.playing:
		_breath_player.stop()


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
