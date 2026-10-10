class_name Flashlight
extends SpotLight3D
## Linterna: la única luz en tiempo real del juego (regla dura 4). Sin batería (docs/03).
## Habla con la proximidad de la entidad: el parpadeo es el radar (docs/12 §3.2, docs/13 §3.2).

signal toggled(on: bool)
## Cada parpadeo o apagón avisa con su fuerza (0 = leve, 1 = apagón total).
signal flickered(strength: float)

## Banda de amenaza actual; la leen la entidad, los niveles y el test.
enum ThreatBand { STABLE, FLICKER, FAIL, BLACKOUT }

## Falso hasta que el jugador la encuentra (Nivel 1, docs/12 §8.1).
@export var available: bool = false:
	set(value):
		available = value
		if not available:
			_set_on(false)

@export var nominal_energy: float = 2.4
## Semiángulo del cono central que "enfoca" a la entidad (docs/12 §3.2 y §6).
@export_range(5.0, 45.0, 0.5) var cone_half_angle_degrees: float = 14.0
## Alcance máximo al que la linterna ilumina un punto.
@export var lighting_range: float = 30.0

## Sin llamadas de la entidad en este tiempo, vuelve a estable.
const THREAT_TIMEOUT: float = 0.5
## Parpadeo leve: de uno cada 3 s lejos a uno cada 0,8 s cerca del fallo.
const FLICKER_PERIOD_FAR: float = 3.0
const FLICKER_PERIOD_NEAR: float = 0.8
const FLICKER_DIP_SECONDS: float = 0.12
const FLICKER_DIP_RATIO: float = 0.3
## Banda de fallo: mitad de luz con apagados de ~1 s (ciclo de 2 s).
const FAIL_CYCLE: float = 2.0
const FAIL_LIT_SECONDS: float = 1.0
const FAIL_RATIO: float = 0.5
## Interferencia de persecución: baches rápidos sobre su base sostenida.
const CHASE_CYCLE: float = 1.5
const CHASE_DIP_SECONDS: float = 0.4
const CHASE_DIP_RATIO: float = 0.2
const CAPTION_COOLDOWN: float = 8.0
const FAIL_SOUND_PATH: String = "res://assets/audio/sfx/flashlight_fail.wav"
const FAIL_CAPTION: String = "[la linterna falla]"
const VIBRATE_BLINK_MS: int = 30
const VIBRATE_CLOSE_MS: int = 150
const CLOSE_DISTANCE: float = 6.0

var is_on: bool = false
## 0 = estable, 1 = fallo total. Lo fija la proximidad de la entidad (docs/12 §3.2).
var interference: float = 0.0
var band: ThreatBand = ThreatBand.STABLE
## Intensidad efectiva 0–1 tras aplicar amenaza, guion y suelo de dificultad.
var ratio: float = 1.0

var _threat_distance: float = INF
var _threat_chasing: bool = false
var _threat_age: float = 99.0
var _killed: bool = false
var _blackout_left: float = 0.0
var _cycle: float = 0.0
var _chase_cycle: float = 0.0
var _blink_left: float = 0.0
var _fail_was_lit: bool = true
var _chase_was_dip: bool = false
var _blackout_announced: bool = false
var _caption_left: float = 0.0
var _fail_player: AudioStreamPlayer = null
var _player: Player = null

@onready var _click: AudioStreamPlayer = $Click


func _ready() -> void:
	_player = owner as Player
	visible = false
	light_energy = nominal_energy
	# El sonido de fallo fuerte lo genera otro agente: si falta, se sigue sin él.
	if ResourceLoader.exists(FAIL_SOUND_PATH):
		_fail_player = AudioStreamPlayer.new()
		_fail_player.stream = load(FAIL_SOUND_PATH) as AudioStream
		_fail_player.volume_db = -4.0
		add_child(_fail_player)


func _unhandled_input(event: InputEvent) -> void:
	if not available or not event.is_action_pressed("flashlight"):
		return
	if _player != null and not _player.controls_enabled:
		return
	turn(not is_on)


func _physics_process(delta: float) -> void:
	_threat_age += delta
	_chase_cycle += delta
	_caption_left = maxf(_caption_left - delta, 0.0)
	_blackout_left = maxf(_blackout_left - delta, 0.0)
	_update_band()
	_update_ratio(delta)
	_apply_light()


## La entidad la llama cada fotograma físico con su distancia; sin llamadas, estable.
func set_threat(distance: float, chasing: bool) -> void:
	_threat_distance = distance
	_threat_chasing = chasing
	_threat_age = 0.0


## Punto iluminado = encendida, sin fallo que la apague, dentro del cono y a ≤ 30 m.
## Sin raycast: la línea de visión la comprueba la entidad.
func is_lighting(point: Vector3) -> bool:
	if not is_on or _killed or _blackout_left > 0.0 or ratio <= 0.05:
		return false
	var offset: Vector3 = point - global_position
	var distance: float = offset.length()
	if distance > lighting_range:
		return false
	if distance < 0.001:
		return true
	var forward: Vector3 = -global_transform.basis.z
	return forward.angle_to(offset / distance) <= deg_to_rad(cone_half_angle_degrees)


