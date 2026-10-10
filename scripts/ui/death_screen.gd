extends CanvasLayer
## Pantalla de muerte (docs/13 §6.3): negro, un epitafio de la voz grabada y REINTENTAR.
## `Game.player_caught()` la instancia en la raíz; se libera sola al reintentar o volver al menú.

## Antes de este tiempo no se acepta entrada: la captura tiene que asentar (docs/13 §7).
const INPUT_DELAY: float = 0.4
const ACCENT_BLUE: Color = Color("1f5fff")
const ACCENT_ORANGE: Color = Color("ff8a1f")

var _opened_at: int = 0
var _closing: bool = false

@onready var _epitaph: Label = $Center/Column/Epitaph
@onready var _retry_button: Button = $Center/Column/RetryButton
@onready var _menu_link: Button = $Center/Column/MenuLink


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_at = Time.get_ticks_msec()
	# La muerte siempre deja el ratón a la vista: hay que poder pulsar REINTENTAR.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_epitaph.text = Game.random_epitaph()
	# El epitafio se queda con la tipografía manuscrita de la escena (voz grabada).
	_apply_spacing(_retry_button, 4)
	_apply_spacing(_menu_link, 2)
	_style_menu_button(_retry_button)
	_style_link(_menu_link)
	_retry_button.pressed.connect(_retry)
	_menu_link.pressed.connect(_to_menu)
	_retry_button.call_deferred("grab_focus")


## Tocar cualquier parte —o pulsar Enter, Espacio o E— reintenta.
func _unhandled_input(event: InputEvent) -> void:
	if _closing or not accepts_input():
		return
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.is_pressed() and not key.is_echo() and key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			get_viewport().set_input_as_handled()
			_retry()
	elif (event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventJoypadButton) and event.is_pressed():
		get_viewport().set_input_as_handled()
		_retry()


## Cierto cuando ya se puede pulsar REINTENTAR (tras la espera de la captura).
func accepts_input() -> bool:
	return Time.get_ticks_msec() - _opened_at >= int(INPUT_DELAY * 1000.0)


## Suelta la pantalla y recarga la escena actual (docs/12 §10).
func _retry() -> void:
	if _closing:
		return
	_closing = true
	queue_free()
	Game.retry()


func _to_menu() -> void:
	if _closing:
		return
	_closing = true
	queue_free()
	Game.return_to_menu()


# --- Estilo ------------------------------------------------------------------------------

func _apply_spacing(control: Control, glyph_px: int) -> void:
	var variation := FontVariation.new()
	variation.base_font = preload("res://assets/fonts/Nunito.ttf")
	variation.spacing_glyph = glyph_px
	control.add_theme_font_override("font", variation)


## Igual que el menú principal: plano, con barra naranja al enfocar.
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


## Enlace discreto, subordinado al botón principal.
func _style_link(button: Button) -> void:
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.45))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", ACCENT_BLUE)
