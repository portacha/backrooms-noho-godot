class_name Player
extends CharacterBody3D
## Jugador en primera persona: caminar, correr y mirar. Correr no cuesta: no hay resistencia;
## su precio es el ruido (docs/12 §3). Feel: docs/13 §3–§4.
## El agachado es automático, sin botón (docs/03): lo fijan los niveles con `set_crouched`.

## Emitida en cada paso; el radio audible alimenta el sistema de estímulos (docs/12 §3.3).
signal footstep(noise_radius: float)
## Lo mismo que `footstep`, con la posición: la oye la entidad sin conocer al jugador.
signal noise_made(radius: float, at: Vector3)

const MOBILE_FOV: float = 70.0
const DESKTOP_FOV: float = 75.0
const PITCH_LIMIT: float = deg_to_rad(85.0)
const SETTLE_TIME: float = 0.2
## Alturas de cámara de pie y agachado; la transición tarda 0,25 s.
const STAND_HEAD_HEIGHT: float = 1.65
const CROUCH_HEAD_HEIGHT: float = 0.9
const CROUCH_TRANSITION_SPEED: float = 3.0
const STAND_CAPSULE_HEIGHT: float = 1.8
## Casi quieto = menos de 0,3 m/s (para `is_hidden`).
const STILL_SPEED: float = 0.3

@export_group("Movimiento")
@export var walk_speed: float = 2.2
@export var sprint_speed: float = 4.2
@export var acceleration: float = 12.0
@export var deceleration: float = 16.0
## El prólogo se juega sin sprint (docs/12 §8.0).
@export var sprint_enabled: bool = true

@export_group("Ruido")
@export var walk_noise_radius: float = 5.0
@export var sprint_noise_radius: float = 14.0

@export_group("Agachado (automático, sin botón)")
@export var crouch_speed_factor: float = 0.55
@export var crouch_head_height: float = 0.9
## Cabe bajo un techo de 1,2 m.
@export var crouch_capsule_height: float = 1.1
@export var crouch_noise_radius: float = 2.0

@export_group("Agua (Nivel 3)")
## Los conductos también mojan: el entorno la fija al entrar en zonas inundadas.
@export var in_water: bool = false
@export var water_walk_noise_radius: float = 8.0
@export var water_sprint_noise_radius: float = 22.0

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

var is_sprinting: bool = false
## Agachado por el entorno (conductos, ofrendas): sin botón, sin sprint.
var is_crouched: bool = false
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
var _last_step_index: int = -1
var _head_height: float = 0.0
var _target_head_height: float = STAND_HEAD_HEIGHT
var _has_move_input: bool = false
var _water_step_sounds: Array[AudioStream] = []
var _splash_sounds: Array[AudioStream] = []
var _base_mouse_sensitivity: float = 0.25
var _base_head_bob: bool = true
var _base_reduced_motion: bool = false

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var interactor: Interactor = $Interactor
@onready var flashlight: Flashlight = $Head/Camera3D/Flashlight
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	# La cápsula se deforma al agacharse: se duplica para no tocar la escena.
	_collision_shape.shape = (_collision_shape.shape as CapsuleShape3D).duplicate()
	_load_water_sounds()
	_base_mouse_sensitivity = mouse_sensitivity
	_base_head_bob = head_bob_enabled
	_base_reduced_motion = reduced_camera_motion
	_head_height = _head.position.y
	_target_head_height = _head_height
	_camera.fov = MOBILE_FOV if _is_touch_device() else DESKTOP_FOV
	_apply_tuning()
	_apply_settings()
	Game.settings_changed.connect(_apply_settings)
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

	var speed: float = sprint_speed if is_sprinting else walk_speed
	if is_crouched:
		speed *= crouch_speed_factor
	var target: Vector3 = direction * speed * minf(input.length(), 1.0)
	var rate: float = acceleration if moving else deceleration
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z).move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

	_head_height = move_toward(_head_height, _target_head_height, CROUCH_TRANSITION_SPEED * delta)
	_update_steps(delta)
	_update_camera(delta)


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


## Agacharse automático (sin botón): lo activan los conductos del nivel.
## Cámara a ~0,9 m, cápsula bajo techos de 1,2 m, velocidad ×0,55, sin sprint.
func set_crouched(on: bool) -> void:
	if is_crouched == on:
		return
	is_crouched = on
	_target_head_height = crouch_head_height if on else _head_rest_height()
	var shape: CapsuleShape3D = _collision_shape.shape as CapsuleShape3D
	if on:
		shape.height = crouch_capsule_height
		_collision_shape.position.y = crouch_capsule_height * 0.5
	else:
		shape.height = STAND_CAPSULE_HEIGHT
		_collision_shape.position.y = STAND_CAPSULE_HEIGHT * 0.5


