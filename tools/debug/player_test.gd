extends Node
## Prueba del jugador, la linterna y los ajustes. Uso:
##   tools/run_godot.sh --headless --path . res://tools/debug/player_test.tscn
## Afirma perfiles de dificultad, agachado, ruido en agua, bandas de amenaza,
## cono de luz, kill/revive, sensibilidad e inversión. Imprime PLAYER TEST OK/FAIL.

var _fails: int = 0
var _blinks: int = 0
var _exhaust_count: int = 0
var _last_footstep: float = -1.0
var _last_noise: float = -1.0
var _saved_settings: Dictionary = {}
var _saved_difficulty: Difficulty.Id = Difficulty.Id.NORMAL

@onready var _player: Player = $Player


func _ready() -> void:
	_saved_settings = Game.settings.duplicate()
	_saved_difficulty = Game.selected_difficulty()
	_player.flashlight.flickered.connect(_on_blink)
	_player.exhaustion_changed.connect(_on_exhaust)
	_player.footstep.connect(_on_footstep)
	_player.noise_made.connect(_on_noise)
	await get_tree().physics_frame
	await get_tree().create_timer(1.0).timeout
	await _run()
	for key: String in _saved_settings:
		Game.set_setting(key, _saved_settings[key])
	Game.select_difficulty(_saved_difficulty)
	Input.action_release("move_forward")
	Input.action_release("sprint")
	print("PLAYER TEST %s (%d fallos)" % ["OK" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(_fails)


func _check(condition: bool, label: String) -> void:
	print(("OK   " if condition else "FAIL ") + label)
	if not condition:
		_fails += 1


func _on_blink(_strength: float) -> void:
	_blinks += 1


func _on_exhaust(_ratio: float) -> void:
	_exhaust_count += 1


func _on_footstep(radius: float) -> void:
	_last_footstep = radius


func _on_noise(radius: float, _at: Vector3) -> void:
	_last_noise = radius


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


## Mantiene correr pulsado; el arranque por toque necesita un evento real
## (`action_press` no marca `just_pressed`), así que se re-envía hasta arrancar.
func _hold_sprint(frames: int) -> void:
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for i: int in frames:
		if not _player.is_sprinting:
			var ev := InputEventAction.new()
			ev.action = &"sprint"
			ev.pressed = true
			Input.parse_input_event(ev)
		await get_tree().physics_frame


func _release_all() -> void:
	Input.action_release("move_forward")
	Input.action_release("sprint")
	await _frames(5)


func _step_once() -> void:
	_last_footstep = -1.0
	_last_noise = -1.0
	_player._play_footstep()


func _run() -> void:
	_check(_player.is_on_floor(), "el jugador apoya en el suelo del test")
	_check(_player.flashlight != null and _player.interactor != null, "linterna e interactor presentes")

	# --- Perfiles de dificultad ------------------------------------------------
	Game.select_difficulty(Difficulty.Id.EASY)
	await _frames(3)
	_check(_player.infinite_stamina and _player.sprint_drain == 0.0, "Fácil: resistencia infinita sin consumo")
	_exhaust_count = 0
	await _hold_sprint(120)
	_check(_player.is_sprinting, "Fácil: el sprint arranca y se mantiene")
	_check(is_equal_approx(_player.stamina, _player.max_stamina), "Fácil: esprintar no gasta")
	_check(not _player.is_hyperventilating and _exhaust_count == 0, "Fácil: sin jadeo ni señales de agotamiento")
	var breath: AudioStreamPlayer = _player.get_node("BreathPlayer") as AudioStreamPlayer
	_check(breath.volume_db <= -59.0, "Fácil: sin respiración audible")
	await _release_all()

	Game.select_difficulty(Difficulty.Id.NORMAL)
	await _frames(3)
	_check(_player.sprint_drain == 20.0 and _player.regen_idle == 12.0 and _player.regen_walking == 6.0, "Intermedio: consumo 20 y regen 12/6")
	_check(_player.walk_noise_radius == 5.0 and _player.sprint_noise_radius == 14.0, "Intermedio: ruido 5/14 m")
	_check(_player.water_walk_noise_radius == 8.0 and _player.water_sprint_noise_radius == 22.0, "Intermedio: agua 8/22 m")
	_check(_player.crouch_noise_radius == 2.0 and _player.hyperventilation_noise_factor == 1.5, "Intermedio: conducto 2 m e hiperventilación x1,5")
	var before: float = _player.stamina
	await _hold_sprint(180)
	_check(_player.stamina < before - 10.0, "Intermedio: esprintar consume (%d u)" % int(_player.stamina))
	_check(_player.is_sprinting, "Intermedio: sigue corriendo con reserva")
	await _release_all()
	before = _player.stamina
	await _frames(120)
	_check(_player.stamina > before, "Intermedio: la resistencia regenera en reposo")
	_player.restore_stamina()
	_check(is_equal_approx(_player.stamina, _player.max_stamina), "restore_stamina llena del todo")

	Game.select_difficulty(Difficulty.Id.HARD)
	await _frames(3)
	_check(_player.sprint_drain == 24.0 and _player.regen_idle == 8.0 and _player.regen_walking == 4.0, "Difícil: consumo 24 y regen 8/4")
	_check(_player.walk_noise_radius == 7.0 and _player.sprint_noise_radius == 18.0, "Difícil: ruido 7/18 m")
	_check(_player.water_walk_noise_radius == 10.0 and _player.water_sprint_noise_radius == 28.0, "Difícil: agua 10/28 m")
	_check(_player.crouch_noise_radius == 3.0 and _player.hyperventilation_noise_factor == 1.8, "Difícil: conducto 3 m e hiperventilación x1,8")
	Game.select_difficulty(Difficulty.Id.NORMAL)
	await _frames(3)

	# --- Agachado automático ---------------------------------------------------
	_player.set_crouched(true)
	await get_tree().create_timer(0.45).timeout
	_check(_player.is_crouched, "agachado activo")
	_check(absf(_player.head.position.y - 0.9) < 0.06, "cámara a ~0,9 m (%.2f)" % _player.head.position.y)
	var shape: CollisionShape3D = _player.get_node("CollisionShape3D") as CollisionShape3D
	var capsule: CapsuleShape3D = shape.shape as CapsuleShape3D
	_check(shape.position.y + capsule.height * 0.5 <= 1.21, "cápsula bajo techo de 1,2 m (alto %.2f)" % (shape.position.y + capsule.height * 0.5))
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await _frames(45)
	_check(not _player.is_sprinting, "agachado: sin sprint")
	var crouch_speed: float = Vector3(_player.velocity.x, 0.0, _player.velocity.z).length()
	_check(absf(crouch_speed - 2.2 * 0.55) < 0.4, "agachado: velocidad x0,55 (%.2f m/s)" % crouch_speed)
	_step_once()
	_check(_last_footstep == 2.0 and _last_noise == 2.0, "agachado: ruido de conducto y doble señal")
	await _release_all()
	_player.set_crouched(false)
	await get_tree().create_timer(0.45).timeout
	_check(not _player.is_crouched and absf(_player.head.position.y - 1.65) < 0.06, "al salir se incorpora solo")

	# --- Ruido en agua ----------------------------------------------------------
	_player.in_water = true
	_player.is_sprinting = false
	_step_once()
	_check(_last_footstep == 8.0, "agua andando: 8 m")
	_player.is_sprinting = true
	_step_once()
	_check(_last_footstep == 22.0, "agua corriendo: 22 m")
	_player.is_sprinting = false
	_player.in_water = false
	_step_once()
	_check(_last_footstep == 5.0, "en seco vuelve a 5 m")

	# --- Linterna: bandas de amenaza -------------------------------------------
	var light: Flashlight = _player.flashlight
	light.available = true
	light.turn(true)
	light.revive()
	light.set_threat(20.0, false)
	await _frames(3)
	_check(light.band == Flashlight.ThreatBand.STABLE and light.ratio > 0.99, "lejos: estable al 100 %")
	light.set_threat(9.0, false)
	await _frames(3)
	_check(light.band == Flashlight.ThreatBand.FLICKER, "a 9 m: banda de parpadeo")
	light.set_threat(4.0, false)
	await _frames(3)
	_check(light.band == Flashlight.ThreatBand.FAIL, "a 4 m: banda de fallo")
	light.set_threat(1.0, false)
	await _frames(3)
	_check(light.band == Flashlight.ThreatBand.BLACKOUT and light.ratio <= 0.01, "a 1 m: apagado sostenido")
	await get_tree().create_timer(0.7).timeout
	_check(light.band == Flashlight.ThreatBand.STABLE and light.ratio > 0.99, "sin llamadas 0,5 s: vuelve a estable")

	# --- Suelo de Fácil y ritmo del parpadeo ------------------------------------
	Game.select_difficulty(Difficulty.Id.EASY)
	await _frames(3)
	var low: float = 1.0
	for i: int in 72:
		light.set_threat(0.5, false)
		await get_tree().physics_frame
		low = minf(low, light.ratio)
	_check(low >= 0.39, "Fácil: nunca bajo el 40 % (mín " + str(snappedf(low, 0.01)) + ")")
	Game.select_difficulty(Difficulty.Id.NORMAL)
	await _frames(3)
	_blinks = 0
	for i: int in 150:
		light.set_threat(4.0, false)
		await get_tree().physics_frame
	_check(_blinks >= 1, "los fallos emiten flickered (%d)" % _blinks)

	# --- Cono de luz -------------------------------------------------------------
	light.set_threat(20.0, false)
	_player.set_view(0.0, 0.0)
	await _frames(3)
	var origin: Vector3 = light.global_position
	_check(light.is_lighting(origin + Vector3(0.0, 0.0, -5.0)), "ilumina dentro del cono")
	_check(not light.is_lighting(origin + Vector3(0.0, 0.0, 5.0)), "no ilumina detrás")
	_check(not light.is_lighting(origin + Vector3(0.0, 0.0, -40.0)), "no ilumina a 40 m")
	light.turn(false)
	await _frames(2)
	_check(not light.is_lighting(origin + Vector3(0.0, 0.0, -5.0)), "apagada no ilumina")
	light.turn(true)
	light.kill()
	await _frames(2)
	_check(light.ratio <= 0.01 and not light.is_lighting(origin + Vector3(0.0, 0.0, -5.0)), "kill apaga del todo")
	light.revive()
	light.set_threat(20.0, false)
	await _frames(3)
	_check(light.ratio > 0.99, "revive devuelve la luz")

	# --- Ocultarse ---------------------------------------------------------------
	light.turn(false)
	_player.set_crouched(true)
	await _frames(10)
	_check(_player.is_hidden(), "agachado + a oscuras + quieto = oculto")
	_player.set_crouched(false)
	await _frames(5)
	_check(not _player.is_hidden(), "de pie no está oculto")

	# --- Sensibilidad e inversión --------------------------------------------------
	Game.set_setting("sensitivity", 1.0)
	await _frames(2)
	_player.set_view(0.0, 0.0)
	_player.apply_look(Vector2(100.0, 0.0))
	var step1: float = _player.rotation.y
	Game.set_setting("sensitivity", 2.0)
	await _frames(2)
	_player.apply_look(Vector2(100.0, 0.0))
	var step2: float = _player.rotation.y - step1
	_check(absf(step2 / step1 - 2.0) < 0.05, "sensibilidad x2 duplica el giro")
	Game.set_setting("sensitivity", 1.0)
	Game.set_setting("invert_y", false)
	await _frames(2)
	_player.set_view(0.0, 0.0)
	_player.apply_look(Vector2(0.0, 50.0))
	var pitch1: float = _player.head.rotation.x
	_player.set_view(0.0, 0.0)
	Game.set_setting("invert_y", true)
	await _frames(2)
	_player.apply_look(Vector2(0.0, 50.0))
	var pitch2: float = _player.head.rotation.x
	_check(not is_zero_approx(pitch1) and signf(pitch1) != signf(pitch2), "invert_y invierte el cabeceo")

	# --- Recolocar -----------------------------------------------------------------
	_player.set_crouched(false)
	_player.respawn_at(Vector3(3.0, 0.5, 4.0), 1.2)
	_check(_player.global_position.is_equal_approx(Vector3(3.0, 0.5, 4.0)), "respawn_at recoloca")
	_check(is_equal_approx(_player.rotation.y, 1.2) and _player.velocity.is_zero_approx(), "respawn_at fija yaw y frena")
