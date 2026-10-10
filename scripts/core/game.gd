extends Node
## Autoload `Game`: flujo entre escenas (menú → prólogo → niveles → final), ajustes,
## perfil de dificultad, checkpoints y muerte/reintento (docs/12 §4 y §10, docs/13 §6–§8).

signal scene_changing(path: String)
signal settings_changed
signal difficulty_changed
## Leyenda de sonido para quien juega sin auriculares (docs/13 §8). La pinta el HUD.
signal caption_requested(text: String, duration: float)

const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const PROLOGUE_SCENE: String = "res://scenes/levels/prologue.tscn"
const LEVEL_1_SCENE: String = "res://scenes/levels/level1.tscn"
const LEVEL_2_SCENE: String = "res://scenes/levels/level2.tscn"
const LEVEL_3_SCENE: String = "res://scenes/levels/level3.tscn"
const LEVEL_4_SCENE: String = "res://scenes/levels/level4.tscn"
const ENDING_SCENE: String = "res://scenes/levels/ending.tscn"
const DEATH_SCREEN: String = "res://scenes/ui/death_screen.tscn"
const LEVEL_ORDER: Array[String] = [PROLOGUE_SCENE, LEVEL_1_SCENE, LEVEL_2_SCENE, LEVEL_3_SCENE, LEVEL_4_SCENE, ENDING_SCENE]
const SAVE_PATH: String = "user://noho.cfg"
const PROMO_CODE: String = "VOLVISTE10"
const BRAND_URL: String = "https://lovenoho.com"

const DEFAULT_SETTINGS: Dictionary = {
	"reduced_camera_motion": false,
	"head_bob": true,
	"invert_y": false,
	"sensitivity": 1.0,
	"vibration": true,
	"sound_captions": false,
	"master_volume": 1.0,
	"touch_opacity": 0.35,
	"touch_scale": 1.0,
	"difficulty": Difficulty.Id.NORMAL,
}

## Epitafios de calaverita para la pantalla de muerte (voz grabada, docs/11 §4).
const EPITAPHS: Array[String] = [
	"Aquí quedó quien miró de frente\nlo que pedía no ser visto.",
	"Corrió sobre el agua\ny el agua avisó.",
	"Tanto alumbró el pasillo\nque el pasillo lo encontró.",
	"No lo alcanzó el olvido:\nlo alcanzó quien lo padece.",
	"Dejó la luz prendida\ny alguien vino a apagarla.",
]

var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
## Perfil activo. Cambia solo en un checkpoint (docs/12 §4.3), nunca en mitad de un tramo.
var difficulty: Difficulty = Difficulty.make(Difficulty.Id.NORMAL)
## Color con el que arranca el fundido de entrada de la siguiente escena (docs/14 §7).
var fade_in_color: Color = Color.BLACK
var checkpoint_scene: String = ""
var checkpoint_id: String = ""
var deaths_in_segment: int = 0
var is_dead: bool = false

## Elimina head-bob, roll y oscilaciones en todo el juego (docs/13 §4).
var reduced_camera_motion: bool:
	get:
		return bool(settings["reduced_camera_motion"])
	set(value):
		set_setting("reduced_camera_motion", value)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	difficulty = Difficulty.make(int(settings["difficulty"]) as Difficulty.Id)
	_apply_volume()


# --- Ajustes -------------------------------------------------------------------------------

