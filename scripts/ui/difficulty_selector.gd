class_name DifficultySelector
extends HBoxContainer
## Selector segmentado de tres perfiles (docs/12 §4.3). Un toque cambia
## `Game.selected_difficulty()`; en partida el efecto llega en el siguiente tramo.

## Acento naranja del logotipo, igual que los botones del menú.
const ACCENT_ORANGE: Color = Color("ff8a1f")

## Se emite tras cambiar de perfil; `Game` ya queda actualizado.
signal difficulty_selected(id: Difficulty.Id)

var _segments: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	# Grupo exclusivo: solo un segmento puede quedar marcado.
	var group: ButtonGroup = ButtonGroup.new()
	group.allow_unpress = false
	for index: int in range(Difficulty.LABELS.size()):
		var button: Button = Button.new()
		button.name = "Segment%d" % index
		button.text = Difficulty.LABELS[index]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(120.0, 48.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_segment_pressed.bind(Difficulty.Id.values()[index]))
		_style_segment(button)
		add_child(button)
		_segments.append(button)
	refresh()


## Marca el perfil activo según `Game`; llamar al reabrir el panel.
func refresh() -> void:
	var active: Difficulty.Id = Game.selected_difficulty()
	for index: int in range(_segments.size()):
		_segments[index].set_pressed_no_signal(index == int(active))


## Útil para las pruebas: simula un toque sobre el segmento `index`.
func press_segment(index: int) -> void:
	if index >= 0 and index < _segments.size():
		_segments[index].pressed.emit()


func _on_segment_pressed(id: Difficulty.Id) -> void:
	Game.select_difficulty(id)
	refresh()
	difficulty_selected.emit(id)


## Segmento plano; el activo se marca con el naranja de marca.
func _style_segment(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.0, 0.0, 0.0, 0.35)
	normal.content_margin_left = 10.0
	normal.content_margin_right = 10.0
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 10.0
	normal.corner_radius_top_left = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_right = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 1.0, 1.0, 0.10)
	var active := normal.duplicate() as StyleBoxFlat
	active.bg_color = Color(1.0, 0.54, 0.11, 0.30)
	active.border_width_bottom = 3
	active.border_color = ACCENT_ORANGE
	var focus := hover.duplicate() as StyleBoxFlat
	focus.border_width_left = 3
	focus.border_color = ACCENT_ORANGE
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", active)
	button.add_theme_stylebox_override("hover_pressed", active)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
