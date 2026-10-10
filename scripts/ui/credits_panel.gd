class_name CreditsPanel
extends Control
## Créditos: equipo y resumen de licencias, con desplazamiento (docs/06).
## Lee `assets/CREDITS.md` si el empaquetado lo deja; si no, texto fijo equivalente.

signal closed

const CREDITS_PATH: String = "res://assets/CREDITS.md"

## Resumen usado cuando el registro completo no se puede leer (export Web/Android).
const LICENSE_SUMMARY: String = """Licencias
Tipografías Nunito, VT323 y Caveat — SIL Open Font License 1.1 (Google Fonts).
Audio y texturas generados para el proyecto — uso comercial según el proveedor.
Modelos low-poly, shaders y geometría — propios del proyecto.
"""

const TEAM_SUMMARY: String = """BACKROOMS NOHO

Equipo
Dirección, diseño, guion y código — equipo Backrooms NOHO.
Narrativa y bóveda de documentos — equipo Backrooms NOHO.
Modelos, texturas y audio — producción propia del proyecto.
"""

@onready var _text: RichTextLabel = $Center/Card/Margin/Column/Scroll/Text
@onready var _close_button: Button = $Center/Card/Margin/Column/CloseButton


func _ready() -> void:
	visible = false
	_style_card()
	_style_menu_button(_close_button)
	_close_button.pressed.connect(close)
	_text.text = _compose_text()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_text.text = _compose_text()
	visible = true
	_close_button.call_deferred("grab_focus")


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Equipo + registro de licencias (completo si se puede leer, resumen si no).
func _compose_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append(TEAM_SUMMARY.strip_edges())
	parts.append("")
	if ResourceLoader.exists(CREDITS_PATH) or FileAccess.file_exists(CREDITS_PATH):
		var file: FileAccess = FileAccess.open(CREDITS_PATH, FileAccess.READ)
		if file != null:
			parts.append(file.get_as_text().strip_edges())
			return "\n\n".join(parts)
	parts.append(LICENSE_SUMMARY.strip_edges())
	return "\n\n".join(parts)


# --- Estilo ------------------------------------------------------------------------------

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
