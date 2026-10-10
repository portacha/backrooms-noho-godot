class_name ResolutionScreen
extends CanvasLayer
## Pantalla de resolución (victoria): la marca es el premio, no el muro (docs/06, docs/13 §6.4).
## La instancia el final del juego, la añade a la raíz y llama a `open()`.

## Fundido de entrada (docs/13 §6.4: el silencio se rompe con el audio de marca).
const FADE_TIME: float = 0.8
const ACCENT_BLUE: Color = Color("1f5fff")
const ACCENT_ORANGE: Color = Color("ff8a1f")
const STING_PATH: String = "res://assets/audio/ambient/brand_sting.ogg"

var _closing: bool = false
var _copy_tween: Tween = null

@onready var _fade: ColorRect = $Fade
@onready var _code_label: Label = $Center/Column/CodeRow/CodeLabel
@onready var _copy_button: Button = $Center/Column/CodeRow/CopyButton
@onready var _brand_link: LinkButton = $Center/Column/BrandLink
@onready var _replay_button: Button = $Center/Column/Buttons/ReplayButton
@onready var _menu_button: Button = $Center/Column/Buttons/MenuButton
@onready var _sting: AudioStreamPlayer = $BrandSting


func _ready() -> void:
	_apply_spacing(_replay_button, 3)
	_apply_spacing(_menu_button, 3)
	_style_menu_button(_replay_button)
	_style_menu_button(_menu_button)
	_style_copy_button(_copy_button)
	_code_label.text = Game.PROMO_CODE
	_copy_button.pressed.connect(_on_copy_pressed)
	_brand_link.pressed.connect(_on_brand_pressed)
	_replay_button.pressed.connect(_on_replay_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_brand_link.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	_brand_link.add_theme_color_override("font_hover_color", Color.WHITE)


## Abre con fundido, borra el progreso guardado y suena el audio de marca si está.
func open() -> void:
	Game.finish_game()
	show()
	_fade.modulate.a = 1.0
	create_tween().tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
	_play_sting()
	_replay_button.call_deferred("grab_focus")


## Copia el código promo al portapapeles del dispositivo.
func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(Game.PROMO_CODE)
	_copy_button.text = "COPIADO"
	if _copy_tween != null:
		_copy_tween.kill()
	_copy_tween = create_tween()
	_copy_tween.tween_interval(1.6)
	_copy_tween.tween_callback(func() -> void: _copy_button.text = "COPIAR")


func _on_brand_pressed() -> void:
	OS.shell_open(Game.BRAND_URL)


func _on_replay_pressed() -> void:
	_close_and(Game.start_new_game)


func _on_menu_pressed() -> void:
	_close_and(Game.return_to_menu)


## Nada bloquea los botones: la pantalla se libera y el flujo sigue (docs/06).
func _close_and(action: Callable) -> void:
	if _closing:
		return
	_closing = true
	queue_free()
	action.call()


func _play_sting() -> void:
	if not ResourceLoader.exists(STING_PATH):
		return
	_sting.stream = load(STING_PATH) as AudioStream
	_sting.play()


# --- Estilo ------------------------------------------------------------------------------

func _apply_spacing(control: Control, glyph_px: int) -> void:
	var variation := FontVariation.new()
	variation.base_font = preload("res://assets/fonts/Nunito.ttf")
	variation.spacing_glyph = glyph_px
	control.add_theme_font_override("font", variation)


## Igual que el menú principal.
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
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)


## El código es lo único destacado junto al lockup: filete azul de marca.
func _style_copy_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(ACCENT_BLUE.r, ACCENT_BLUE.g, ACCENT_BLUE.b, 0.22)
	normal.content_margin_left = 14.0
	normal.content_margin_right = 14.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.border_width_bottom = 2
	normal.border_color = ACCENT_BLUE
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(ACCENT_BLUE.r, ACCENT_BLUE.g, ACCENT_BLUE.b, 0.40)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