## Oculto = agachado, linterna apagada y casi quieto (docs/03).
func is_hidden() -> bool:
	var still: bool = Vector3(velocity.x, 0.0, velocity.z).length() < STILL_SPEED
	var dark: bool = flashlight == null or not flashlight.is_on
	return is_crouched and dark and still


## Recoloca tras una caída al vacío (N4): posición, mirada y velocidad a cero.
func respawn_at(at: Vector3, yaw: float) -> void:
	global_position = at
	velocity = Vector3.ZERO
	set_view(yaw, 0.0)


func _head_rest_height() -> float:
	return STAND_HEAD_HEIGHT


func _look(relative: Vector2) -> void:
	var radians_per_pixel: float = deg_to_rad(mouse_sensitivity)
	rotate_y(-relative.x * radians_per_pixel)
	var pitch_sign: float = 1.0 if invert_y else -1.0
	_pitch = clampf(_pitch + relative.y * radians_per_pixel * pitch_sign, -PITCH_LIMIT, PITCH_LIMIT)
	_head.rotation.x = _pitch


## Los radios de ruido salen del ajuste estándar, `Game.difficulty` (docs/12 §4).
func _apply_tuning() -> void:
	var d: Difficulty = Game.difficulty
	walk_noise_radius = d.noise_walk
	sprint_noise_radius = d.noise_sprint
	water_walk_noise_radius = d.noise_water_walk
	water_sprint_noise_radius = d.noise_water_sprint
	crouch_noise_radius = d.noise_crouch


## Ajustes en vivo: sensibilidad, inversión, head-bob y movimiento reducido.
func _apply_settings() -> void:
	mouse_sensitivity = _base_mouse_sensitivity * float(Game.setting("sensitivity"))
	invert_y = bool(Game.setting("invert_y"))
	head_bob_enabled = _base_head_bob and bool(Game.setting("head_bob"))
	reduced_camera_motion = _base_reduced_motion or bool(Game.setting("reduced_camera_motion")) or Game.reduced_camera_motion


func _update_sprint(moving: bool) -> void:
	# Correr siempre que se quiera: sin resistencia que lo limite.
	is_sprinting = sprint_enabled and not is_crouched and moving and is_on_floor() and Input.is_action_pressed("sprint")


func _step_noise_radius() -> float:
	var radius: float
	if is_crouched:
		radius = crouch_noise_radius
	elif in_water:
		radius = water_sprint_noise_radius if is_sprinting else water_walk_noise_radius
	else:
		radius = sprint_noise_radius if is_sprinting else walk_noise_radius
	return radius


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
	var radius: float = _step_noise_radius()
	footstep.emit(radius)
	noise_made.emit(radius, global_position)

	var bank: Array[AudioStream] = footstep_sounds
	if in_water and not is_crouched:
		if is_sprinting and not _splash_sounds.is_empty():
			bank = _splash_sounds
		elif not is_sprinting and not _water_step_sounds.is_empty():
			bank = _water_step_sounds
		# Sin los sonidos de agua (los genera otro agente) se pisa en seco, pero el radio sí es de agua.
	if bank.is_empty():
		return
	var index: int = randi() % bank.size()
	if index == _last_step_index:
		index = (index + 1) % bank.size()
	_last_step_index = index
	# Sin variación de pitch: en Web (modo Sample) todo va pre-renderizado (docs/13 §9).
	_footstep_player.stream = bank[index]
	_footstep_player.volume_db = randf_range(-3.0, 0.0) + (2.0 if is_sprinting else 0.0)
	# El chapoteo acompaña, no manda: va por debajo del paso seco.
	if bank != footstep_sounds:
		_footstep_player.volume_db -= 9.0 if is_sprinting else 12.0
	_footstep_player.play()


## Los pasos de agua los genera otro agente: si faltan, se juega sin ellos.
func _load_water_sounds() -> void:
	for i: int in range(1, 7):
		var path: String = "res://assets/audio/sfx/footstep_water_%02d.wav" % i
		if ResourceLoader.exists(path):
			_water_step_sounds.append(load(path) as AudioStream)
	for i: int in range(1, 4):
		var path: String = "res://assets/audio/sfx/splash_run_%02d.wav" % i
		if ResourceLoader.exists(path):
			_splash_sounds.append(load(path) as AudioStream)


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


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
