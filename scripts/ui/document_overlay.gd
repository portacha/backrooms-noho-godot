class_name DocumentOverlay
extends Control
## Overlay de lectura (docs/13 §5). La presentación depende del soporte del documento:
## hoja de papel, nota adhesiva, pared rayada o —si se lee en un terminal— un monitor viejo
## con un bloc de notas. Se cierra con cualquier botón.

signal opened(document: DocumentData)
signal closed(document: DocumentData)

## Evita que la misma pulsación que abre el documento lo cierre.
const CLOSE_GUARD_MSEC: int = 300
const TYPE_TIME: float = 0.7
const CURSOR_PERIOD: float = 0.5

const BODY_FONT: Font = preload("res://assets/fonts/nunito_regular.tres")
const HAND_FONT: Font = preload("res://assets/fonts/Caveat.ttf")

const PAPER_COLORS: Dictionary[DocumentData.Medium, Color] = {
	DocumentData.Medium.PAPER: Color(0.92, 0.92, 0.89),
	DocumentData.Medium.STICKY_NOTE: Color(0.95, 0.87, 0.47),
	DocumentData.Medium.WALL: Color(0.16, 0.15, 0.14),
}
const INK_COLORS: Dictionary[DocumentData.Medium, Color] = {
	DocumentData.Medium.PAPER: Color(0.1, 0.1, 0.12),
	DocumentData.Medium.STICKY_NOTE: Color(0.12, 0.12, 0.2),
	DocumentData.Medium.WALL: Color(0.82, 0.8, 0.74),
}

var document: DocumentData = null

var _opened_at: int = 0
var _cursor_time: float = 0.0
var _screen_text: String = ""

@onready var _center: CenterContainer = $Center
@onready var _paper: PanelContainer = $Center/Paper
@onready var _heading: Label = $Center/Paper/Margin/Lines/Heading
@onready var _body: Label = $Center/Paper/Margin/Lines/Body
@onready var _signature: Label = $Center/Paper/Margin/Lines/Signature
@onready var _hint: Label = $Hint
@onready var _monitor: Control = $Monitor
@onready var _title: Label = $Monitor/Glass/Window/TitleBar/Title
@onready var _text: Label = $Monitor/Glass/Window/Text
@onready var _status: Label = $Monitor/Glass/Window/Status


func _ready() -> void:
	hide()
	_hint.text = "toca para cerrar" if DisplayServer.is_touchscreen_available() else "cualquier tecla para cerrar"


func _process(delta: float) -> void:
	if not visible or not _monitor.visible:
		return
	# Cursor de bloque parpadeante al final del texto.
	_cursor_time = fmod(_cursor_time + delta, CURSOR_PERIOD * 2.0)
	_text.text = _screen_text + ("█" if _cursor_time < CURSOR_PERIOD else " ")


func _input(event: InputEvent) -> void:
	if not visible or not _is_press(event):
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() - _opened_at >= CLOSE_GUARD_MSEC:
		close()


func open(data: DocumentData) -> void:
	if data == null:
		return
	document = data
	_opened_at = Time.get_ticks_msec()
	var on_screen: bool = data.medium == DocumentData.Medium.SCREEN
	_monitor.visible = on_screen
	_center.visible = not on_screen
	if on_screen:
		_apply_screen(data)
	else:
		_apply_paper(data)
	show()
	opened.emit(data)


func close() -> void:
	if not visible:
		return
	hide()
	var data: DocumentData = document
	document = null
	closed.emit(data)


## Bloc de notas en el terminal: el texto se "imprime" rápido, como al abrir un archivo.
func _apply_screen(data: DocumentData) -> void:
	_title.text = "BLOC DE NOTAS — %s" % (data.file_name if not data.file_name.is_empty() else "SIN_TITULO.TXT")
	var parts: PackedStringArray = PackedStringArray()
	if not data.heading.is_empty():
		parts.append(data.heading)
		parts.append("")
	parts.append(data.body)
	if not data.signature.is_empty():
		parts.append("")
		parts.append(data.signature)
	_screen_text = "\n".join(parts)
	_status.text = "Lín %d, Col 1        SOLO LECTURA        23:47" % (_screen_text.count("\n") + 1)
	_text.text = _screen_text
	_text.visible_ratio = 0.0
	create_tween().tween_property(_text, "visible_ratio", 1.0, TYPE_TIME)


func _apply_paper(data: DocumentData) -> void:
	var medium: DocumentData.Medium = data.medium
	var ink: Color = INK_COLORS[medium]
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAPER_COLORS[medium]
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0.0, 6.0)
	_paper.add_theme_stylebox_override("panel", style)
	# La nota adhesiva es pequeña, cuadrada y está pegada algo torcida.
	var sticky: bool = medium == DocumentData.Medium.STICKY_NOTE
	_paper.custom_minimum_size = Vector2(430.0, 400.0) if sticky else Vector2(560.0, 0.0)
	_paper.pivot_offset = _paper.custom_minimum_size * 0.5
	_paper.rotation_degrees = -2.5 if sticky else 0.0

	# La voz íntima va manuscrita, esté en una nota o en una hoja (docs/11 §4).
	var handwritten: bool = sticky or data.voice == DocumentData.Voice.INTIMATE
	var font: Font = HAND_FONT if handwritten else BODY_FONT
	var width: float = 350.0 if sticky else 480.0
	_heading.text = data.heading
	_heading.visible = not data.heading.is_empty()
	_body.text = data.body
	_signature.text = data.signature
	_signature.visible = not data.signature.is_empty()
	for label: Label in [_heading, _body, _signature]:
		label.add_theme_color_override("font_color", ink)
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 34 if handwritten else 22)
		label.custom_minimum_size.x = width
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if medium == DocumentData.Medium.WALL else HORIZONTAL_ALIGNMENT_LEFT


func _is_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.is_pressed() and not event.is_echo()
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventJoypadButton:
		return event.is_pressed()
	return false
