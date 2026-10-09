class_name Interactor
extends Node
## Elige el interactuable que el jugador tiene a la vista y al alcance, y resuelve
## el toque o el mantener (docs/13 §3.4). El HUD solo escucha sus señales.

## `target` es null cuando no hay nada en rango.
signal focus_changed(target: Interactable)
signal hold_progress_changed(ratio: float)
signal interacted(target: Interactable)

const LINE_OF_SIGHT_TOLERANCE: float = 0.2
const HOLD_DECAY_TIME: float = 0.4

@export var camera: Camera3D
## Media apertura del cono de mirada. Amplio a propósito: la interacción es por
## proximidad, no por puntería (docs/03).
@export_range(5.0, 90.0, 1.0) var view_half_angle_degrees: float = 45.0
## Tolerancia a soltar por accidente durante un mantener (docs/13 §8).
@export var hold_release_grace: float = 0.25

var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			_pressed = false
			_set_focus(null)

var focus: Interactable = null

var _pressed: bool = false
var _hold_elapsed: float = 0.0
var _released_for: float = 0.0
var _body: CollisionObject3D = null


func _ready() -> void:
	_body = get_parent() as CollisionObject3D


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		# Con el puntero libre, el clic es para capturarlo (Web), no para interactuar.
		if event is InputEventMouseButton and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		press()
	elif event.is_action_released("interact"):
		release()


func _physics_process(delta: float) -> void:
	if not enabled or camera == null:
		return
	_set_focus(_find_target())
	_update_hold(delta)


## Pulsación de interactuar. Pública para el toque sobre la retícula en móvil.
func press() -> void:
	if not enabled or focus == null:
		return
	if focus.hold_time <= 0.0:
		_complete()
	else:
		_pressed = true
		_released_for = 0.0


func release() -> void:
	_pressed = false


func _find_target() -> Interactable:
	var origin: Vector3 = camera.global_position
	var forward: Vector3 = -camera.global_basis.z
	var best: Interactable = null
	var best_angle: float = deg_to_rad(view_half_angle_degrees)
	for node: Node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var candidate: Interactable = node as Interactable
		if candidate == null or not candidate.enabled or not candidate.is_visible_in_tree():
			continue
		var offset: Vector3 = candidate.global_position - origin
		if offset.length() > candidate.interaction_range or offset.is_zero_approx():
			continue
		# Gana el más cercano al centro de la pantalla.
		var angle: float = forward.angle_to(offset)
		if angle > best_angle or not _has_line_of_sight(origin, candidate.global_position):
			continue
		best = candidate
		best_angle = angle
	return best


func _has_line_of_sight(from: Vector3, to: Vector3) -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	if _body != null:
		query.exclude = [_body.get_rid()]
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var hit_position: Vector3 = hit["position"]
	return hit_position.distance_to(to) <= LINE_OF_SIGHT_TOLERANCE


func _update_hold(delta: float) -> void:
	if focus == null or focus.hold_time <= 0.0:
		return
	var previous: float = _hold_elapsed
	if _pressed:
		_hold_elapsed += delta
		if _hold_elapsed >= focus.hold_time:
			_complete()
			return
	else:
		_released_for += delta
		if _released_for > hold_release_grace:
			_hold_elapsed = move_toward(_hold_elapsed, 0.0, focus.hold_time * delta / HOLD_DECAY_TIME)
	if not is_equal_approx(previous, _hold_elapsed):
		hold_progress_changed.emit(_hold_elapsed / focus.hold_time)


func _complete() -> void:
	var target: Interactable = focus
	_reset_hold()
	target.interact()
	interacted.emit(target)


func _set_focus(target: Interactable) -> void:
	if target == focus:
		return
	focus = target
	_reset_hold()
	focus_changed.emit(focus)


func _reset_hold() -> void:
	_pressed = false
	_released_for = 0.0
	if _hold_elapsed > 0.0:
		_hold_elapsed = 0.0
		hold_progress_changed.emit(0.0)