func setting(key: String) -> Variant:
	return settings.get(key, DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	if settings.get(key) == value:
		return
	settings[key] = value
	if key == "master_volume":
		_apply_volume()
	_save()
	settings_changed.emit()


## Elegir perfil: fuera de partida surte efecto ya; en partida, en el siguiente checkpoint.
func select_difficulty(id: Difficulty.Id) -> void:
	set_setting("difficulty", id)
	if not in_run():
		_apply_difficulty()


func selected_difficulty() -> Difficulty.Id:
	return int(settings["difficulty"]) as Difficulty.Id


func in_run() -> bool:
	var scene: Node = get_tree().current_scene
	return scene != null and scene.scene_file_path in LEVEL_ORDER


# --- Flujo ---------------------------------------------------------------------------------

func start_new_game() -> void:
	checkpoint_scene = ""
	checkpoint_id = ""
	deaths_in_segment = 0
	_apply_difficulty()
	_save()
	goto_scene(PROLOGUE_SCENE)


func has_save() -> bool:
	return not checkpoint_scene.is_empty() and ResourceLoader.exists(checkpoint_scene)


func continue_game() -> void:
	if not has_save():
		start_new_game()
		return
	_apply_difficulty()
	goto_scene(checkpoint_scene)


func return_to_menu() -> void:
	goto_scene(MENU_SCENE)


## Pasa a la escena siguiente de `LEVEL_ORDER` y deja el checkpoint en su inicio.
func next_level(from_color: Color = Color.BLACK) -> void:
	var current: String = get_tree().current_scene.scene_file_path
	var index: int = LEVEL_ORDER.find(current)
	var target: String = LEVEL_ORDER[index + 1] if index >= 0 and index + 1 < LEVEL_ORDER.size() else MENU_SCENE
	if target != MENU_SCENE and not ResourceLoader.exists(target):
		target = MENU_SCENE
	if target in LEVEL_ORDER:
		checkpoint_scene = target
		checkpoint_id = ""
		deaths_in_segment = 0
		_apply_difficulty()
		_save()
	goto_scene(target, from_color)


func goto_scene(path: String, from_color: Color = Color.BLACK) -> void:
	fade_in_color = from_color
	is_dead = false
	get_tree().paused = false
	scene_changing.emit(path)
	get_tree().change_scene_to_file.call_deferred(path)


## Fin de la partida (pantalla de resolución): borra el progreso guardado.
func finish_game() -> void:
	checkpoint_scene = ""
	checkpoint_id = ""
	_save()


# --- Checkpoints y muerte ------------------------------------------------------------------

## Autosave silencioso al inicio de un tramo. `id` es el sufijo del marcador `cp_<id>` del nivel.
func set_checkpoint(id: String) -> void:
	var scene: String = get_tree().current_scene.scene_file_path
	if checkpoint_scene == scene and checkpoint_id == id:
		return
	checkpoint_scene = scene
	checkpoint_id = id
	deaths_in_segment = 0
	_apply_difficulty()
	_save()


## Checkpoint con el que debe arrancar la escena actual ("" = inicio del nivel).
func current_checkpoint() -> String:
	var scene: Node = get_tree().current_scene
	if scene != null and scene.scene_file_path == checkpoint_scene:
		return checkpoint_id
	return ""


## La entidad capturó al jugador: negro, epitafio y REINTENTAR (docs/13 §6.3).
func player_caught() -> void:
	if is_dead:
		return
	is_dead = true
	deaths_in_segment += 1
	if ResourceLoader.exists(DEATH_SCREEN):
		var screen: Node = (load(DEATH_SCREEN) as PackedScene).instantiate()
		get_tree().root.add_child(screen)
	else:
		retry()


func random_epitaph() -> String:
	return EPITAPHS[randi() % EPITAPHS.size()]


func retry() -> void:
	var scene: String = get_tree().current_scene.scene_file_path
	goto_scene(scene)


## Regla de compasión (docs/12 §4.5): factor sobre el umbral de persecución.
func chase_threshold_factor() -> float:
	if deaths_in_segment >= difficulty.compassion_deaths:
		return 1.0 + difficulty.compassion_bonus
	return 1.0


## Tras 3 muertes seguidas en el tramo, los pétalos marcan el camino 10 s (docs/13 §7).
func wants_petal_hint() -> bool:
	return deaths_in_segment >= 3


func caption(text: String, duration: float = 3.0) -> void:
	if bool(settings["sound_captions"]):
		caption_requested.emit(text, duration)


func vibrate(milliseconds: int) -> void:
	if bool(settings["vibration"]) and DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld(milliseconds)


# --- Persistencia --------------------------------------------------------------------------

func _apply_difficulty() -> void:
	var id: Difficulty.Id = selected_difficulty()
	if difficulty.id == id:
		return
	difficulty = Difficulty.make(id)
	difficulty_changed.emit()


func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(float(settings["master_volume"]), 0.0001, 1.0)))


func _save() -> void:
	var file: ConfigFile = ConfigFile.new()
	for key: String in settings:
		file.set_value("settings", key, settings[key])
	file.set_value("progress", "scene", checkpoint_scene)
	file.set_value("progress", "checkpoint", checkpoint_id)
	file.save(SAVE_PATH)


func _load() -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return
	for key: String in DEFAULT_SETTINGS:
		settings[key] = file.get_value("settings", key, DEFAULT_SETTINGS[key])
	checkpoint_scene = file.get_value("progress", "scene", "")
	checkpoint_id = file.get_value("progress", "checkpoint", "")
