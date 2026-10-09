extends Node
## Autoload `Game`: flujo entre escenas (menú → prólogo → niveles) y ajustes de sesión.

signal scene_changing(path: String)

const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const PROLOGUE_SCENE: String = "res://scenes/levels/prologue.tscn"
const LEVEL_1_SCENE: String = "res://scenes/levels/level1.tscn"

## Elimina head-bob, roll y oscilaciones en todo el juego (docs/13 §4).
var reduced_camera_motion: bool = false
## Color con el que arranca el fundido de entrada de la siguiente escena (docs/14 §7).
var fade_in_color: Color = Color.BLACK


func start_new_game() -> void:
	goto_scene(PROLOGUE_SCENE)


func return_to_menu() -> void:
	goto_scene(MENU_SCENE)


func goto_scene(path: String, from_color: Color = Color.BLACK) -> void:
	fade_in_color = from_color
	get_tree().paused = false
	scene_changing.emit(path)
	get_tree().change_scene_to_file.call_deferred(path)
