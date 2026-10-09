class_name Flashlight
extends SpotLight3D
## Linterna: la única luz en tiempo real del juego (regla dura 4). Sin batería (docs/03).

signal toggled(on: bool)

## Falso hasta que el jugador la encuentra (Nivel 1, docs/12 §8.1).
@export var available: bool = false:
	set(value):
		available = value
		if not available:
			_set_on(false)

@export var nominal_energy: float = 2.4

var is_on: bool = false
## 0 = estable, 1 = fallo total. Lo fija la proximidad de la entidad (docs/12 §3.2).
var interference: float = 0.0

var _player: Player = null

@onready var _click: AudioStreamPlayer = $Click


func _ready() -> void:
	_player = owner as Player
	visible = false
	light_energy = nominal_energy


func _unhandled_input(event: InputEvent) -> void:
	if not available or not event.is_action_pressed("flashlight"):
		return
	if _player != null and not _player.controls_enabled:
		return
	turn(not is_on)


func _process(_delta: float) -> void:
	if not is_on:
		return
	var energy: float = nominal_energy
	if interference > 0.0:
		# Parpadeo irregular: más interferencia, más tiempo apagada.
		var noise: float = absf(sin(Time.get_ticks_msec() * 0.031) * sin(Time.get_ticks_msec() * 0.0173))
		energy *= 0.0 if noise < interference * 0.8 else 1.0 - interference * 0.5
	light_energy = energy


func turn(on: bool) -> void:
	if on and not available:
		return
	_set_on(on)
	_click.play()


func _set_on(on: bool) -> void:
	if is_on == on:
		return
	is_on = on
	visible = on
	toggled.emit(on)
