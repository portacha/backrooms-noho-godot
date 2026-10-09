class_name LevelBase
extends Node3D
## Base de nivel: geometría pre-horneada (tools/build_levels.gd) + jugador + HUD.
## Los objetos de juego se colocan en los marcadores de la geometría.

const SIGN_FONT: Font = preload("res://assets/fonts/nunito_bold.tres")

@onready var geo: Node3D = $Geo
@onready var player: Player = $Player
@onready var hud: Hud = $Hud
@onready var screen_fx: ScreenFx = $ScreenFx
@onready var pause_menu: Node = get_node_or_null("PauseMenu")
@onready var touch_controls: Node = get_node_or_null("TouchControls")


func _ready() -> void:
	RenderingServer.global_shader_parameter_set(&"world_light", 1.0)
	RenderingServer.global_shader_parameter_set(&"flicker_override", -1.0)


func marker(marker_name: String) -> Vector3:
	var node: Node3D = geo.get_node_or_null("Markers/" + marker_name) as Node3D
	if node == null:
		push_error("Falta el marcador '%s' en %s" % [marker_name, geo.name])
		return Vector3.ZERO
	return node.global_position


func has_marker(marker_name: String) -> bool:
	return geo.has_node("Markers/" + marker_name)


func add_interactable(at: Vector3, interaction_range: float = 2.0, hold_time: float = 0.0) -> Interactable:
	var node: Interactable = Interactable.new()
	node.interaction_range = interaction_range
	node.hold_time = hold_time
	add_child(node)
	node.global_position = at
	return node


func add_document(at: Vector3, path: String, interaction_range: float = 2.0) -> DocumentPickup:
	var node: DocumentPickup = DocumentPickup.new()
	node.document = load(path) as DocumentData
	node.interaction_range = interaction_range
	add_child(node)
	node.global_position = at
	return node


## Instancia un modelo de `assets/models` para objetos dinámicos (los estáticos se hornean en la
## geometría). Sin luz en tiempo real, se ven por emisión: `glow` para el cuerpo, `special_glow`
## para las superficies `Glow`, `Flame` y `Screen`.
func spawn_model(model: String, parent: Node3D, glow: float = 0.35, special_glow: float = 2.5) -> Node3D:
	var packed: PackedScene = load("res://assets/models/%s.glb" % model) as PackedScene
	var instance: Node3D = packed.instantiate() as Node3D
	parent.add_child(instance)
	for node: Node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface: int in mesh_instance.mesh.get_surface_count():
			var source: BaseMaterial3D = mesh_instance.get_active_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var material: StandardMaterial3D = StandardMaterial3D.new()
			var special: bool = source.resource_name in ["Glow", "Flame", "Screen"]
			material.albedo_color = Color.BLACK if special else source.albedo_color
			material.roughness = 1.0
			material.emission_enabled = true
			material.emission = source.albedo_color
			material.emission_energy_multiplier = special_glow if special else glow
			mesh_instance.set_surface_override_material(surface, material)
	return instance


## Escribe el texto de los letreros que dejó la definición del nivel (`LevelDef.add_sign`).
## `texts`: clave del letrero → texto. Los colgantes (clave que empieza por "h") llevan letra mayor.
func build_signs(texts: Dictionary, ink: Color) -> void:
	for node: Node in geo.get_node("Markers").get_children():
		var marker_name: String = node.name
		if not marker_name.begins_with("sign_") or marker_name.ends_with("_n"):
			continue
		var key: String = marker_name.trim_prefix("sign_").rsplit("_", true, 1)[0]
		if not texts.has(key):
			continue
		var at: Vector3 = (node as Node3D).global_position
		var facing: Vector3 = marker(marker_name + "_n") - at
		var label: Label3D = Label3D.new()
		label.text = texts[key]
		label.font = SIGN_FONT
		label.font_size = 96 if key.begins_with("h") else 64
		label.pixel_size = 0.0011 if key.begins_with("h") else 0.00078
		label.outline_size = 0
		label.modulate = ink
		add_child(label)
		label.global_position = at
		label.rotation.y = atan2(facing.x, facing.z)


func set_can_pause(value: bool) -> void:
	if pause_menu != null:
		pause_menu.set("can_pause", value)


func set_touch_button(property: StringName, value: bool) -> void:
	if touch_controls != null:
		touch_controls.set(property, value)


func is_touch() -> bool:
	return DisplayServer.is_touchscreen_available() and (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"))


func play_sound(stream: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	var audio: AudioStreamPlayer = AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume_db
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)
	return audio


func add_loop(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var audio: AudioStreamPlayer = AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume_db
	add_child(audio)
	audio.play()
	return audio
