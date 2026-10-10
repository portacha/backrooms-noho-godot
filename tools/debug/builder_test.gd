extends SceneTree
## Prueba headless del constructor; no guarda ni modifica escenas.

var _failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		print("BUILDER TEST FAIL: " + message)

func _run() -> void:
	var def: LevelDef = (load("res://tools/levels/test_def.gd") as GDScript).new() as LevelDef
	var builder: LevelBuilder = LevelBuilder.new()
	var level: Node3D = builder._build(def)
	if level == null:
		_check(false, "No se construyó el mapa técnico.")
		quit(1)
		return
	_check(level.get_meta("grid_width") == 8 and level.get_meta("grid_height") == 5, "Dimensiones de rejilla.")
	var heights: PackedFloat32Array = level.get_meta("cell_heights")
	var walkable: PackedByteArray = level.get_meta("walkable")
	_check(heights.size() == 40 and walkable.size() == 40, "Longitud de metadatos.")
	_check(is_equal_approx(heights[11], 4.8) and is_equal_approx(heights[12], 1.2) and heights[21] == 0.0, "Alturas y vacío en orden de filas.")
	_check(walkable[9] == 1 and walkable[10] == 1 and walkable[11] == 1, "Suelo libre transitable.")
	_check(walkable[12] == 0 and walkable[18] == 0 and walkable[0] == 0 and walkable[21] == 0 and walkable[28] == 0, "Conducto, nav=false, sólido, vacío y techo sin suelo.")
	_check(walkable[17] == 0 and walkable[20] == 0, "Huellas de tabique y prop inclinado.")
	var zones: Dictionary = level.get_meta("zones")
	_check(zones.get("agua") == [Vector2i(3, 1)] and zones.get("disparador") == [Vector2i(3, 1)] and zones.get("conducto") == [Vector2i(4, 1)] and zones.get("remanso") == [Vector2i(4, 2)], "Zonas exactas sin duplicados.")
	_check(level.has_node("Chunks") and not level.has_node("Geometry"), "Árbol de bloques.")
	_check(_contains(level, Vector3(8.0, 2.0, 3.0)), "Dintel alto/bajo con colisión.")
	_check(not _contains(level, Vector3(8.0, 0.8, 3.0)), "Paso libre bajo el dintel.")
	_check(_contains(level, Vector3(9.0, 1.25, 3.0)) and not _contains(level, Vector3(7.0, 1.25, 3.0)), "Techo bajo por celda.")
	_check(_contains(level, Vector3(7.0, 4.85, 3.0)), "Techo alto por celda.")
	_check(_contains(level, Vector3(5.0, -0.3, 3.0)), "Losa bajo suelo con grosor de isla.")
	for y: float in [1.0, -0.1, -0.5, -2.0]:
		_check(not _contains(level, Vector3(11.0, y, 5.0)), "Abismo libre a altura %.1f." % y)
	_check(not _contains(level, Vector3(9.0, -0.1, 7.0)) and _contains(level, Vector3(9.0, 3.65, 7.0)), "Techo sin suelo no tapa abismo.")
	_check(not builder._visible(Vector3(7, 2, 3), Vector3(9, 2, 3)), "Dintel ocluye la luz alta.")
	_check(builder._visible(Vector3(7, 0.8, 3), Vector3(9, 0.8, 3)), "Luz atraviesa el conducto bajo.")
	_check(builder._visible(Vector3(11, 1, 3), Vector3(11, 1, 5)), "Vacío no ocluye luz.")
	var lights: Array = level.get_meta("lights")
	_check(lights.size() == 2 and is_equal_approx(lights[0]["pos"].y, 1.5) and is_equal_approx(lights[1]["pos"].y, 2.4), "Alturas de focos sin/con panel.")
	_check(level.find_children("LightPanels", "MeshInstance3D", true, false).size() == 1, "Solo un difusor: panel=false omite luminaria.")
	_check(_has_face(level, &"edge", Vector3.DOWN, -def.void_skirt_depth), "Cara inferior con material edge.")
	_check(_has_face(level, &"floor", Vector3.RIGHT, -def.void_skirt_depth), "Faldón de isla hacia el vacío.")
	_check(_has_face(level, &"wall", Vector3.LEFT, 1.2), "Cara del dintel usa material de celda baja.")
	_check_tilt(level, def)
	_check_chunks(level, def)
	def.chunk_cells = 0
	var unsplit: Node3D = LevelBuilder.build(def)
	_check_triangle_counts(level, unsplit)
	unsplit.free()
	level.free()
	_check_defaults()
	_check_rectangles_and_void_walls()
	_check_legacy_scenes()
	if _failures == 0:
		print("BUILDER TEST OK")
	else:
		print("BUILDER TEST FAIL: %d comprobaciones." % _failures)
	quit(0 if _failures == 0 else 1)

## Inspección de cajas: transforma el punto al espacio de cada CollisionShape3D.
func _contains(level: Node3D, point: Vector3) -> bool:
	for node: Node in level.get_node("Collision").get_children():
		var collision: CollisionShape3D = node as CollisionShape3D
		var shape: BoxShape3D = collision.shape as BoxShape3D
		var local: Vector3 = collision.transform.affine_inverse() * point
		if AABB(-shape.size * 0.5, shape.size).has_point(local):
			return true
	return false

