class_name TouchControls
extends CanvasLayer
## Controles táctiles: joystick dinámico, mirada por arrastre y botones (docs/03).
## Solo visibles en táctil; el centro queda libre para el HUD (radio 56 px).

## Radio central reservado al toque de interactuar del HUD.
const CENTER_FREE_RADIUS: float = 56.0
## Diámetro de los botones y margen sobre el área segura.
const BUTTON_DIAMETER: float = 96.0
const SAFE_MARGIN: float = 24.0
## Separación entre botones de acción.
const BUTTON_GAP: float = 16.0

@export var player: Player = null
## Muestra los controles en escritorio para probar el layout.
@export var force_visible: bool = false
## Multiplica el arrastre táctil antes de girar la cámara.
@export_range(0.1, 2.0, 0.05) var look_sensitivity: float = 0.6
@export var sprint_visible: bool = true:
	set(value):
		sprint_visible = value
		if is_node_ready():
			_sprint_button.visible = value
@export var flashlight_visible: bool = true:
	set(value):
		flashlight_visible = value
		if is_node_ready():
			_flash_button.visible = value

## Dedo que gira la cámara; -1 si ninguno.
var _look_touch: int = -1
## Centro visual (y táctil) de cada botón, en píxeles de canvas.
var _sprint_center: Vector2 = Vector2.ZERO
var _flash_center: Vector2 = Vector2.ZERO
var _base_look_sensitivity: float = 0.6
var _touch_opacity: float = 0.35
var _touch_scale: float = 1.0

@onready var _joystick: VirtualJoystick = $Joystick
@onready var _sprint_button: TouchScreenButton = $SprintButton
@onready var _flash_button: TouchScreenButton = $FlashButton


func _ready() -> void:
	_base_look_sensitivity = look_sensitivity
	_sprint_button.visible = sprint_visible
	_flash_button.visible = flashlight_visible
	_apply_settings()
	_layout_buttons()
	get_viewport().size_changed.connect(_layout_buttons)
	Game.settings_changed.connect(_apply_settings)
	_update_visibility()


## Sensibilidad, opacidad y tamaño salen de los ajustes y se aplican en vivo.
func _apply_settings() -> void:
	look_sensitivity = _base_look_sensitivity * float(Game.setting("sensitivity"))
	_touch_opacity = clampf(float(Game.setting("touch_opacity")), 0.1, 1.0)
	_touch_scale = clampf(float(Game.setting("touch_scale")), 0.75, 1.5)
	_redraw_buttons()
	if is_node_ready():
		_layout_buttons()


func _input(event: InputEvent) -> void:
	if not _controls_active():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_claim_look_finger(touch.index, touch.position)
		elif touch.index == _look_touch:
			_look_touch = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _look_touch and player != null and player.controls_enabled:
			player.apply_look(drag.relative * look_sensitivity)


## Reclama el dedo para la mirada si nació en la mitad derecha libre.
func _claim_look_finger(index: int, position: Vector2) -> void:
	if _look_touch != -1:
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	if position.x < view.x * 0.5:
		return # Mitad izquierda: del joystick.
	if position.distance_to(view * 0.5) <= CENTER_FREE_RADIUS:
		return # Centro: del HUD para interactuar.
	if _sprint_button.visible and position.distance_to(_button_center(_sprint_button)) <= BUTTON_DIAMETER * _touch_scale:
		return
	if _flash_button.visible and position.distance_to(_button_center(_flash_button)) <= BUTTON_DIAMETER * _touch_scale:
		return
	_look_touch = index


func _controls_active() -> bool:
	return force_visible or _is_touch_device()


func _update_visibility() -> void:
	visible = _controls_active()


func _button_center(button: TouchScreenButton) -> Vector2:
	if button == _sprint_button:
		return _sprint_center
	return _flash_center


