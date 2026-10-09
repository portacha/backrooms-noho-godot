class_name Reticle
extends Control
## Retícula: punto de 4 px que se expande a anillo de 24 px solo con algo en rango.
## Es toda la UI permanente del juego (docs/13 §3.4 y §5).

const DOT_RADIUS: float = 2.0
const RING_RADIUS: float = 12.0
const HOLD_RING_RADIUS: float = 17.0
const EXPAND_TIME: float = 0.12
const ARC_POINTS: int = 48

@export var color: Color = Color(1.0, 1.0, 1.0, 0.75)
@export var hold_color: Color = Color(1.0, 1.0, 1.0, 0.45)

var focused: bool = false
var hold_ratio: float = 0.0:
	set(value):
		hold_ratio = clampf(value, 0.0, 1.0)
		queue_redraw()

var _expand: float = 0.0


func _process(delta: float) -> void:
	var target: float = 1.0 if focused else 0.0
	if is_equal_approx(_expand, target):
		return
	_expand = move_toward(_expand, target, delta / EXPAND_TIME)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	if _expand <= 0.0:
		draw_circle(center, DOT_RADIUS, color)
		return
	var radius: float = lerpf(DOT_RADIUS, RING_RADIUS, _expand)
	draw_arc(center, radius, 0.0, TAU, ARC_POINTS, color, 1.5, true)
	if hold_ratio > 0.0:
		var start: float = -PI * 0.5
		draw_arc(center, HOLD_RING_RADIUS, start, start + TAU * hold_ratio, ARC_POINTS, hold_color, 2.0, true)
