class_name Hud
extends CanvasLayer
## HUD de partida: retícula y overlay de documentos (docs/13 §5).
## Escucha al Interactor del jugador; no conoce los niveles.

## Radio del toque sobre la retícula que cuenta como interactuar en móvil (docs/03).
const TOUCH_RADIUS: float = 56.0

@export var player: Player

var _interactor: Interactor = null
var _reticle_touch: int = -1

@onready var _reticle: Reticle = $Reticle
@onready var _overlay: DocumentOverlay = $DocumentOverlay
@onready var _paper_player: AudioStreamPlayer = $PaperPlayer
@onready var _hint: Label = $Hint
@onready var _line: Label = $Line
@onready var _end_card: Control = $EndCard
@onready var _end_title: Label = $EndCard/Lines/Title
@onready var _end_text: Label = $EndCard/Lines/Text
@onready var _end_button: Button = $EndCard/Lines/MenuButton

var _hint_tween: Tween = null
var _line_tween: Tween = null


func _ready() -> void:
	_hint.modulate.a = 0.0
	_line.modulate.a = 0.0
	_end_card.hide()
	_end_button.pressed.connect(Game.return_to_menu)
	if player == null:
		push_warning("Hud sin jugador asignado.")
		return
	if not player.is_node_ready():
		await player.ready
	_interactor = player.interactor
	_interactor.focus_changed.connect(_on_focus_changed)
	_interactor.hold_progress_changed.connect(_on_hold_progress_changed)
	_interactor.interacted.connect(_on_interacted)
	_overlay.opened.connect(_on_document_opened)
	_overlay.closed.connect(_on_document_closed)


func _unhandled_input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch == null or _interactor == null:
		return
	if touch.pressed:
		var center: Vector2 = _reticle.get_global_rect().get_center()
		if _reticle.focused and touch.position.distance_to(center) <= TOUCH_RADIUS:
			_reticle_touch = touch.index
			_interactor.press()
			get_viewport().set_input_as_handled()
	elif touch.index == _reticle_touch:
		_reticle_touch = -1
		_interactor.release()


## Pista tenue y pasajera (docs/14 §11). `duration` 0 = hasta `hide_hint()`.
func show_hint(text: String, duration: float = 4.0) -> void:
	_hint.text = text
	if _hint_tween != null:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint, "modulate:a", 0.7, 0.8)
	if duration > 0.0:
		_hint_tween.tween_interval(duration)
		_hint_tween.tween_property(_hint, "modulate:a", 0.0, 0.8)


func hide_hint() -> void:
	if _hint_tween != null:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint, "modulate:a", 0.0, 0.4)


## Frase que el protagonista dice para sí: subtítulo breve, sin voz.
func show_line(text: String, duration: float = 3.5) -> void:
	_line.text = "«%s»" % text
	if _line_tween != null:
		_line_tween.kill()
	_line_tween = create_tween()
	_line_tween.tween_property(_line, "modulate:a", 0.9, 0.4)
	_line_tween.tween_interval(duration)
	_line_tween.tween_property(_line, "modulate:a", 0.0, 0.8)


## Tarjeta de cierre sobre negro (fin de nivel o de la demo).
func show_end_card(title: String, text: String) -> void:
	_reticle.hide()
	_end_title.text = title
	_end_text.text = text
	_end_card.modulate.a = 0.0
	_end_card.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	create_tween().tween_property(_end_card, "modulate:a", 1.0, 1.2)
	_end_button.grab_focus()


func _on_focus_changed(target: Interactable) -> void:
	_reticle.focused = target != null


func _on_hold_progress_changed(ratio: float) -> void:
	_reticle.hold_ratio = ratio


func _on_interacted(target: Interactable) -> void:
	var pickup: DocumentPickup = target as DocumentPickup
	if pickup != null:
		_overlay.open(pickup.document)


func _on_document_opened(_document: DocumentData) -> void:
	player.controls_enabled = false
	_reticle.hide()
	_paper_player.play()


func _on_document_closed(_document: DocumentData) -> void:
	player.controls_enabled = true
	_reticle.show()