## Botones abajo a la derecha, sobre el margen de área segura.
## OJO: TouchScreenButton dibuja la textura desde `position` (esquina),
## mientras la forma sí se centra; por eso se resta el radio dos veces.
func _layout_buttons() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var diameter: float = BUTTON_DIAMETER * _touch_scale
	var radius: float = diameter * 0.5
	_flash_button.position = Vector2(view.x - SAFE_MARGIN - diameter, view.y - SAFE_MARGIN - diameter)
	_sprint_button.position = Vector2(view.x - SAFE_MARGIN - diameter - diameter - BUTTON_GAP, view.y - SAFE_MARGIN - diameter)
	_flash_center = _flash_button.position + Vector2(radius, radius)
	_sprint_center = _sprint_button.position + Vector2(radius, radius)


## La opacidad del ajuste se hornea en la textura; la escala va al nodo.
func _redraw_buttons() -> void:
	_sprint_button.texture_normal = _make_button_texture("sprint", false)
	_sprint_button.texture_pressed = _make_button_texture("sprint", true)
	_flash_button.texture_normal = _make_button_texture("flash", false)
	_flash_button.texture_pressed = _make_button_texture("flash", true)
	_sprint_button.scale = Vector2(_touch_scale, _touch_scale)
	_flash_button.scale = Vector2(_touch_scale, _touch_scale)


## Círculo blanco procedural con el glifo dibujado; sin assets externos.
func _make_button_texture(kind: String, pressed: bool) -> ImageTexture:
	var side: int = int(BUTTON_DIAMETER)
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var alpha: float = minf(_touch_opacity + 0.25, 1.0) if pressed else _touch_opacity
	var ink := Color(1.0, 1.0, 1.0, alpha)
	var center := Vector2(side, side) * 0.5
	_draw_ring(image, center, 44.0, 4.0, ink)
	if kind == "sprint":
		_draw_chevron(image, center + Vector2(-12.0, 0.0), 17.0, 7.0, ink)
		_draw_chevron(image, center + Vector2(5.0, 0.0), 17.0, 7.0, ink)
	else:
		_draw_disc(image, center, 9.0, ink)
		for i: int in range(8):
			var angle: float = TAU * float(i) / 8.0
			var direction := Vector2(cos(angle), sin(angle))
			_draw_line(image, center + direction * 16.0, center + direction * 26.0, 5.0, ink)
	return ImageTexture.create_from_image(image)


## Galón ">" centrado en el punto dado.
func _draw_chevron(image: Image, center: Vector2, half: float, width: float, ink: Color) -> void:
	_draw_line(image, center + Vector2(-half * 0.6, -half), center + Vector2(half * 0.6, 0.0), width, ink)
	_draw_line(image, center + Vector2(half * 0.6, 0.0), center + Vector2(-half * 0.6, half), width, ink)


func _draw_ring(image: Image, center: Vector2, radius: float, width: float, ink: Color) -> void:
	var from: int = int((center.x - radius - width) / 1.0)
	var to: int = int((center.x + radius + width) / 1.0)
	for y: int in range(from, to + 1):
		for x: int in range(from, to + 1):
			var distance: float = Vector2(float(x), float(y)).distance_to(center)
			if absf(distance - radius) <= width * 0.5:
				_blend_pixel(image, x, y, ink)


func _draw_disc(image: Image, center: Vector2, radius: float, ink: Color) -> void:
	var from_x: int = maxi(0, int(center.x - radius - 1.0))
	var to_x: int = mini(image.get_width() - 1, int(center.x + radius + 1.0))
	var from_y: int = maxi(0, int(center.y - radius - 1.0))
	var to_y: int = mini(image.get_height() - 1, int(center.y + radius + 1.0))
	for y: int in range(from_y, to_y + 1):
		for x: int in range(from_x, to_x + 1):
			if Vector2(float(x), float(y)).distance_to(center) <= radius:
				_blend_pixel(image, x, y, ink)


func _draw_line(image: Image, from: Vector2, to: Vector2, width: float, ink: Color) -> void:
	var steps: int = int(maxi(1, int(ceili(from.distance_to(to) * 2.0))))
	for i: int in range(steps + 1):
		_draw_disc(image, from.lerp(to, float(i) / float(steps)), width * 0.5, ink)


func _blend_pixel(image: Image, x: int, y: int, ink: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	var base: Color = image.get_pixel(x, y)
	var mixed := Color(ink.r, ink.g, ink.b, ink.a + base.a * (1.0 - ink.a))
	image.set_pixel(x, y, mixed)


func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