func _has_face(level: Node3D, material: StringName, normal: Vector3, y: float) -> bool:
	for node: Node in level.find_children("*", "MeshInstance3D", true, false):
		var mesh: ArrayMesh = (node as MeshInstance3D).mesh as ArrayMesh
		for surface: int in mesh.get_surface_count():
			if mesh.surface_get_name(surface) != String(material):
				continue
			var arrays: Array = mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i: int in positions.size():
				if normals[i].dot(normal) > 0.99 and is_equal_approx(positions[i].y, y):
					return true
	return false

func _check_tilt(level: Node3D, def: LevelDef) -> void:
	var prop: Dictionary = def.props[0]
	var model: Node3D = (load("res://assets/models/desk_office.glb") as PackedScene).instantiate() as Node3D
	var bounds: AABB = AABB()
	var initialized: bool = false
	var helper: LevelBuilder = LevelBuilder.new()
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		var transform: Transform3D = helper._transform_to_root(instance, model)
		for surface: int in instance.mesh.get_surface_count():
			var vertices: PackedVector3Array = instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				var point: Vector3 = transform * vertex
				bounds = bounds.expand(point) if initialized else AABB(point, Vector3.ZERO)
				initialized = true
	var tilt: Vector3 = prop["tilt"]
	var basis: Basis = Basis(Vector3.UP, deg_to_rad(prop["rot_y"])) * Basis(Vector3.RIGHT, deg_to_rad(tilt.x)) * Basis(Vector3.BACK, deg_to_rad(tilt.z))
	var expected: AABB = Transform3D(basis, prop["pos"]) * bounds
	var found: bool = false
	for node: Node in level.get_node("Collision").get_children():
		var collision: CollisionShape3D = node as CollisionShape3D
		if collision.position.is_equal_approx(expected.get_center()) and (collision.shape as BoxShape3D).size.is_equal_approx(expected.size) and collision.rotation.is_zero_approx():
			found = true
	_check(found, "Prop inclinado tiene AABB mundial exacta sin rotación de caja.")
	model.free()

func _check_chunks(level: Node3D, def: LevelDef) -> void:
	var materials: Dictionary = {}
	for node: Node in level.get_node("Chunks").get_children():
		var instance: MeshInstance3D = node as MeshInstance3D
		_check(String(instance.name).begins_with("Chunk_"), "Nombres de bloques.")
		_check(instance.visibility_range_end == def.visibility_range and instance.visibility_range_end_margin > 0.0 and instance.visibility_range_fade_mode == GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED, "Rango con histéresis.")
		var mesh: ArrayMesh = instance.mesh as ArrayMesh
		for surface: int in mesh.get_surface_count():
			var key: String = mesh.surface_get_name(surface)
			var material: Material = mesh.surface_get_material(surface)
			_check(not materials.has(key) or materials[key] == material, "Instancia compartida de material " + key)
			materials[key] = material
		for child: Node in instance.get_children():
			_check((child as MeshInstance3D).visibility_range_end == def.visibility_range, "Difusor sigue rango del bloque.")

func _triangles(level: Node3D) -> Dictionary:
	var result: Dictionary = {}
	for node: Node in level.find_children("*", "MeshInstance3D", true, false):
		if node.name == &"LightPanels":
			continue
		var mesh: ArrayMesh = (node as MeshInstance3D).mesh as ArrayMesh
		for surface: int in mesh.get_surface_count():
			var key: String = mesh.surface_get_name(surface)
			var indices: PackedInt32Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
			result[key] = int(result.get(key, 0)) + indices.size() / 3
	return result

## Compara atributos por triángulo, ignorando el orden entre bloques y grupos vacíos.
func _indexed_attributes(level: Node3D) -> Dictionary:
	var result: Dictionary = {}
	for node: Node in level.find_children("*", "MeshInstance3D", true, false):
		var mesh: ArrayMesh = (node as MeshInstance3D).mesh as ArrayMesh
		for surface: int in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var key: String = mesh.surface_get_name(surface)
			if node.name == &"LightPanels":
				key = "panel_" + (key if not key.is_empty() else ("steady" if surface == 0 else "flicker"))
			for offset: int in range(0, indices.size(), 3):
				if (vertices[indices[offset + 1]] - vertices[indices[offset]]).cross(vertices[indices[offset + 2]] - vertices[indices[offset]]).is_zero_approx():
					continue
				var signature: String = key
				for corner: int in range(3):
					var index: int = indices[offset + corner]
					for attribute: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_COLOR]:
						signature += str(arrays[attribute][index]) + ";"
				result[signature] = int(result.get(signature, 0)) + 1
	return result

func _check_triangle_counts(split: Node3D, unsplit: Node3D) -> void:
	_check(_triangles(split) == _triangles(unsplit), "Bloques conservan todos los triángulos por material.")
	_check(split.get_meta("build_stats") == unsplit.get_meta("build_stats"), "Bloques conservan conteos de horneado.")
	_check(_indexed_attributes(split) == _indexed_attributes(unsplit), "Bloques conservan posición, normales, UV, color y energía de todos los triángulos.")

