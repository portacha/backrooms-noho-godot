class_name MainMenu
extends Control
## Menú principal: portada viva, JUGAR inmediato y marca mínima (docs/13 §6.1, docs/06).
## Debajo de JUGAR: CONTINUAR (si hay partida), dificultad, opciones y créditos.

## Azul, blanco y naranja del logotipo NOHO; nada más.
const ACCENT_BLUE: Color = Color("1f5fff")
const ACCENT_WHITE: Color = Color.WHITE
const ACCENT_ORANGE: Color = Color("ff8a1f")
const BRAND_URL: String = "https://lovenoho.com"

@onready var _background: TextureRect = $Background
@onready var _overline: Label = $LeftColumn/Overline
@onready var _title: Label = $LeftColumn/Title
@onready var _play_button: Button = $LeftColumn/PlayButton
@onready var _continue_button: Button = $LeftColumn/ContinueButton
@onready var _difficulty_selector: DifficultySelector = $LeftColumn/DifficultySelector
@onready var _options_button: Button = $LeftColumn/OptionsButton
@onready var _credits_button: Button = $LeftColumn/CreditsButton
@onready var _quit_button: Button = $LeftColumn/QuitButton
@onready var _options_panel: OptionsPanel = $OptionsPanel
@onready var _credits_panel: CreditsPanel = $CreditsPanel
@onready var _brand_link: LinkButton = $BrandLink


func _ready() -> void:
	# El menú siempre se usa con ratón o táctil.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_spacing(_overline, 6)
	_apply_spacing(_title, 10)
	for button: Button in [_play_button, _continue_button, _options_button, _credits_button, _quit_button]:
		_apply_spacing(button, 4)
		_style_menu_button(button)
	_overline.add_theme_color_override("font_color", ACCENT_ORANGE)
	_brand_link.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	_brand_link.add_theme_color_override("font_hover_color", ACCENT_WHITE)
	_play_button.pressed.connect(_on_play_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_brand_link.pressed.connect(_on_brand_pressed)
	_options_panel.closed.connect(_on_panel_closed)
	_credits_panel.closed.connect(_on_panel_closed)
	# En Web no se puede salir y en móvil no tiene sentido: solo JUGAR.
	_quit_button.visible = not (_is_web() or _is_touch_device())
	refresh_continue()
	# Foco inicial sin esperar a nada; JUGAR arranca al instante.
	_play_button.call_deferred("grab_focus")
	_start_background_drift()


## CONTINUAR solo aparece con partida guardada (docs/13 §8: retomar en <5 s).
func refresh_continue() -> void:
	_continue_button.visible = Game.has_save()


## Separa las letras con la fuente por defecto (fina y aireada).
func _apply_spacing(control: Control, glyph_px: int) -> void:
	var variation := FontVariation.new()
	variation.base_font = preload("res://assets/fonts/Nunito.ttf")
	variation.spacing_glyph = glyph_px
	control.add_theme_font_override("font", variation)


## Botón plano oscuro con barra naranja al enfocar; sin el gris de serie.
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
	focus.border_color = ACCENT_ORANGE
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", ACCENT_WHITE)
	button.add_theme_color_override("font_hover_color", ACCENT_WHITE)
	button.add_theme_color_override("font_pressed_color", ACCENT_WHITE)
	button.add_theme_color_override("font_focus_color", ACCENT_WHITE)


## Zoom muy lento en bucle para que la portada respire; no bloquea la entrada.
func _start_background_drift() -> void:
	await get_tree().process_frame
	if not is_instance_valid(_background):
		return
	_background.pivot_offset = _background.size * 0.5
	var tween := create_tween().set_loops()
	tween.set_parallel(true)
	tween.tween_property(_background, "scale", Vector2(1.06, 1.06), 24.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_background, "position", _background.position + Vector2(-14.0, 10.0), 24.0).set_trans(Tween.TRANS_SINE)


func _on_play_pressed() -> void:
	Game.start_new_game()


func _on_continue_pressed() -> void:
	Game.continue_game()


func _on_options_pressed() -> void:
	_options_panel.open()
	_set_menu_focusable(false)


func _on_credits_pressed() -> void:
	_credits_panel.open()
	_set_menu_focusable(false)


func _on_panel_closed() -> void:
	_set_menu_focusable(true)
	refresh_continue()
	_play_button.call_deferred("grab_focus")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_brand_pressed() -> void:
	OS.shell_open(BRAND_URL)


## Con un panel abierto, el tabulador no debe pasear por el menú de detrás.
func _set_menu_focusable(enabled: bool) -> void:
	for node: Node in _collect_controls($LeftColumn):
		(node as Control).focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _collect_controls(root: Control) -> Array[Control]:
	var result: Array[Control] = []
	for child: Node in root.get_children():
		var control: Control = child as Control
		if control == null:
			continue
		if control is Button:
			result.append(control)
		result.append_array(_collect_controls(control))
	return result


func _is_web() -> bool:
	return OS.has_feature("web")


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
