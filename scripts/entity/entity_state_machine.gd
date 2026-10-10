class_name EntityStateMachine
extends Node
signal changed(state: StringName)
var active: EntityState
var state: StringName = &""
func setup(entity: CharacterBody3D) -> void:
	for child: Node in get_children():
		var item: EntityState = child as EntityState
		item.entity = entity
		item.machine = self
	transition(&"Wander")
func transition(next: StringName) -> void:
	if next == state or (active != null and not active.can_exit()):
		return
	var incoming: EntityState = get_node_or_null(String(next) + "State") as EntityState
	if incoming == null:
		return
	var previous: StringName = state
	if active != null:
		active.exit()
	state = next
	active = incoming
	active.enter(previous)
	changed.emit(state)
