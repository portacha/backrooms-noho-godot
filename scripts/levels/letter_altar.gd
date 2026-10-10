class_name LetterAltar
extends Node3D
## Letra-altar (docs/12 §9, docs/13 §3.4): neón flotando con halo; se toma manteniendo 1,5 s.

signal taken

const NEON: Color = Color(1.0, 0.36, 0.72)

## 0–1 mientras el jugador mantiene la interacción.
var hold_ratio: float = 0.0
var is_taken: bool = false
var spot: Interactable = null
## Escala de la letra (la O del Nivel 2 es monumental).
var size: float = 1.0

var _base_y: float = 0.0
var _time: float = 0.0


## `level` crea el modelo (`LevelBase.spawn_model`) y el punto de interacción.
func build(level: LevelBase, model: String, yaw: float, interaction_range: float) -> void:
	_base_y = position.y
	var letter: Node3D = level.spawn_model(model, self, 2.6, 2.6)
	letter.rotation.y = yaw
	for node: Node in letter.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		for surface: int in mesh_instance.mesh.get_surface_count():
			var material: StandardMaterial3D = mesh_instance.get_surface_override_material(surface) as StandardMaterial3D
			if material != null:
				material.emission = Color(1.0, 0.8, 0.9)
	# Halo: no es un objeto, es el resplandor del neón (un disco aditivo que mira a cámara).
	var falloff: Gradient = Gradient.new()
	falloff.set_color(0, Color.WHITE)
	falloff.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var falloff_texture: GradientTexture2D = GradientTexture2D.new()
	falloff_texture.gradient = falloff
	falloff_texture.fill = GradientTexture2D.FILL_RADIAL
	falloff_texture.fill_from = Vector2(0.5, 0.5)
	falloff_texture.fill_to = Vector2(1.0, 0.5)
	var halo_material: StandardMaterial3D = StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_material.albedo_color = Color(NEON.r, NEON.g, NEON.b, 0.3)
	halo_material.albedo_texture = falloff_texture
	halo_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var halo_mesh: QuadMesh = QuadMesh.new()
	halo_mesh.size = Vector2(1.5, 1.5)
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.mesh = halo_mesh
	halo.material_override = halo_material
	add_child(halo)

	spot = level.add_interactable(global_position, interaction_range, 1.5)
	spot.interacted.connect(_on_interacted)
	level.player.interactor.hold_progress_changed.connect(func(ratio: float) -> void:
		if level.player.interactor.focus == spot or ratio == 0.0:
			hold_ratio = ratio)


## Color y energía del tubo de neón (por defecto, rosa pálido).
func set_neon(color: Color, energy: float) -> void:
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.mesh is QuadMesh:
			(mesh_instance.material_override as StandardMaterial3D).albedo_color = Color(color.r, color.g, color.b, 0.3)
			continue
		for surface: int in mesh_instance.mesh.get_surface_count():
			var material: StandardMaterial3D = mesh_instance.get_surface_override_material(surface) as StandardMaterial3D
			if material != null:
				material.emission = color
				material.emission_energy_multiplier = energy


func _process(delta: float) -> void:
	if is_taken:
		return
	_time += delta
	position.y = _base_y + sin(_time * 1.3) * 0.035
	rotation.y = sin(_time * 0.5) * 0.35
	var grow: float = 1.0 + hold_ratio * 0.25
	scale = Vector3.ONE * grow * size


func _on_interacted() -> void:
	if is_taken:
		return
	is_taken = true
	spot.enabled = false
	taken.emit()
