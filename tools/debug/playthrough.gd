extends Node
## Prueba de integración: recorre menú → prólogo → caída → Nivel 1 → letra → tarjeta final
## teletransportando al jugador y pulsando interactuar. Uso:
##   godot --headless --path . res://tools/debug/playthrough.tscn

var _fails: int = 0


func _ready() -> void:
	# Deja de ser la escena actual para sobrevivir a los cambios de escena.
	await get_tree().process_frame
	get_tree().current_scene = null
	await _run()
	print("PLAYTHROUGH %s (%d fallos)" % ["OK" if _fails == 0 else "FALLÓ", _fails])
	get_tree().quit(_fails)


func _check(condition: bool, label: String) -> void:
	print(("OK   " if condition else "FAIL ") + label)
	if not condition:
		_fails += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Con ventana (sin --headless) y PLAY_SHOTS=1 guarda capturas en builds/.
func _snap(label: String) -> void:
	if OS.get_environment("PLAY_SHOTS") != "1" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/play_%s.png" % label)


func _level() -> Node:
	return get_tree().current_scene


func _focus_and_press(level: Node, at: Vector3, look_at_point: Vector3, expected: String) -> void:
	var player: Player = level.get_node("Player")
	player.global_position = at
	await _wait(0.1)
	player.steer_look(look_at_point, 1.0)
	await _wait(0.2)
	_check(player.interactor.focus != null, "foco en %s" % expected)
	player.interactor.press()


