class_name OptionsPanel
extends Control
## Panel de opciones reutilizable por el menú y la pausa (docs/13 §4 y §8).
## Cada cambio se escribe al instante en `Game`; nada espera a un botón de aplicar.

signal closed

## Rango de sensibilidad de cámara (docs/13 §4).
const SENSITIVITY_MIN: float = 0.3
const SENSITIVITY_MAX: float = 2.0
const TOUCH_OPACITY_MIN: float = 0.15
const TOUCH_SCALE_MIN: float = 0.7
const TOUCH_SCALE_MAX: float = 1.6

## Fuerza a mostrar las filas táctiles (fuera de un dispositivo táctil, para pruebas).
var show_touch_rows: bool = false

## Clave de ajuste → etiqueta con la que se muestra su valor.
var _value_labels: Dictionary[String, Label] = {}

@onready var _rows: VBoxContainer = $Center/Card/Margin/Column/Scroll/Rows
@onready var _close_button: Button = $Center/Card/Margin/Column/CloseButton


func _ready() -> void:
	visible = false
	_style_card()
	_style_menu_button(_close_button)
	_close_button.pressed.connect(close)
	_add_toggle("reduced_camera_motion", "Movimiento de cámara reducido", false)
	_add_toggle("head_bob", "Balanceo al caminar", false)
	_add_toggle("invert_y", "Invertir eje Y", false)
	_add_slider("sensitivity", "Sensibilidad de cámara", SENSITIVITY_MIN, SENSITIVITY_MAX, 0.05, false)
	_add_toggle("vibration", "Vibración", false)
	_add_toggle("sound_captions", "Leyendas de sonido", false)
	_add_slider("master_volume", "Volumen general", 0.0, 1.0, 0.05, false)
	_add_slider("touch_opacity", "Opacidad de controles táctiles", TOUCH_OPACITY_MIN, 1.0, 0.05, true)
	_add_slider("touch_scale", "Tamaño de controles táctiles", TOUCH_SCALE_MIN, TOUCH_SCALE_MAX, 0.05, true)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Muestra el panel con los valores actuales.
func open() -> void:
	refresh()
	visible = true
	_close_button.call_deferred("grab_focus")


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Sincroniza con `Game` y muestra u oculta las filas táctiles.
func refresh() -> void:
	for row: Node in _rows.get_children():
		var key: String = row.name
		row.visible = _row_visible(key)
		var check: CheckButton = row.get_node_or_null("Line/Check") as CheckButton
		if check != null:
			check.set_pressed_no_signal(bool(Game.setting(key)))
		var slider: HSlider = row.get_node_or_null("Slider") as HSlider
		if slider != null:
			slider.set_value_no_signal(float(Game.setting(key)))
		_update_value_label(key)


## Las filas de controles táctiles solo interesan en táctil (docs/13 §8).
func _row_visible(key: String) -> bool:
	if key != "touch_opacity" and key != "touch_scale":
		return true
	return show_touch_rows or _is_touch_device()


# --- Filas -------------------------------------------------------------------------------

func _add_toggle(key: String, label: String, touch_only: bool) -> void:
	var row: VBoxContainer = _new_row(key, touch_only)
	var line: HBoxContainer = HBoxContainer.new()
	line.name = "Line"
	var caption: Label = _new_label(label)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var check: CheckButton = CheckButton.new()
	check.name = "Check"
	check.focus_mode = Control.FOCUS_ALL
	check.button_pressed = bool(Game.setting(key))
	check.toggled.connect(_on_toggle.bind(key))
	line.add_child(caption)
	line.add_child(check)
	row.add_child(line)
	_rows.add_child(row)


func _add_slider(key: String, label: String, low: float, high: float, step: float, touch_only: bool) -> void:
	var row: VBoxContainer = _new_row(key, touch_only)
	var line: HBoxContainer = HBoxContainer.new()
	line.name = "Line"
	var caption: Label = _new_label(label)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_label: Label = _new_label("")
	value_label.name = "Value"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(64.0, 0.0)
	_value_labels[key] = value_label
	var slider: HSlider = HSlider.new()
	slider.name = "Slider"
	slider.focus_mode = Control.FOCUS_ALL
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = float(Game.setting(key))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider.bind(key))
	line.add_child(caption)
	line.add_child(value_label)
	row.add_child(line)
	row.add_child(slider)
	_rows.add_child(row)
	_update_value_label(key)


func _new_row(key: String, touch_only: bool) -> VBoxContainer:
	var row: VBoxContainer = VBoxContainer.new()
	row.name = key
	row.add_theme_constant_override("separation", 4)
	row.visible = not touch_only or _row_visible(key)
	return row


func _new_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	return label


# --- Cambios -----------------------------------------------------------------------------

func _on_toggle(pressed: bool, key: String) -> void:
	Game.set_setting(key, pressed)


func _on_slider(value: float, key: String) -> void:
	Game.set_setting(key, value)
	_update_value_label(key)


func _update_value_label(key: String) -> void:
	if not _value_labels.has(key):
		return
	var value: float = float(Game.setting(key))
	if key == "master_volume" or key == "touch_opacity":
		_value_labels[key].text = "%d %%" % roundi(value * 100.0)
	else:
		_value_labels[key].text = String.num(value, 2).replace(".", ",")


# --- Estilo ------------------------------------------------------------------------------

## Tarjeta casi negra con borde tenue, como la pausa.
func _style_card() -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = Color(0.02, 0.02, 0.03, 0.96)
	card.border_width_left = 1
	card.border_width_right = 1
	card.border_width_top = 1
	card.border_width_bottom = 1
	card.border_color = Color(1.0, 1.0, 1.0, 0.14)
	card.corner_radius_top_left = 8
	card.corner_radius_top_right = 8
	card.corner_radius_bottom_left = 8
	card.corner_radius_bottom_right = 8
	($Center/Card as PanelContainer).add_theme_stylebox_override("panel", card)


## Mismo estilo plano que el menú principal.
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


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