## Apagón guionizado de unos segundos (los guiones de nivel).
func pulse_blackout(seconds: float) -> void:
	_blackout_left = maxf(_blackout_left, seconds)


## N4: la linterna muere en la carrera final; ni el suelo de Fácil la salva.
func kill() -> void:
	_killed = true
	_set_ratio(0.0)
	visible = false


func revive() -> void:
	_killed = false
	visible = is_on


func turn(on: bool) -> void:
	if on and not available:
		return
	_set_on(on)
	_click.play()


func _set_on(on: bool) -> void:
	if is_on == on:
		return
	is_on = on
	visible = on and not _killed and _blackout_left <= 0.0
	toggled.emit(on)


func _update_band() -> void:
	var next: ThreatBand = ThreatBand.STABLE
	if _threat_age <= THREAT_TIMEOUT:
		var d: Difficulty = Game.difficulty
		if _threat_distance < d.light_blackout_distance:
			next = ThreatBand.BLACKOUT
		elif _threat_distance < d.light_fail_distance:
			next = ThreatBand.FAIL
		elif _threat_distance < d.light_flicker_distance:
			next = ThreatBand.FLICKER
	if next != band:
		band = next
		_cycle = 0.0
		_blink_left = 0.0
		_fail_was_lit = true
		_chase_was_dip = false
		_blackout_announced = false


func _update_ratio(delta: float) -> void:
	# Guion y muerte mandan sobre la amenaza (sin suelo de dificultad).
	if _killed or _blackout_left > 0.0:
		_set_ratio(0.0)
		return
	var d: Difficulty = Game.difficulty
	var target: float = 1.0
	match band:
		ThreatBand.FLICKER:
			target = _flicker_target(delta, d)
		ThreatBand.FAIL:
			target = _fail_target(delta)
		ThreatBand.BLACKOUT:
			if not _blackout_announced:
				_blackout_announced = true
				_announce(1.0)
			target = 0.0
	if _threat_chasing:
		target = minf(target, (1.0 - d.light_chase_interference) * _chase_gate())
	# En Fácil la luz nunca baja del 40 % (docs/12 §4.4).
	_set_ratio(maxf(target, d.light_min_ratio))


## Parpadeos breves con ritmo reconocible: más rápidos cuanto más cerca.
func _flicker_target(delta: float, d: Difficulty) -> float:
	var span: float = maxf(d.light_flicker_distance - d.light_fail_distance, 0.001)
	var closeness: float = clampf(1.0 - (_threat_distance - d.light_fail_distance) / span, 0.0, 1.0)
	var period: float = lerpf(FLICKER_PERIOD_FAR, FLICKER_PERIOD_NEAR, closeness)
	_cycle += delta
	if _cycle >= period:
		_cycle = fmod(_cycle, period)
		_blink_left = FLICKER_DIP_SECONDS
		_announce(0.3 + 0.4 * closeness)
	if _blink_left > 0.0:
		_blink_left -= delta
		return FLICKER_DIP_RATIO
	return 1.0


func _fail_target(delta: float) -> float:
	_cycle += delta
	var lit: bool = fmod(_cycle, FAIL_CYCLE) < FAIL_LIT_SECONDS
	if lit != _fail_was_lit:
		_fail_was_lit = lit
		if not lit:
			_announce(1.0)
	return FAIL_RATIO if lit else 0.0


func _chase_gate() -> float:
	var phase: float = fmod(_chase_cycle, CHASE_CYCLE)
	if phase < CHASE_DIP_SECONDS:
		if not _chase_was_dip:
			_chase_was_dip = true
			_announce(0.7)
		return CHASE_DIP_RATIO
	_chase_was_dip = false
	return 1.0


func _announce(strength: float) -> void:
	flickered.emit(strength)
	# Vibración como radar (docs/13 §8): pulso largo con la entidad a < 6 m.
	if _threat_distance < CLOSE_DISTANCE:
		Game.vibrate(VIBRATE_CLOSE_MS)
	else:
		Game.vibrate(VIBRATE_BLINK_MS)
	if strength >= 0.7 and _caption_left <= 0.0:
		_caption_left = CAPTION_COOLDOWN
		Game.caption(FAIL_CAPTION, 3.0)
	if strength >= 1.0 and _fail_player != null and not _fail_player.playing:
		_fail_player.play()


func _set_ratio(value: float) -> void:
	ratio = clampf(value, 0.0, 1.0)


func _apply_light() -> void:
	interference = 1.0 - ratio
	if not is_on:
		return
	light_energy = nominal_energy * ratio
	visible = ratio > 0.0 and not _killed and _blackout_left <= 0.0