func _run() -> void:
	# El árbol arranca con esta escena; cambiamos al menú como haría el juego.
	Game.return_to_menu()
	await _wait(0.5)
	_check(_level().scene_file_path == Game.MENU_SCENE, "menú principal cargado")
	await _snap("01_menu")
	Game.start_new_game()
	await _wait(1.0)
	var prologue: Node = _level()
	_check(prologue.scene_file_path == Game.PROLOGUE_SCENE, "prólogo cargado")
	var player: Player = prologue.get_node("Player")
	var hud: Hud = prologue.get_node("Hud")
	var overlay: DocumentOverlay = hud.get_node("DocumentOverlay")
	_check(not player.sprint_enabled and not player.flashlight.available, "prólogo sin sprint ni linterna")
	await _wait(1.2)
	await _snap("02_start")
	await _wait(2.6)
	await _snap("03_locked")

	for id: String in ["d02", "d01", "d03"]:
		var target: Vector3 = prologue.call("marker", "d02_screen" if id == "d02" else id)
		var stand: Vector3 = Vector3(target.x, 0.0, target.z) + Vector3(0.0, 0.0, 1.0)
		await _focus_and_press(prologue, stand, target, id)
		await _wait(0.2)
		_check(overlay.visible and overlay.document != null and String(overlay.document.id).to_lower() == id, "se lee %s" % id)
		await _wait(0.4)
		overlay.close()
		await _wait(0.1)
		await _snap("04_" + id)

	# Las luces del pasillo fallan al pasar por el cruce y el oficinista lo comenta.
	var junction: Vector3 = prologue.call("marker", "junction")
	player.global_position = junction
	await _wait(2.6)
	_check(hud.get_node("Line").modulate.a > 0.0, "comentario sobre las luces")
	await _snap("04_lights")

	# El cuadro: basta mirarlo de cerca. Apartar la vista corta la transición.
	var painting: Vector3 = prologue.call("marker", "painting")
	var screen_fx: ScreenFx = prologue.get_node("ScreenFx")
	_check(player.interactor.focus == null or not player.interactor.focus.hold_time > 0.0, "el cuadro no se toca")
	player.global_position = Vector3(painting.x, 0.0, painting.z + 2.0)
	await _wait(0.1)
	player.steer_look(painting, 1.0)
	await _wait(2.5)
	_check(screen_fx.aberration == 0.0 and player.controls_enabled, "antes de 3 s no hay transición")
	await _wait(1.3)
	_check(screen_fx.aberration > 0.0 and player.controls_enabled, "a los 3 s empieza la transición, aún con control")
	await _snap("05_hold")
	player.steer_look(painting + Vector3(6.0, 0.0, 0.0), 1.0)
	await _wait(0.8)
	_check(screen_fx.aberration == 0.0 and _level() == prologue and player.controls_enabled, "apartar la vista corta la transición")
	player.steer_look(painting, 1.0)
	await _wait(4.7)
	_check(not player.controls_enabled, "sostener la mirada 4,5 s empieza la caída")
	await _wait(0.5)
	await _snap("06_fall_a")
	await _wait(0.6)
	await _snap("07_fall_b")
	await _wait(0.5)
	await _snap("08_fall_c")
	await _wait(2.4)
	var level1: Node = _level()
	_check(level1.scene_file_path == Game.LEVEL_1_SCENE, "Nivel 1 cargado tras la caída")
	player = level1.get_node("Player")
	hud = level1.get_node("Hud")
	overlay = hud.get_node("DocumentOverlay")
	await _wait(0.7)
	await _snap("09_landing")
	await _wait(1.3)
	_check(player.controls_enabled and player.sprint_enabled, "Nivel 1 con control y sprint")
	_check(not player.flashlight.available, "sin linterna al llegar")

	var flashlight: Vector3 = level1.call("marker", "flashlight")
	player.global_position = flashlight + Vector3(-5.0, -flashlight.y, 3.0)
	player.steer_look(flashlight, 1.0)
	await _wait(0.3)
	await _snap("10_reception")
	await _focus_and_press(level1, Vector3(flashlight.x, 0.0, flashlight.z + 1.0), flashlight, "la linterna")
	await _wait(0.3)
	_check(player.flashlight.available and player.flashlight.is_on, "linterna recogida y encendida")
	await _snap("11_flashlight")

	for id: String in ["d04", "d05", "d06"]:
		var target: Vector3 = level1.call("marker", id)
		var offset: Vector3 = {"d04": Vector3(0.0, 0.0, 1.2), "d05": Vector3(-0.9, 0.0, 0.9), "d06": Vector3(0.0, 0.0, -1.0)}[id]
		await _focus_and_press(level1, Vector3(target.x, 0.0, target.z) + offset, target, id)
		await _wait(0.2)
		_check(overlay.visible and overlay.document != null and String(overlay.document.id).to_lower() == id, "se lee %s" % id)
		await _wait(0.4)
		overlay.close()
		await _wait(0.1)
		await _snap("12_" + id)

	# Pasillo en bucle: cruzar el disparador hacia el norte devuelve tres celdas atrás.
	var trigger: Vector3 = level1.call("marker", "loop_trigger")
	player.global_position = trigger + Vector3(0.0, 0.0, 0.5)
	await _wait(0.1)
	player.global_position = trigger + Vector3(0.0, 0.0, -0.3)
	await _wait(0.1)
	_check(player.global_position.z > trigger.z + 4.0, "el pasillo en bucle devuelve al jugador (z=%.1f)" % player.global_position.z)

	var letter: Vector3 = level1.call("marker", "letter")
	await _focus_and_press(level1, Vector3(letter.x, 0.0, letter.z - 1.5), letter, "la letra N")
	await _wait(1.0)
	await _snap("13_letter_hold")
	await _wait(0.8)
	_check(not level1.get_node("Player").controls_enabled or level1.get("_letter_taken"), "la letra se recoge tras 1,5 s")
	await _wait(1.3)
	await _snap("14_taken")
	await _wait(3.0)
	await _snap("15_contamination")
	await _wait(8.2)
	await _snap("16_end_card")
	_check(hud.get_node("EndCard").visible, "tarjeta final visible")
	hud.get_node("EndCard/Lines/MenuButton").pressed.emit()
	await _wait(0.6)
	_check(_level().scene_file_path == Game.MENU_SCENE, "vuelve al menú")
