extends Node
## Prueba de la interfaz: menú, dificultad, opciones, pausa, muerte, resolución,
## leyendas de sonido y documentos. Uso:
##   tools/run_godot.sh --headless --path . res://tools/debug/ui_test.tscn
## Con ventana (sin --headless) guarda capturas en builds/ui_*.png.
## No deja basura en `user://noho.cfg`: restaura ajustes y guardado al terminar.

var _fails: int = 0
## Evita que una recarga accidental de esta escena relance la prueba en bucle.
static var _started: bool = false
var _options_closed: bool = false
var _reading_started: bool = false
var _reading_finished: bool = false
var _settings_backup: Dictionary = {}
var _checkpoint_scene: String = ""
var _checkpoint_id: String = ""
var _deaths: int = 0
var _had_config: bool = false
var _config_bytes: PackedByteArray = PackedByteArray()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _started:
		print("UI TEST skip (escena recargada)")
		get_tree().quit(0)
		return
	_started = true
	_backup_state()
	await get_tree().process_frame
	await _run()
	_restore_state()
	print("UI TEST %s (%d fallos)" % ["OK" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(_fails)


func _check(condition: bool, label: String) -> void:
	print(("OK   " if condition else "FAIL ") + label)
	if not condition:
		_fails += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Con ventana (sin --headless) guarda capturas en builds/.
func _snap(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/ui_%s.png" % label)


func _row(options: OptionsPanel, key: String) -> Node:
	return options.get_node("Center/Card/Margin/Column/Scroll/Rows/" + key)


# --- Casos ---------------------------------------------------------------------------------

func _run() -> void:
	await _test_menu()
	await _test_options()
	await _test_pause()
	await _test_death()
	await _test_resolution()
	await _test_captions()
	_test_documents()


## Menú: CONTINUAR según guardado y el selector de dificultad.
func _test_menu() -> void:
	var menu: MainMenu = (load(Game.MENU_SCENE) as PackedScene).instantiate() as MainMenu
	add_child(menu)
	await _wait(0.3)
	Game.checkpoint_scene = ""
	menu.refresh_continue()
	_check(not (menu.get_node("LeftColumn/ContinueButton") as Button).visible, "CONTINUAR oculto sin guardado")
	Game.checkpoint_scene = Game.LEVEL_1_SCENE
	Game.checkpoint_id = "t"
	menu.refresh_continue()
	_check((menu.get_node("LeftColumn/ContinueButton") as Button).visible, "CONTINUAR visible con guardado")
	_check((menu.get_node("LeftColumn/PlayButton") as Button).text == "JUGAR", "JUGAR sigue siendo el botón primario")
	await _snap("menu")

	var selector: DifficultySelector = menu.get_node("LeftColumn/DifficultySelector")
	selector.press_segment(0)
	_check(Game.selected_difficulty() == Difficulty.Id.EASY, "el selector cambia a Casual")
	selector.press_segment(1)
	_check(Game.selected_difficulty() == Difficulty.Id.NORMAL, "el selector cambia a Equilibrio")
	selector.press_segment(2)
	_check(Game.selected_difficulty() == Difficulty.Id.HARD, "el selector cambia a Pesadilla")
	menu.queue_free()
	await _wait(0.1)


## Panel de opciones: cada control escribe su ajuste en `Game`.
func _test_options() -> void:
	var options: OptionsPanel = (load("res://scenes/ui/options_panel.tscn") as PackedScene).instantiate() as OptionsPanel
	add_child(options)
	await _wait(0.2)
	options.show_touch_rows = true
	options.open()
	await _wait(0.2)
	_check(options.visible, "el panel de opciones se abre")

	var sensitivity: HSlider = _row(options, "sensitivity").get_node("Slider") as HSlider
	sensitivity.value = 1.5
	_check(is_equal_approx(float(Game.setting("sensitivity")), 1.5), "la sensibilidad se escribe al instante")

	var captions: CheckButton = _row(options, "sound_captions").get_node("Line/Check") as CheckButton
	captions.button_pressed = true
	_check(bool(Game.setting("sound_captions")), "las leyendas de sonido se escriben al instante")
	var motion: CheckButton = _row(options, "reduced_camera_motion").get_node("Line/Check") as CheckButton
	motion.button_pressed = true
	_check(bool(Game.setting("reduced_camera_motion")), "el movimiento reducido se escribe al instante")

	var volume: HSlider = _row(options, "master_volume").get_node("Slider") as HSlider
	volume.value = 0.8
	_check(is_equal_approx(float(Game.setting("master_volume")), 0.8), "el volumen general se escribe al instante")

	var opacity: HSlider = _row(options, "touch_opacity").get_node("Slider") as HSlider
	opacity.value = 0.55
	_check(is_equal_approx(float(Game.setting("touch_opacity")), 0.55), "la opacidad táctil se escribe al instante")
	var scale: HSlider = _row(options, "touch_scale").get_node("Slider") as HSlider
	scale.value = 1.2
	_check(is_equal_approx(float(Game.setting("touch_scale")), 1.2), "el tamaño táctil se escribe al instante")
	await _snap("options")

	_options_closed = false
	options.closed.connect(_on_options_closed)
	options.close()
	await _wait(0.1)
	_check(_options_closed and not options.visible, "el panel de opciones se cierra y emite closed")
	options.queue_free()
	await _wait(0.1)


func _on_options_closed() -> void:
	_options_closed = true


func _on_reading_started(_document: DocumentData) -> void:
	_reading_started = true


func _on_reading_finished(_document: DocumentData) -> void:
	_reading_finished = true


## Pausa: abre, congela, atenúa el audio al 10 % y lo restaura al reanudar.
func _test_pause() -> void:
	Game.set_setting("master_volume", 0.8)
	await _wait(0.1)
	var pause: PauseMenu = (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate() as PauseMenu
	add_child(pause)
	await _wait(0.2)
	pause.pause_game()
	await _wait(0.5)
	_check(get_tree().paused, "la pausa congela el árbol")
	_check(pause.visible, "la pausa muestra su tarjeta")
	var ducked: float = AudioServer.get_bus_volume_db(0)
	_check(absf(ducked - linear_to_db(0.08)) < 0.6, "el audio baja al 10 %% (%.1f dB)" % ducked)

	# El selector de la pausa también cambia el perfil.
	var selector: DifficultySelector = pause.get_node("Center/Card/Margin/Column/DifficultySelector")
	selector.press_segment(1)
	_check(Game.selected_difficulty() == Difficulty.Id.NORMAL, "el selector de la pausa cambia el perfil")
	_check((pause.get_node("Center/Card/Margin/Column/DifficultyNote") as Label).text.contains("siguiente tramo"), "la pausa avisa del efecto diferido")
	await _snap("pause")

	pause.resume_game()
	await _wait(0.5)
	_check(not get_tree().paused, "reanudar descongela el árbol")
	_check(absf(AudioServer.get_bus_volume_db(0) - linear_to_db(0.8)) < 0.6, "el audio se restaura al reanudar")
	pause.queue_free()
	await _wait(0.1)


## Muerte: `Game.player_caught()` la instancia, espera 0,4 s y REINTENTAR recarga la escena.
func _test_death() -> void:
	# La recarga de REINTENTAR se mide contra un menú puesto como escena actual.
	# La escena actual debe ser hija directa de la raíz (exigencia de SceneTree).
	var probe: Control = (load(Game.MENU_SCENE) as PackedScene).instantiate() as Control
	get_tree().root.add_child(probe)
	await _wait(0.2)
	get_tree().current_scene = probe
	var probe_id: int = probe.get_instance_id()
	Game.is_dead = false
	Game.player_caught()
	await _wait(0.3)
	var death: CanvasLayer = get_tree().root.get_node_or_null("DeathScreen") as CanvasLayer
	_check(death != null, "player_caught() muestra la pantalla de muerte")
	if death == null:
		return
	var screen: Node = death
	_check((screen.get_node("Center/Column/RetryButton") as Button).text == "REINTENTAR", "hay un botón REINTENTAR")
	_check(not (screen.get_node("Center/Column/Epitaph") as Label).text.is_empty(), "muestra un epitafio")
	_check(not (screen.get_node("Center/Column/MenuLink") as Button).text.is_empty(), "hay enlace al menú")
	_check(screen.get_node_or_null("Brand/Name") != null, "marca NOHO mínima presente")
	_check(not bool(screen.call("accepts_input")), "la entrada espera 0,4 s")
	await _snap("death")
	await _wait(0.3)
	_check(bool(screen.call("accepts_input")), "a los 0,4 s ya acepta entrada")
	(screen.get_node("Center/Column/RetryButton") as Button).pressed.emit()
	await _wait(0.8)
	_check(not is_instance_valid(screen), "la pantalla de muerte se libera")
	_check(get_tree().current_scene != null, "queda una escena cargada")
	if get_tree().current_scene != null:
		_check(get_tree().current_scene.scene_file_path == Game.MENU_SCENE, "REINTENTAR recarga la escena actual")
		_check(get_tree().current_scene.get_instance_id() != probe_id, "REINTENTAR crea una instancia nueva")


## Resolución: código promo, `finish_game()` al abrir y botones sin bloquear.
func _test_resolution() -> void:
	Game.checkpoint_scene = Game.LEVEL_1_SCENE
	Game.checkpoint_id = "t"
	var resolution: ResolutionScreen = (load("res://scenes/ui/resolution_screen.tscn") as PackedScene).instantiate() as ResolutionScreen
	add_child(resolution)
	await _wait(0.2)
	resolution.open()
	await _wait(0.3)
	_check(Game.checkpoint_scene.is_empty(), "open() llama a finish_game() y borra el progreso")
	var code: Label = resolution.get_node("Center/Column/CodeRow/CodeLabel") as Label
	_check(code.text == Game.PROMO_CODE, "muestra el código promo %s" % Game.PROMO_CODE)
	_check((resolution.get_node("Center/Column/CodeRow/CopyButton") as Button).text == "COPIAR", "hay botón para copiar el código")
	_check((resolution.get_node("Center/Column/BrandLink") as LinkButton).text == "lovenoho.com", "hay enlace a la marca")
	for button: Button in [
		resolution.get_node("Center/Column/Buttons/ReplayButton") as Button,
		resolution.get_node("Center/Column/Buttons/MenuButton") as Button,
	]:
		_check(button.visible and not button.disabled, "botón '%s' sin bloquear" % button.text)
	# La captura espera a que el fundido de `open()` termine (0,8 s).
	await _wait(0.6)
	await _snap("resolution")
	(resolution.get_node("Center/Column/CodeRow/CopyButton") as Button).pressed.emit()
	await _wait(0.1)
	_check((resolution.get_node("Center/Column/CodeRow/CopyButton") as Button).text == "COPIADO", "copiar da feedback")
	resolution.queue_free()
	await _wait(0.1)


## Leyendas de sonido: solo se pintan con el ajuste activo; lectura avisa a los niveles.
func _test_captions() -> void:
	var hud: Hud = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate() as Hud
	add_child(hud)
	await _wait(0.2)
	var caption: Label = hud.get_node("Caption") as Label
	Game.set_setting("sound_captions", false)
	Game.caption("esto no debería verse", 1.0)
	_check(not caption.visible, "sin leyendas con el ajuste apagado")
	Game.set_setting("sound_captions", true)
	Game.caption("pasos que imitan tu ritmo — lejos", 1.0)
	await _wait(0.3)
	_check(caption.visible, "la leyenda aparece con el ajuste activo")
	_check(caption.text.contains("pasos"), "la leyenda muestra el texto pedido")

	_reading_started = false
	_reading_finished = false
	hud.reading_started.connect(_on_reading_started)
	hud.reading_finished.connect(_on_reading_finished)
	var overlay: DocumentOverlay = hud.get_node("DocumentOverlay") as DocumentOverlay
	var document: DocumentData = load("res://resources/documents/d07.tres") as DocumentData
	overlay.open(document)
	_check(_reading_started and hud.is_reading, "reading_started e is_reading al abrir un documento")
	overlay.close()
	_check(_reading_finished and not hud.is_reading, "reading_finished al cerrar el documento")
	hud.queue_free()
	await _wait(0.1)


## La bóveda D07–D15 carga como `DocumentData` con cuerpo.
func _test_documents() -> void:
	for index: int in range(7, 16):
		var path: String = "res://resources/documents/d%02d.tres" % index
		_check(ResourceLoader.exists(path), "%s existe" % path)
		var data: Resource = load(path)
		_check(data is DocumentData, "%s es DocumentData" % path)
		if data is DocumentData:
			var document: DocumentData = data as DocumentData
			_check(not document.body.strip_edges().is_empty(), "%s con cuerpo no vacío" % path)
			_check(String(document.id) == "D%02d" % index, "%s con su id" % path)


# --- Persistencia --------------------------------------------------------------------------

func _backup_state() -> void:
	_settings_backup = Game.settings.duplicate(true)
	_checkpoint_scene = Game.checkpoint_scene
	_checkpoint_id = Game.checkpoint_id
	_deaths = Game.deaths_in_segment
	_had_config = FileAccess.file_exists(Game.SAVE_PATH)
	if _had_config:
		var file: FileAccess = FileAccess.open(Game.SAVE_PATH, FileAccess.READ)
		if file != null:
			_config_bytes = file.get_buffer(file.get_length())


## Restaura ajustes, progreso y el archivo de guardado tal y como estaban.
func _restore_state() -> void:
	Game.settings = _settings_backup.duplicate(true)
	Game.checkpoint_scene = _checkpoint_scene
	Game.checkpoint_id = _checkpoint_id
	Game.deaths_in_segment = _deaths
	Game.is_dead = false
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(float(Game.setting("master_volume")), 0.0001, 1.0)))
	if _had_config:
		var file: FileAccess = FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_buffer(_config_bytes)
	elif FileAccess.file_exists(Game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.SAVE_PATH))
