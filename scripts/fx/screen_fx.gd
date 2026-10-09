class_name ScreenFx
extends CanvasLayer
## Shader de pantalla completa por eventos (docs/07 "Posprocesado") y fundidos.

@export var fade_in_time: float = 1.5

var aberration: float = 0.0:
	set(value):
		aberration = value
		_apply(&"aberration", value)
var distortion: float = 0.0:
	set(value):
		distortion = value
		_apply(&"distortion", value)
var vignette: float = 0.0:
	set(value):
		vignette = value
		_apply(&"vignette", value)
var fade: float = 0.0:
	set(value):
		fade = value
		_apply(&"fade", value)
var fade_color: Color = Color.BLACK:
	set(value):
		fade_color = value
		_apply(&"fade_color", value)

@onready var _rect: ColorRect = $Rect
@onready var _material: ShaderMaterial = $Rect.material


func _ready() -> void:
	# Cada escena entra fundiendo desde el color con el que salió la anterior (docs/14 §7).
	fade_color = Game.fade_in_color
	fade = 1.0
	fade_to(0.0, fade_in_time)


func fade_to(amount: float, duration: float) -> Tween:
	var tween: Tween = create_tween()
	tween.tween_property(self, "fade", amount, duration).set_trans(Tween.TRANS_SINE)
	return tween


func _apply(parameter: StringName, value: Variant) -> void:
	if not is_node_ready():
		return
	_material.set_shader_parameter(parameter, value)
	_rect.visible = aberration > 0.0 or distortion > 0.0 or vignette > 0.0 or fade > 0.0
