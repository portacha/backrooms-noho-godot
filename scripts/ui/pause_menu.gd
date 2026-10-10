class_name PauseMenu
extends CanvasLayer
## Pausa real de un jugador offline: congela todo y atenúa (docs/13 §6.2).
## Reanudar · Opciones · Menú principal. Nunca redirige a la marca.

signal paused
signal resumed

## El audio baja a esta fracción del volumen general mientras se pausa (docs/13 §6.2).
const DUCK_RATIO: float = 0.1
const DUCK_TIME: float = 0.3

## Los niveles lo apagan durante cinemáticas.
var can_pause: bool = true

var _is_paused: bool = false
var _volume_tween: Tween = null

@onready var _resume_button: Button = $Center/Card/Margin/Column/ResumeButton
@onready var _options_button: Button = $Center/Card/Margin/Column/OptionsButton
@onready var _menu_button: Button = $Center/Card/Margin/Column/MenuButton
@onready var _title: Label = $Center/Card/Margin/Column/Title
@onready var _card: PanelContainer = $Center/Card
@onready var _options_panel: OptionsPanel = $OptionsPanel
@onready var _touch_button: Button = $TouchPauseButton


func _ready() -> void:
	visible = false
	_style_card()
	_apply_spacing(_title, 8)
	for button: Button in [_resume_button, _options_button, _menu_button]:
		_apply_spacing(button, 3)
		_style_menu_button(button)
	_resume_button.pressed.connect(resume_game)
	_options_button.pressed.connect(_on_options_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_options_panel.closed.connect(_on_options_closed)
	Game.settings_changed.connect(_on_settings_changed)
	_touch_button.pressed.connect(pause_game)
	_refresh_touch_button()


func _unhandled_input(event: InputEvent) -> void:
	if not can_pause or _options_panel.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		# Que nadie más reaccione a este Esc.
		get_viewport().set_input_as_handled()


## Alterna pausa y reanudación; lo usa la verificación y el botón táctil.
func toggle_pause() -> void:
	if _is_paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	if _is_paused or not can_pause:
		return
	_is_paused = true
	get_tree().paused = true
	visible = true
	_refresh_touch_button()
	_duck_audio()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_resume_button.call_deferred("grab_focus")
	paused.emit()


func resume_game() -> void:
	if not _is_paused:
		return
	_is_paused = false
	get_tree().paused = false
	visible = false
	_refresh_touch_button()
	_restore_audio()
	# En táctil no hay cursor que capturar.
	if not _is_touch_device():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	resumed.emit()


## Cierra el panel de opciones y vuelve a la tarjeta de pausa.
func _on_options_pressed() -> void:
	_card.visible = false
	_options_panel.open()


func _on_options_closed() -> void:
	_card.visible = true
	_resume_button.call_deferred("grab_focus")


## Si cambia el volumen general con la pausa puesta, sigue atenuado.
func _on_settings_changed() -> void:
	if _is_paused:
		_set_master_db(_ducked_db())


# --- Audio --------------------------------------------------------------------------------

func _master_linear() -> float:
	return clampf(float(Game.setting("master_volume")), 0.0001, 1.0)


func _ducked_db() -> float:
	return linear_to_db(_master_linear() * DUCK_RATIO)


func _duck_audio() -> void:
	_tween_volume(_ducked_db())


func _restore_audio() -> void:
	_tween_volume(linear_to_db(_master_linear()))


## El tween se procesa en pausa (el menú está en modo ALWAYS).
func _tween_volume(target_db: float) -> void:
	if _volume_tween != null:
		_volume_tween.kill()
	var from_db: float = AudioServer.get_bus_volume_db(0)
	_volume_tween = create_tween()
	_volume_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_volume_tween.tween_method(_set_master_db, from_db, target_db, DUCK_TIME)


func _set_master_db(db: float) -> void:
	AudioServer.set_bus_volume_db(0, db)


# --- Estilo y utilidades -----------------------------------------------------------------

## Botón táctil solo fuera de la pausa y solo en táctil.
func _refresh_touch_button() -> void:
	_touch_button.visible = _is_touch_device() and not _is_paused


## Tarjeta casi negra con borde blanco tenue; sin el gris de serie.
func _style_card() -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = Color(0.02, 0.02, 0.03, 0.94)
	card.border_width_left = 1
	card.border_width_right = 1
	card.border_width_top = 1
	card.border_width_bottom = 1
	card.border_color = Color(1.0, 1.0, 1.0, 0.14)
	card.corner_radius_top_left = 8
	card.corner_radius_top_right = 8
	card.corner_radius_bottom_left = 8
	card.corner_radius_bottom_right = 8
	_card.add_theme_stylebox_override("panel", card)


## Mismo estilo plano que el menú principal (código duplicado a propósito).
func _style_menu_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.0, 0.0, 0.0, 0.35)
	normal.content_margin_left = 22.0
	normal.content_margin_right = 22.0
	normal.content_margin_top = 12.0
	normal.content_margin_bottom = 12.0
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 1.0, 1.0, 0.10)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(1.0, 0.54, 0.11, 0.25)
	var focus := hover.duplicate() as StyleBoxFlat
	focus.border_width_left = 4
	focus.border_color = Color("ff8a1f")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)


func _apply_spacing(control: Control, glyph_px: int) -> void:
	var variation := FontVariation.new()
	variation.base_font = preload("res://assets/fonts/Nunito.ttf")
	variation.spacing_glyph = glyph_px
	control.add_theme_font_override("font", variation)


func _on_menu_pressed() -> void:
	Game.return_to_menu()


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
