class_name MirrorSteps
extends Node3D
## Pasos espejo (docs/12 §8.1): durante un evento, cada paso del jugador se repite un
## instante después desde una habitación contigua. Si él se detiene, se detienen; si
## corre, se aceleran. Nunca se acercan: la fuente mantiene su distancia.

signal event_started
signal event_finished

@export var step_sounds: Array[AudioStream] = []
@export var echo_delay: float = 0.34
@export var min_distance: float = 8.0
@export var max_distance: float = 12.0
@export var event_duration: float = 11.0
@export var volume_db: float = -3.0

var active: bool = false

var _player: Player = null
var _offset: Vector3 = Vector3.ZERO
var _time_left: float = 0.0
var _last_index: int = -1

@onready var _voice: AudioStreamPlayer3D = $Voice


func setup(player: Player) -> void:
	_player = player
	_player.footstep.connect(_on_player_footstep)


func _process(delta: float) -> void:
	if not active:
		return
	global_position = _player.global_position + _offset
	_time_left -= delta
	if _time_left <= 0.0:
		active = false
		event_finished.emit()


## Empieza un evento: los pasos suenan a la espalda del jugador, algo ladeados.
func start_event() -> void:
	if active or _player == null:
		return
	var behind: Vector3 = _player.global_basis.z
	var side: float = [-1.0, 1.0].pick_random()
	var direction: Vector3 = (behind + _player.global_basis.x * side * 0.7).normalized()
	_offset = direction * randf_range(min_distance, max_distance)
	_time_left = event_duration
	active = true
	event_started.emit()


func _on_player_footstep(_noise_radius: float) -> void:
	if not active or step_sounds.is_empty():
		return
	await get_tree().create_timer(echo_delay).timeout
	if not active:
		return
	var index: int = randi() % step_sounds.size()
	if index == _last_index:
		index = (index + 1) % step_sounds.size()
	_last_index = index
	_voice.stream = step_sounds[index]
	_voice.volume_db = volume_db + randf_range(-2.0, 0.0)
	_voice.play()
