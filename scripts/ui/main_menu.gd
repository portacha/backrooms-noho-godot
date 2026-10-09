class_name MainMenu
extends Control
## Menú principal: portada viva, JUGAR inmediato y marca mínima (docs/13 §6.1, docs/06).

## Azul, blanco y naranja del logotipo NOHO; nada más.
const ACCENT_BLUE: Color = Color("1f5fff")
const ACCENT_WHITE: Color = Color.WHITE
const ACCENT_ORANGE: Color = Color("ff8a1f")
const BRAND_URL: String = "https://lovenoho.com"

@onready var _background: TextureRect = $Background
@onready var _overline: Label = $LeftColumn/Overline
@onready var _title: Label = $LeftColumn/Title
@onready var _play_button: Button = $LeftColumn/PlayButton
@onready var _quit_button: Button = $LeftColumn/QuitButton
@onready var _brand_link: LinkButton = $BrandLink


func _ready() -> void:
	# El menú siempre se usa con ratón o táctil.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_spacing(_overline, 6)
	_apply_spacing(_title, 10)
	_apply_spacing(_play_button, 4)
	_apply_spacing(_quit_button, 4)
	_style_menu_button(_play_button)
	_style_menu_button(_quit_button)
	_overline.add_theme_color_override("font_color", ACCENT_ORANGE)
	_brand_link.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	_brand_link.add_theme_color_override("font_hover_color", ACCENT_WHITE)
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_brand_link.pressed.connect(_on_brand_pressed)
	# En Web no se puede salir y en móvil no tiene sentido: solo JUGAR.
	_quit_button.visible = not (_is_web() or _is_touch_device())
	# Foco inicial sin esperar a nada; JUGAR arranca al instante.
	_play_button.call_deferred("grab_focus")
	_start_background_drift()


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


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_brand_pressed() -> void:
	OS.shell_open(BRAND_URL)


func _is_web() -> bool:
	return OS.has_feature("web")


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
