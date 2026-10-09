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
@export var sprint_drain: float = 20.0
@export var regen_idle: float = 12.0
@export var regen_walking: float = 6.0
@export var hyperventilation_threshold: float = 20.0
@export var hyperventilation_linger: float = 5.0
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
@export var breath_max_db: float = -6.0

var stamina: float = 100.0
var is_sprinting: bool = false
var is_hyperventilating: bool = false

var _pitch: float = 0.0
var _stride_phase: float = 0.0
var _motion_weight: float = 0.0
var _sprint_weight: float = 0.0
var _linger_left: float = 0.0
var _last_step_index: int = -1
var _head_height: float = 0.0
var _has_move_input: bool = false

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var _breath_player: AudioStreamPlayer = $BreathPlayer


func _ready() -> void:
	stamina = max_stamina
	_head_height = _head.position.y
	_camera.fov = MOBILE_FOV if _is_touch_device() else DESKTOP_FOV
	_breath_player.volume_db = BREATH_SILENT_DB
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	var captured: bool = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and captured:
		_look((event as InputEventMouseMotion).relative)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.is_pressed() and not captured:
		# En Web el navegador solo concede el bloqueo del puntero tras un clic.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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
		_set_hyperventilating(false)
		return

	if is_sprinting:
		stamina = maxf(stamina - sprint_drain * delta, 0.0)
	else:
		var regen: float = regen_walking if moving else regen_idle
		stamina = minf(stamina + regen * delta, max_stamina)

	if stamina < hyperventilation_threshold:
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
	var target_db: float = breath_max_db if is_hyperventilating else BREATH_SILENT_DB
	var fade_speed: float = 60.0 if is_hyperventilating else 20.0
	_breath_player.volume_db = move_toward(_breath_player.volume_db, target_db, fade_speed * delta)
	var audible: bool = _breath_player.volume_db > BREATH_SILENT_DB + 0.5
	if audible and not _breath_player.playing:
		_breath_player.play()
	elif not audible and _breath_player.playing:
		_breath_player.stop()


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