func _check_defaults() -> void:
	var def: LevelDef = LevelDef.new()
	def.name = "defaults"
	def.rows = PackedStringArray(["."])
	def.tiles = {".": {"floor": &"floor", "ceiling": &"ceiling"}}
	var level: Node3D = LevelBuilder.build(def)
	_check(level != null, "Defaults construyen nivel.")
	if level == null:
		return
	_check(level.has_node("Geometry") and not level.has_node("Chunks") and level.has_node("LightPanels"), "Árbol original con defaults.")
	_check(level.get_meta("build_stats") == {"cells": 1, "vertices": 50, "lights": 0}, "Conteos originales con defaults.")
	_check(level.get_node("Collision").get_child_count() == 2 and _contains(level, Vector3(1, -0.1, 1)) and _contains(level, Vector3(1, 2.9, 1)), "Losas globales originales.")
	_check(level.get_meta("walkable") == PackedByteArray([1]), "Navegación por defecto.")
	level.free()
	# Los huecos siguen cubiertos por la losa global si open_void=false.
	def.rows = PackedStringArray([". "])
	level = LevelBuilder.build(def)
	_check(_contains(level, Vector3(3, -0.1, 1)), "Vacío desactivado conserva suelo global.")
	level.free()
	# Alturas distintas también funcionan sin activar open_void.
	def.rows = PackedStringArray([".c"])
	def.tiles["c"] = {"floor": &"floor", "ceiling": &"ceiling", "height": 1.2}
	level = LevelBuilder.build(def)
	_check(_contains(level, Vector3(3, 1.25, 1)) and not _contains(level, Vector3(1, 1.25, 1)), "Techos por celda sin open_void.")
	level.free()

func _check_rectangles_and_void_walls() -> void:
	var def: LevelDef = LevelDef.new()
	def.name = "rectangles"
	def.open_void = true
	def.rows = PackedStringArray([".. ", ".. "])
	def.tiles = {".": {"floor": &"floor", "ceiling": &"ceiling"}}
	var level: Node3D = LevelBuilder.build(def)
	_check(level.get_node("Collision").get_child_count() == 2, "Suelo y techo fusionados en dos rectángulos.")
	_check(not _contains(level, Vector3(4, 1, 1)), "Borde de isla sin muro.")
	level.free()
	def.tiles["."]["void_wall"] = &"wall"
	level = LevelBuilder.build(def)
	_check(_contains(level, Vector3(4, 1, 1)), "void_wall explícito conserva pared de borde.")
	level.free()

## Las referencias se guardan antes de editar en builds/01-builder-baseline/.
func _check_legacy_scenes() -> void:
	for name: String in ["prologue", "level1"]:
		var path: String = "res://builds/01-builder-baseline/" + name + ".scn"
		if not ResourceLoader.exists(path):
			print("BUILDER TEST: referencia inicial ausente para " + name + "; se omite comparación de escena.")
			continue
		var before: Node3D = (load(path) as PackedScene).instantiate() as Node3D
		var after: Node3D = (load("res://scenes/levels/generated/" + name + ".scn") as PackedScene).instantiate() as Node3D
		_check(before.get_meta("build_stats") == after.get_meta("build_stats"), name + ": estadísticas idénticas.")
		for mesh_name: String in ["Geometry", "LightPanels"]:
			var old_mesh: ArrayMesh = (before.get_node(mesh_name) as MeshInstance3D).mesh as ArrayMesh
			var new_mesh: ArrayMesh = (after.get_node(mesh_name) as MeshInstance3D).mesh as ArrayMesh
			_check(old_mesh.get_surface_count() == new_mesh.get_surface_count(), name + ": superficies idénticas.")
			for surface: int in old_mesh.get_surface_count():
				var old_arrays: Array = old_mesh.surface_get_arrays(surface)
				var new_arrays: Array = new_mesh.surface_get_arrays(surface)
				for attribute: int in Mesh.ARRAY_MAX:
					_check(old_arrays[attribute] == new_arrays[attribute], "%s: %s superficie %d atributo %d idéntico." % [name, mesh_name, surface, attribute])
		var old_shapes: Array[Node] = before.get_node("Collision").get_children()
		var new_shapes: Array[Node] = after.get_node("Collision").get_children()
		_check(old_shapes.size() == new_shapes.size(), name + ": cantidad de colisiones idéntica.")
		for i: int in mini(old_shapes.size(), new_shapes.size()):
			var old_shape: CollisionShape3D = old_shapes[i] as CollisionShape3D
			var new_shape: CollisionShape3D = new_shapes[i] as CollisionShape3D
			_check(old_shape.transform == new_shape.transform and (old_shape.shape as BoxShape3D).size == (new_shape.shape as BoxShape3D).size, name + ": colisión %d idéntica." % i)
		before.free()
		after.free()
		print("BUILDER TEST: comparación de referencia " + name + " terminada.")
