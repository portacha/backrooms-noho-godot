class_name LevelBuilder
extends RefCounted

const STEP: float = 0.5
const DOOR_HEIGHT: float = 2.1
const DIRS: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

class SurfaceData:
	extends RefCounted
	var positions: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var uv2s: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	var cells: PackedInt32Array = PackedInt32Array()
	var kinds: PackedByteArray = PackedByteArray()
	var chunks: PackedInt32Array = PackedInt32Array()
	func arrays() -> Array:
		var result: Array = []
		result.resize(Mesh.ARRAY_MAX)
		result[Mesh.ARRAY_VERTEX] = positions
		result[Mesh.ARRAY_NORMAL] = normals
		result[Mesh.ARRAY_TEX_UV] = uvs
		result[Mesh.ARRAY_TEX_UV2] = uv2s
		result[Mesh.ARRAY_COLOR] = colors
		result[Mesh.ARRAY_INDEX] = indices
		return result

var _def: LevelDef
var _width: int = 0
var _height: int = 0
var _grid: Array[Dictionary] = []
var _surfaces: Dictionary[StringName, SurfaceData] = {}
var _lights: Array[Dictionary] = []
var _samples: Array[PackedVector3Array] = []
var _buckets: Dictionary[Vector2i, Array] = {}
var _occluders: Array[AABB] = []
var _panels: Array[SurfaceData] = []
var _floor_sum: PackedColorArray = PackedColorArray()
var _floor_count: PackedInt32Array = PackedInt32Array()
var _root: Node3D
var _collision: StaticBody3D
var _markers: Node3D
var _marker_counts: Dictionary[String, int] = {}
## Paleta de tintes planos: las cajas con `tint` comparten un único material (docs/07).
const PALETTE_MATERIAL: StringName = &"flat"
const PALETTE_SIZE: int = 32
var _palette: Array[Color] = []
var _nav_obstacles: Array[AABB] = []
var _material_cache: Dictionary[StringName, ShaderMaterial] = {}
var _object_cell: int = -1
var _variable_heights: bool = false
var _max_height: float = 0.0
var _palette_uv: Vector2 = Vector2(-1.0, -1.0)

static func build(def: LevelDef) -> Node3D:
	var builder: LevelBuilder = LevelBuilder.new()
	return builder._build(def)

func _build(def: LevelDef) -> Node3D:
	_def = def
	if not _validate():
		return null
	_height = def.rows.size()
	for row: String in def.rows:
		_width = maxi(_width, row.length())
	_root = Node3D.new()
	_root.name = def.name.capitalize().replace(" ", "") + "Geo"
	_collision = StaticBody3D.new()
	_collision.name = "Collision"
	_attach(_root, _collision)
	_markers = Node3D.new()
	_markers.name = "Markers"
	_attach(_root, _markers)
	_panels = [SurfaceData.new(), SurfaceData.new()]
	for r: int in range(_height):
		for c: int in range(_width):
			var symbol: String = def.rows[r].substr(c, 1) if c < def.rows[r].length() else " "
			var tile: Dictionary = {}
			if symbol != " " and def.tiles.has(symbol):
				tile = (def.tiles[symbol] as Dictionary).duplicate()
				# Un diccionario definido vacío sigue siendo una celda abierta.
				tile["_defined"] = true
			_grid.append(tile)
			if _open(tile):
				_variable_heights = _variable_heights or not is_equal_approx(_cell_height(tile), def.wall_height)
				_max_height = maxf(_max_height, _cell_height(tile))
	_floor_sum.resize(_grid.size())
	_floor_sum.fill(Color(0, 0, 0, 0))
	_floor_count.resize(_grid.size())
	_floor_count.fill(0)
	for r: int in range(_height):
		for c: int in range(_width):
			_emit_cell(c, r)
	for box: Dictionary in def.boxes:
		_emit_box(box)
	for prop: Dictionary in def.props:
		_emit_prop(prop)
	for light: Dictionary in def.lights:
		_add_light(light, false)
	for marker: String in def.markers:
		_add_marker(marker, def.markers[marker])
	_merge_collision()
	if def.open_void:
		_merge_slabs("floor")
		_merge_slabs("ceiling")
	else:
		var size: Vector3 = Vector3(_width * def.cell_size, 0.2, _height * def.cell_size)
		_shape(size, Vector3(size.x * 0.5, -0.1, size.z * 0.5))
		if _variable_heights:
			_merge_slabs("ceiling", true)
		else:
			_shape(size, Vector3(size.x * 0.5, def.wall_height + 0.1, size.z * 0.5))
	_bake()
	var vertex_count: int = 0
	for key: StringName in _surfaces:
		vertex_count += _surfaces[key].positions.size()
	if def.chunk_cells > 0:
		_emit_chunks()
	else:
		var mesh: ArrayMesh = ArrayMesh.new()
		for key: StringName in _surfaces:
			var data: SurfaceData = _surfaces[key]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data.arrays())
			mesh.surface_set_material(mesh.get_surface_count() - 1, _shared_material(key))
			mesh.surface_set_name(mesh.get_surface_count() - 1, String(key))
		var geometry: MeshInstance3D = MeshInstance3D.new()
		geometry.name = "Geometry"
		geometry.mesh = mesh
		_attach(_root, geometry)
		_emit_panels()
	_navigation_meta()
	_root.set_meta("lights", _lights)
	_root.set_meta("cell_size", def.cell_size)
	_root.set_meta("rows", def.rows)
	_root.set_meta("build_stats", {"cells": _grid.size(), "vertices": vertex_count, "lights": _lights.size()})
	return _root

func _validate() -> bool:
	if _def == null or _def.name.is_empty() or _def.name.validate_filename() != _def.name:
		push_error("LevelDef: nombre inválido.")
		return false
	if _def.rows.is_empty() or not _positive(_def.cell_size) or not _positive(_def.wall_height):
		push_error("LevelDef: mapa vacío o dimensiones inválidas.")
		return false
	if _def.chunk_cells < 0 or not is_finite(_def.visibility_range) or _def.visibility_range < 0.0 or not _positive(_def.void_skirt_depth):
		push_error("LevelDef: bloques, visibilidad o grosor inválidos.")
		return false
	for symbol: Variant in _def.tiles:
		if not symbol is String or not _def.tiles[symbol] is Dictionary:
			push_error("LevelDef: tile inválido.")
			return false
		var tile: Dictionary = _def.tiles[symbol]
		if (tile.has("height") and not _number(tile["height"])) or not _positive(_cell_height(tile)) or (bool(tile.get("door", false)) and _cell_height(tile) < DOOR_HEIGHT):
			push_error("LevelDef: altura de tile inválida.")
			return false
		for key: String in ["nav", "solid", "door"]:
			if tile.has(key) and not tile[key] is bool:
				push_error("LevelDef: " + key + " debe ser bool.")
				return false
		if tile.has("edge") and not (tile["edge"] is StringName or tile["edge"] is String):
			push_error("LevelDef: edge debe ser nombre de material.")
			return false
		if tile.has("zone") and (not tile["zone"] is String or String(tile["zone"]).is_empty()):
			push_error("LevelDef: zone debe ser nombre no vacío.")
			return false
		if tile.has("zones"):
			if not tile["zones"] is Array:
				push_error("LevelDef: zones debe ser Array[String].")
				return false
			for zone: Variant in tile["zones"]:
				if not zone is String or String(zone).is_empty():
					push_error("LevelDef: nombre de zona inválido.")
					return false
		if tile.has("light"):
			if not tile["light"] is Dictionary:
				push_error("LevelDef: light debe ser Dictionary.")
				return false
			var light: Dictionary = tile["light"]
			if (light.has("panel") and not light["panel"] is bool) or (light.has("height") and (not _number(light["height"]) or not _positive(float(light["height"])))):
				push_error("LevelDef: panel o altura de luz inválidos.")
				return false
	for prop: Dictionary in _def.props:
		if prop.has("tilt"):
			if not prop["tilt"] is Vector3:
				push_error("LevelDef: tilt debe ser Vector3.")
				return false
			var tilt: Vector3 = prop["tilt"]
			if not tilt.is_finite() or not is_zero_approx(tilt.y):
				push_error("LevelDef: tilt finito en X/Z; usar rot_y para Y.")
				return false
	var has_cells: bool = false
	for row: String in _def.rows:
		has_cells = has_cells or not row.is_empty()
	if not has_cells:
		push_error("LevelDef: mapa sin columnas.")
		return false
	for box: Dictionary in _def.boxes:
		if not box.get("pos") is Vector3 or not box.get("size") is Vector3:
			push_error("LevelDef: caja sin pos/size Vector3.")
			return false
		var size: Vector3 = box["size"]
		if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
			push_error("LevelDef: caja con tamaño no positivo.")
			return false
	for light: Dictionary in _def.lights:
		if not light.get("pos") is Vector3 or float(light.get("radius", 0.0)) <= 0.0:
			push_error("LevelDef: luz sin posición o radio positivo.")
			return false
	for key: String in _def.markers:
		if key.is_empty() or not _def.markers[key] is Vector3:
			push_error("LevelDef: marcador inválido.")
			return false
	return true

func _attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root

func _tile(c: int, r: int) -> Dictionary:
	if c < 0 or r < 0 or c >= _width or r >= _height:
		return {}
	return _grid[r * _width + c]

func _open(tile: Dictionary) -> bool:
	return not tile.is_empty() and not bool(tile.get("solid", false))

func _emit_cell(c: int, r: int) -> void:
	var tile: Dictionary = _tile(c, r)
	if not _open(tile):
		return
	var cs: float = _def.cell_size
	var x: float = c * cs
	var z: float = r * cs
	var cell: int = r * _width + c
	var height: float = _cell_height(tile)
	var top: float = _clearance(tile)
	if tile.has("floor"):
		_face(tile["floor"], Vector3(x, 0, z), Vector3(cs, 0, 0), Vector3(0, 0, cs), Vector3.UP, cell, 0)
	if tile.has("ceiling") and not bool(tile.get("door", false)):
		_face(tile["ceiling"], Vector3(x, height, z), Vector3(cs, 0, 0), Vector3(0, 0, cs), Vector3.DOWN, cell, 1)
	if bool(tile.get("door", false)):
		_face(tile.get("wall", &"default"), Vector3(x, DOOR_HEIGHT, z), Vector3(cs, 0, 0), Vector3(0, 0, cs), Vector3.DOWN, cell, 2)
		if height > DOOR_HEIGHT:
			_shape(Vector3(cs, height - DOOR_HEIGHT, cs), Vector3(x + cs * 0.5, (DOOR_HEIGHT + height) * 0.5, z + cs * 0.5))
	if _def.open_void and tile.has("floor"):
		_face(tile.get("edge", tile["floor"]), Vector3(x, -_def.void_skirt_depth, z), Vector3(cs, 0, 0), Vector3(0, 0, cs), Vector3.DOWN, cell, 3)
	for dir: Vector2i in DIRS:
		var neighbour: Dictionary = _tile(c + dir.x, r + dir.y)
		var bottom: float = 0.0
		var mat: StringName
		if _def.open_void and tile.has("floor") and (not _open(neighbour) or not neighbour.has("floor")) and not bool(neighbour.get("solid", false)):
			var skirt: Vector3 = Vector3(x, -_def.void_skirt_depth, z)
			var edge_along: Vector3 = Vector3(cs, 0, 0)
			if dir.x != 0:
				skirt.x += cs if dir.x > 0 else 0.0
				edge_along = Vector3(0, 0, cs)
			elif dir.y > 0:
				skirt.z += cs
			_face(tile.get("edge", tile["floor"]), skirt, edge_along, Vector3(0, _def.void_skirt_depth, 0), Vector3(dir.x, 0, dir.y), cell, 3)
		if neighbour.is_empty():
			if not tile.has("void_wall"):
				continue
			mat = tile["void_wall"]
		elif bool(neighbour.get("solid", false)):
			mat = neighbour.get("wall", &"default")
		elif _clearance(neighbour) < top:
			bottom = _clearance(neighbour)
			mat = neighbour.get("wall", &"default")
		else:
			continue
		var origin: Vector3 = Vector3(x, bottom, z)
		var along: Vector3 = Vector3(cs, 0, 0)
		if dir.x != 0:
			origin.x += cs if dir.x > 0 else 0.0
			along = Vector3(0, 0, cs)
		elif dir.y > 0:
			origin.z += cs
		_face(mat, origin, along, Vector3(0, top - bottom, 0), Vector3(-dir.x, 0, -dir.y), cell, 2)
		if (bottom > 0.0 and not bool(neighbour.get("door", false))) or (_def.open_void and neighbour.is_empty()):
			var depth: Vector3 = Vector3(0.04 if dir.x != 0 else cs, top - bottom, cs if dir.x != 0 else 0.04)
			_shape(depth, origin + along * 0.5 + Vector3(0, (top - bottom) * 0.5, 0))
		if bottom == 0.0 and _def.baseboard_height > 0.0:
			var inward: Vector3 = Vector3(-dir.x, 0, -dir.y)
			_palette_uv = Vector2((_palette_index(_def.baseboard_tint) + 0.5) / PALETTE_SIZE, 0.5)
			_face(PALETTE_MATERIAL, origin + inward * 0.012, along, Vector3(0, _def.baseboard_height, 0), inward, cell, 3)
			_palette_uv = Vector2(-1.0, -1.0)
	if tile.has("marker"):
		_add_marker(String(tile["marker"]), Vector3(x + cs * 0.5, 0, z + cs * 0.5))
	if tile.has("light"):
		var light: Dictionary = tile["light"].duplicate()
		light["pos"] = Vector3(x + cs * 0.5, float(light.get("height", height - 0.02)), z + cs * 0.5)
		_add_light(light, bool(light.get("panel", true)))

func _face(material: StringName, origin: Vector3, u: Vector3, v: Vector3, normal: Vector3, cell: int, kind: int, fit: bool = false, transform: Transform3D = Transform3D.IDENTITY) -> void:
	if not _surfaces.has(material):
		_surfaces[material] = SurfaceData.new()
	var data: SurfaceData = _surfaces[material]
	var settings: Dictionary = _def.materials.get(material, {})
	var scale_uv: float = maxf(float(settings.get("uv_scale", 2.0)), 0.001)
	_append_face(data, origin, u, v, normal, cell, kind, fit, transform, scale_uv)

func _append_face(data: SurfaceData, origin: Vector3, u: Vector3, v: Vector3, normal: Vector3, cell: int, kind: int, fit: bool, transform: Transform3D, scale_uv: float, color: Color = Color(0, 0, 0, 0), panel_energy: float = 0.0) -> void:
	var nu: int = maxi(1, ceili(u.length() / STEP))
	var nv: int = maxi(1, ceili(v.length() / STEP))
	var start: int = data.positions.size()
	var world_normal: Vector3 = transform.basis * normal
	for j: int in range(nv + 1):
		for i: int in range(nu + 1):
			var a: float = float(i) / nu
			var b: float = float(j) / nv
			var local: Vector3 = origin + u * a + v * b
			var p: Vector3 = transform * local
			var uv: Vector2
			if _palette_uv.x >= 0.0:
				uv = _palette_uv
			elif fit:
				uv = Vector2(a, 1.0 - b)
			elif absf(normal.y) > 0.5:
				uv = Vector2(p.x, p.z) / scale_uv
			else:
				uv = Vector2(p.dot((transform.basis * u).normalized()), p.y) / scale_uv
			data.positions.append(p)
			data.normals.append(world_normal)
			data.uvs.append(uv)
			data.uv2s.append(Vector2(panel_energy, 0))
			data.colors.append(color)
			data.cells.append(cell)
			data.chunks.append(cell if cell >= 0 else _object_cell)
			data.kinds.append(kind)
	var reverse: bool = u.cross(v).dot(normal) > 0.0
	for j: int in range(nv):
		for i: int in range(nu):
			var a: int = start + j * (nu + 1) + i
			var b: int = a + 1
			var d: int = a + nu + 1
			var e: int = d + 1
			# Godot usa el orden horario para las caras visibles.
			data.indices.append_array(PackedInt32Array([a, e, b, a, d, e] if reverse else [a, b, e, a, e, d]))

func _emit_box(box: Dictionary) -> void:
	var center: Vector3 = box["pos"]
	var size: Vector3 = box["size"]
	_object_cell = _position_cell(center)
	var angle: float = deg_to_rad(float(box.get("rot_y", 0.0)))
	var transform: Transform3D = Transform3D(Basis(Vector3.UP, angle), center)
	var p: Vector3 = -size * 0.5
	var material: StringName = box.get("material", &"default")
	var fit: bool = bool(box.get("uv_fit", false))
	if box.has("tint"):
		material = PALETTE_MATERIAL
		_palette_uv = Vector2((_palette_index(box["tint"]) + 0.5) / PALETTE_SIZE, 0.5)
	_face(material, p, Vector3(size.x, 0, 0), Vector3(0, size.y, 0), Vector3.FORWARD, -1, 3, fit, transform)
	_face(material, p + Vector3(0, 0, size.z), Vector3(size.x, 0, 0), Vector3(0, size.y, 0), Vector3.BACK, -1, 3, fit, transform)
	_face(material, p, Vector3(0, 0, size.z), Vector3(0, size.y, 0), Vector3.LEFT, -1, 3, fit, transform)
	_face(material, p + Vector3(size.x, 0, 0), Vector3(0, 0, size.z), Vector3(0, size.y, 0), Vector3.RIGHT, -1, 3, fit, transform)
	_face(material, p + Vector3(0, size.y, 0), Vector3(size.x, 0, 0), Vector3(0, 0, size.z), Vector3.UP, -1, 3, fit, transform)
	if absf(center.y - size.y * 0.5) > 0.05:
		_face(material, p, Vector3(size.x, 0, 0), Vector3(0, 0, size.z), Vector3.DOWN, -1, 3, fit, transform)
	_palette_uv = Vector2(-1.0, -1.0)
	if bool(box.get("collide", true)):
		_shape(size, center, angle)
		_nav_obstacles.append(transform * AABB(-size * 0.5, size))
	if bool(box.get("occlude", false)):
		if is_zero_approx(angle):
			_occluders.append(AABB(center - size * 0.5, size))
		else:
			push_warning("Caja rotada: occlude se ignora (solo AABB sin rotación).")

func _shape(size: Vector3, center: Vector3, angle: float = 0.0) -> void:
	var node: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	node.shape = shape
	node.position = center
	node.rotation.y = angle
	_attach(_collision, node)

func _merge_collision() -> void:
	var active: Dictionary[Vector2i, Rect2i] = {}
	for r: int in range(_height + 1):
		var next: Dictionary[Vector2i, Rect2i] = {}
		var c: int = 0
		while r < _height and c < _width:
			if not bool(_tile(c, r).get("solid", false)):
				c += 1
				continue
			var first: int = c
			while c < _width and bool(_tile(c, r).get("solid", false)):
				c += 1
			var key: Vector2i = Vector2i(first, c - first)
			var rect: Rect2i = active.get(key, Rect2i(first, r, c - first, 0))
			rect.size.y += 1
			next[key] = rect
		for key: Vector2i in active:
			if not next.has(key):
				var rect: Rect2i = active[key]
				var cs: float = _def.cell_size
				_shape(Vector3(rect.size.x * cs, maxf(_max_height, _def.wall_height), rect.size.y * cs), Vector3((rect.position.x + rect.size.x * 0.5) * cs, maxf(_max_height, _def.wall_height) * 0.5, (rect.position.y + rect.size.y * 0.5) * cs))
		active = next

func _add_marker(base: String, pos: Vector3) -> void:
	if base.is_empty():
		return
	var count: int = _marker_counts.get(base, 0) + 1
	var candidate: String = base if count == 1 else base + "_" + str(count)
	while _markers.has_node(NodePath(candidate)):
		count += 1
		candidate = base + "_" + str(count)
	_marker_counts[base] = count
	var node: Marker3D = Marker3D.new()
	node.name = candidate
	node.position = pos
	_attach(_markers, node)

func _add_light(input: Dictionary, panel: bool) -> void:
	var light: Dictionary = {"pos": input["pos"], "color": input.get("color", Color.WHITE), "energy": float(input.get("energy", 1.0)), "radius": float(input.get("radius", 6.0)), "flicker": bool(input.get("flicker", false))}
	if light["radius"] <= 0.0:
		push_warning("Luz de panel con radio no positivo: se omite.")
		return
	var index: int = _lights.size()
	_lights.append(light)
	var pos: Vector3 = light["pos"]
	_object_cell = _position_cell(pos)
	var samples: PackedVector3Array = PackedVector3Array([pos])
	if panel:
		var cs: float = _def.cell_size
		samples.append_array(PackedVector3Array([pos + Vector3(cs * 0.3, 0, 0), pos - Vector3(cs * 0.3, 0, 0), pos + Vector3(0, 0, cs * 0.15), pos - Vector3(0, 0, cs * 0.15)]))
		var color: Color = light["color"]
		color.a = 1.0
		# Carcasa modelada fundida en la paleta; el difusor queda detrás de la rejilla.
		_emit_prop({"model": "ceiling_fixture", "pos": Vector3(pos.x, pos.y + 0.02, pos.z), "collide": false})
		_append_face(_panels[1 if light["flicker"] else 0], Vector3(pos.x - 0.59, pos.y - 0.04, pos.z - 0.29), Vector3(1.18, 0, 0), Vector3(0, 0, 0.58), Vector3.DOWN, -1, 4, true, Transform3D.IDENTITY, 1.0, color, light["energy"])
	_samples.append(samples)
	var radius: float = light["radius"]
	var lo: Vector2i = _cell(pos - Vector3(radius, 0, radius))
	var hi: Vector2i = _cell(pos + Vector3(radius, 0, radius))
	for r: int in range(lo.y, hi.y + 1):
		for c: int in range(lo.x, hi.x + 1):
			var key: Vector2i = Vector2i(c, r)
			if not _buckets.has(key):
				_buckets[key] = []
			_buckets[key].append(index)

func _cell(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / _def.cell_size), floori(p.z / _def.cell_size))

func _direct(p: Vector3, n: Vector3) -> Color:
	var result: Color = Color(0, 0, 0, 0)
	var nearby: Array = _buckets.get(_cell(p), [])
	for index: int in nearby:
		var light: Dictionary = _lights[index]
		var delta: Vector3 = light["pos"] - p
		var distance: float = delta.length()
		var radius: float = light["radius"]
		if distance >= radius:
			continue
		var direction: Vector3 = delta / maxf(distance, 0.0001)
		var lambert: float = maxf(0.0, (n.dot(direction) + 0.3) / 1.3)
		if lambert <= 0.0:
			continue
		var visible: int = 0
		var samples: PackedVector3Array = _samples[index]
		for sample: Vector3 in samples:
			if _visible(p + n * 0.05, sample):
				visible += 1
		var factor: float = float(light["energy"]) * lambert * pow(1.0 - distance / radius, 2.0) * float(visible) / samples.size()
		var color: Color = light["color"]
		if light["flicker"]:
			result.a += (color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722) * factor
		else:
			result.r += color.r * factor
			result.g += color.g * factor
			result.b += color.b * factor
	return result

func _visible(start: Vector3, finish: Vector3) -> bool:
	for box: AABB in _occluders:
		if _segment_box(start, finish, box):
			return false
	var delta: Vector3 = finish - start
	var cell: Vector2i = _cell(start)
	var step_x: int = 1 if delta.x > 0.0 else -1
	var step_z: int = 1 if delta.z > 0.0 else -1
	var tx_delta: float = _def.cell_size / absf(delta.x) if absf(delta.x) > 0.000001 else INF
	var tz_delta: float = _def.cell_size / absf(delta.z) if absf(delta.z) > 0.000001 else INF
	var tx: float = ((cell.x + (1 if step_x > 0 else 0)) * _def.cell_size - start.x) / delta.x if tx_delta < INF else INF
	var tz: float = ((cell.y + (1 if step_z > 0 else 0)) * _def.cell_size - start.z) / delta.z if tz_delta < INF else INF
	var entry: float = 0.0
	while entry < 1.0:
		var end: float = minf(1.0, minf(tx, tz))
		var tile: Dictionary = _tile(cell.x, cell.y)
		if end > entry + 0.000001:
			if (tile.is_empty() and not _def.open_void) or bool(tile.get("solid", false)):
				return false
			if _open(tile) and (bool(tile.get("door", false)) or _variable_heights) and maxf(start.y + delta.y * entry, start.y + delta.y * end) > _clearance(tile):
				return false
		if end >= 1.0:
			break
		entry = end
		# Ambas dimensiones avanzan en los cruces exactos de esquina.
		var cross_x: bool = tx <= tz + 0.000001
		var cross_z: bool = tz <= tx + 0.000001
		if cross_x:
			cell.x += step_x
			tx += tx_delta
		if cross_z:
			cell.y += step_z
			tz += tz_delta
	return true

func _segment_box(start: Vector3, finish: Vector3, box: AABB) -> bool:
	var delta: Vector3 = finish - start
	var lo: float = 0.0
	var hi: float = 1.0
	for axis: int in range(3):
		if absf(delta[axis]) < 0.000001:
			if start[axis] < box.position[axis] or start[axis] > box.end[axis]:
				return false
		else:
			var a: float = (box.position[axis] - start[axis]) / delta[axis]
			var b: float = (box.end[axis] - start[axis]) / delta[axis]
			lo = maxf(lo, minf(a, b))
			hi = minf(hi, maxf(a, b))
			if hi < lo:
				return false
	return hi > 0.00001 and lo < 0.99999

## RGB = luz fija / 2; alfa = luminancia parpadeante / 2.
## ArrayMesh almacena COLOR en UNORM8: error de decodificación < 2/255.
## GLES3 copia el atributo sin conversión sRGB; el shader usa un varying explícito.
## Verificado en GPU contra emisión constante con el mismo error de cuantización.
func _bake() -> void:
	for key: StringName in _surfaces:
		var data: SurfaceData = _surfaces[key]
		var settings: Dictionary = _def.materials.get(key, {})
		if bool(settings.get("emissive", false)):
			continue
		for i: int in range(data.positions.size()):
			var direct: Color = _direct(data.positions[i], data.normals[i])
			data.colors[i] = direct
			var cell: int = data.cells[i]
			if data.kinds[i] == 0 and cell >= 0:
				_floor_sum[cell] += direct
				_floor_count[cell] += 1
	var averages: PackedColorArray = PackedColorArray()
	averages.resize(_grid.size())
	averages.fill(Color(0, 0, 0, 0))
	for cell: int in range(_grid.size()):
		if _floor_count[cell] > 0:
			_floor_sum[cell] /= float(_floor_count[cell])
	for r: int in range(_height):
		for c: int in range(_width):
			if not _open(_tile(c, r)):
				continue
			var sum: Color = Color(0, 0, 0, 0)
			var count: int = 0
			for dr: int in range(-1, 2):
				for dc: int in range(-1, 2):
					if _open(_tile(c + dc, r + dr)):
						sum += _floor_sum[(r + dr) * _width + c + dc]
						count += 1
			averages[r * _width + c] = sum / maxf(count, 1)
	var ambient: Color = Color(_def.ambient.r, _def.ambient.g, _def.ambient.b, 0)
	for key: StringName in _surfaces:
		var data: SurfaceData = _surfaces[key]
		if bool((_def.materials.get(key, {}) as Dictionary).get("emissive", false)):
			continue
		for i: int in range(data.positions.size()):
			var cell: int = data.cells[i]
			if cell < 0:
				var coords: Vector2i = _cell(data.positions[i] + data.normals[i] * 0.05)
				if _open(_tile(coords.x, coords.y)):
					cell = coords.y * _width + coords.x
			var value: Color = data.colors[i] + ambient
			if cell >= 0:
				value += averages[cell] * _def.bounce * (2.0 if data.kinds[i] == 1 else 1.0)
			value *= _ao(data.positions[i], data.normals[i], cell, data.kinds[i]) * 0.5
			data.colors[i] = Color(clampf(value.r, 0, 1), clampf(value.g, 0, 1), clampf(value.b, 0, 1), clampf(value.a, 0, 1))

func _ao(p: Vector3, n: Vector3, cell: int, kind: int) -> float:
	if kind == 3:
		return 0.75 if absf(n.y) < 0.5 and absf(p.y) < 0.05 else 1.0
	if cell < 0:
		return 1.0
	var c: int = cell % _width
	var r: int = cell / _width
	var near_walls: int = 0
	for dir: Vector2i in DIRS:
		var tile: Dictionary = _tile(c + dir.x, r + dir.y)
		var boundary: float = (c + (1 if dir.x > 0 else 0)) * _def.cell_size if dir.x != 0 else (r + (1 if dir.y > 0 else 0)) * _def.cell_size
		var coordinate: float = p.x if dir.x != 0 else p.z
		if absf(coordinate - boundary) < 0.001 and (bool(tile.get("solid", false)) or (tile.is_empty() and _grid[cell].has("void_wall"))):
			near_walls += 1
	var result: float = 1.0
	if (near_walls > 0 or kind == 2) and (absf(p.y) < 0.001 or absf(p.y - _cell_height(_grid[cell])) < 0.001):
		result *= 0.72
	if near_walls >= 2 and absf(n.y) < 0.5:
		result *= 0.8
	return result

## Superficies de los modelos con tratamiento emisivo: nombre del material en Blender → material del nivel.
const SPECIAL_MATERIALS: Dictionary[String, StringName] = {"Flame": &"flame", "Glow": &"glow"}

## Funde un modelo .glb en la malla del nivel: cada material de Blender pasa a ser un tinte de la
## paleta, así el modelo recibe la luz horneada y no añade materiales (docs/07).
func _emit_prop(prop: Dictionary) -> void:
	var path: String = "res://assets/models/%s.glb" % prop["model"]
	var packed: PackedScene = load(path) as PackedScene if ResourceLoader.exists(path) else null
	if packed == null:
		push_error("Modelo no encontrado: " + path)
		return
	var instance: Node3D = packed.instantiate() as Node3D
	_object_cell = _position_cell(prop["pos"])
	var angle: float = deg_to_rad(float(prop.get("rot_y", 0.0)))
	var scale: float = float(prop.get("scale", 1.0))
	var tilt: Vector3 = prop.get("tilt", Vector3.ZERO)
	var basis: Basis = Basis(Vector3.UP, angle)
	if not tilt.is_zero_approx():
		basis = basis * Basis(Vector3.RIGHT, deg_to_rad(tilt.x)) * Basis(Vector3.BACK, deg_to_rad(tilt.z))
	var placement: Transform3D = Transform3D(basis.scaled(Vector3.ONE * scale), prop["pos"])
	var local_bounds: AABB = AABB()
	var has_bounds: bool = false
	var screen_sum: Vector3 = Vector3.ZERO
	var screen_normal: Vector3 = Vector3.ZERO
	var screen_count: int = 0
	for node: Node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var local: Transform3D = _transform_to_root(mesh_instance, instance)
		var world: Transform3D = placement * local
		var normal_basis: Basis = world.basis.inverse().transposed()
		for surface: int in mesh_instance.mesh.get_surface_count():
			var arrays: Array = mesh_instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var source_uvs: Variant = arrays[Mesh.ARRAY_TEX_UV]
			var source_indices: Variant = arrays[Mesh.ARRAY_INDEX]
			var material: Material = mesh_instance.get_active_material(surface)
			var material_name: String = material.resource_name if material != null else ""
			var key: StringName = PALETTE_MATERIAL
			var swatch: Vector2 = Vector2(-1.0, -1.0)
			var is_screen: bool = material_name == "Screen"
			if is_screen and _def.materials.has(prop.get("screen_material", &"screen")):
				key = prop.get("screen_material", &"screen")
			elif SPECIAL_MATERIALS.has(material_name) and _def.materials.has(SPECIAL_MATERIALS[material_name]):
				key = SPECIAL_MATERIALS[material_name]
			else:
				var albedo: Color = (material as BaseMaterial3D).albedo_color if material is BaseMaterial3D else Color(0.6, 0.6, 0.6)
				var overrides: Dictionary = prop.get("tints", {})
				if overrides.has(material_name):
					albedo = overrides[material_name]
				swatch = Vector2((_palette_index(Color(albedo.r, albedo.g, albedo.b)) + 0.5) / PALETTE_SIZE, 0.5)
			if not _surfaces.has(key):
				_surfaces[key] = SurfaceData.new()
			var data: SurfaceData = _surfaces[key]
			var start: int = data.positions.size()
			for i: int in vertices.size():
				var position: Vector3 = world * vertices[i]
				var normal: Vector3 = (normal_basis * normals[i]).normalized()
				data.positions.append(position)
				data.normals.append(normal)
				data.uvs.append(swatch if swatch.x >= 0.0 else (source_uvs as PackedVector2Array)[i] if source_uvs != null else Vector2.ZERO)
				data.uv2s.append(Vector2.ZERO)
				data.colors.append(Color(0, 0, 0, 0))
				data.cells.append(-1)
				data.chunks.append(_object_cell)
				data.kinds.append(3)
				var in_model: Vector3 = local * vertices[i]
				if has_bounds:
					local_bounds = local_bounds.expand(in_model)
				else:
					local_bounds = AABB(in_model, Vector3.ZERO)
					has_bounds = true
				if is_screen:
					screen_sum += position
					screen_normal += normal
					screen_count += 1
			if source_indices != null:
				for index: int in (source_indices as PackedInt32Array):
					data.indices.append(start + index)
			else:
				for i: int in vertices.size():
					data.indices.append(start + i)
	instance.free()
	if not has_bounds:
		return
	if prop.has("screen_marker") and screen_count > 0:
		_add_marker(String(prop["screen_marker"]), screen_sum / screen_count + screen_normal.normalized() * 0.004)
	var center: Vector3 = placement * local_bounds.get_center()
	var size: Vector3 = local_bounds.size * scale
	var world_bounds: AABB = placement * local_bounds
	if bool(prop.get("collide", true)):
		if tilt.is_zero_approx():
			_shape(size, center, angle)
		else:
			_shape(world_bounds.size, world_bounds.get_center())
		_nav_obstacles.append(world_bounds)
	if bool(prop.get("occlude", false)):
		if not tilt.is_zero_approx():
			_occluders.append(world_bounds)
			return
		var quarter_turns: float = angle / (PI * 0.5)
		if is_equal_approx(quarter_turns, roundf(quarter_turns)):
			var footprint: Vector3 = size if int(roundf(quarter_turns)) % 2 == 0 else Vector3(size.z, size.y, size.x)
			_occluders.append(AABB(center - footprint * 0.5, footprint))
		else:
			push_warning("Modelo girado: occlude se ignora (solo giros de 90°).")

func _transform_to_root(node: Node3D, root: Node3D) -> Transform3D:
	var result: Transform3D = Transform3D.IDENTITY
	var current: Node3D = node
	while current != null and current != root:
		result = current.transform * result
		current = current.get_parent() as Node3D
	return root.transform * result if current == root else result

func _palette_index(tint: Color) -> int:
	var index: int = _palette.find(tint)
	if index < 0:
		if _palette.size() >= PALETTE_SIZE:
			push_warning("Paleta llena: se reutiliza el último tinte.")
			return PALETTE_SIZE - 1
		_palette.append(tint)
		index = _palette.size() - 1
	return index

func _palette_texture() -> ImageTexture:
	var image: Image = Image.create(PALETTE_SIZE, 1, false, Image.FORMAT_RGB8)
	for i: int in _palette.size():
		image.set_pixel(i, 0, _palette[i])
	return ImageTexture.create_from_image(image)

func _material(key: StringName) -> ShaderMaterial:
	var settings: Dictionary = _def.materials.get(key, {})
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/baked_surface.gdshader") as Shader
	if key == PALETTE_MATERIAL and not _palette.is_empty():
		material.set_shader_parameter("albedo_tex", _palette_texture())
	material.set_shader_parameter("tint", settings.get("tint", Color.WHITE))
	material.set_shader_parameter("flicker_color", _def.flicker_color)
	material.set_shader_parameter("texture_gain", float(settings.get("texture_gain", 1.0)))
	material.set_shader_parameter("texture_saturation", float(settings.get("texture_saturation", 1.0)))
	if bool(settings.get("emissive", false)):
		material.set_shader_parameter("unlit_energy", float(settings.get("energy", 1.0)))
		material.set_shader_parameter("emissive_side", float(settings.get("reality_side", 0.0)))
	if _def.dual_reality:
		material.set_shader_parameter("dual", true)
		var alt_path: String = settings.get("alt_texture", "")
		if not alt_path.is_empty() and ResourceLoader.exists(alt_path):
			material.set_shader_parameter("alt_tex", load(alt_path))
			material.set_shader_parameter("alt_tint", settings.get("alt_tint", Color.WHITE))
			material.set_shader_parameter("alt_uv", float(settings.get("uv_scale", 2.0)) / maxf(float(settings.get("alt_uv_scale", 2.0)), 0.001))
		elif key == PALETTE_MATERIAL and not _palette.is_empty():
			material.set_shader_parameter("alt_tex", _palette_texture())
		elif not String(settings.get("texture", "")).is_empty() and ResourceLoader.exists(settings["texture"]):
			material.set_shader_parameter("alt_tex", load(settings["texture"]))
			material.set_shader_parameter("alt_tint", settings.get("tint", Color.WHITE))
		else:
			material.set_shader_parameter("alt_tint", settings.get("tint", Color.WHITE))
	var path: String = settings.get("texture", "")
	if not path.is_empty():
		if ResourceLoader.exists(path):
			var texture: Texture2D = load(path) as Texture2D
			if texture != null:
				material.set_shader_parameter("albedo_tex", texture)
			else:
				push_warning("Textura incompatible, se usa tinte: " + path)
		else:
			push_warning("Textura pendiente, se usa tinte: " + path)
	return material

func _emit_panels() -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	for group: int in range(2):
		var data: SurfaceData = _panels[group]
		if data.positions.is_empty():
			# Triángulo degenerado para conservar los índices steady=0/flicker=1.
			data.positions = PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
			data.normals = PackedVector3Array([Vector3.DOWN, Vector3.DOWN, Vector3.DOWN])
			data.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0)])
			data.uvs = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
			data.uv2s = data.uvs
			data.indices = PackedInt32Array([0, 1, 2])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data.arrays())
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load("res://shaders/light_panel.gdshader") as Shader
		material.set_shader_parameter("flicker", group == 1)
		material.set_shader_parameter("dual", _def.dual_reality)
		mesh.surface_set_material(group, material)
	var panels: MeshInstance3D = MeshInstance3D.new()
	panels.name = "LightPanels"
	panels.mesh = mesh
	_attach(_root, panels)

## Altura geométrica y altura libre: las puertas mantienen su dintel de 2.1 m.
func _cell_height(tile: Dictionary) -> float:
	return float(tile.get("height", _def.wall_height))

func _clearance(tile: Dictionary) -> float:
	return DOOR_HEIGHT if bool(tile.get("door", false)) else _cell_height(tile)

func _number(value: Variant) -> bool:
	return value is float or value is int

func _positive(value: float) -> bool:
	return is_finite(value) and value > 0.0

func _position_cell(pos: Vector3) -> int:
	var coords: Vector2i = _cell(pos)
	# Los objetos fuera del mapa se asignan al bloque de borde más cercano.
	return clampi(coords.y, 0, _height - 1) * _width + clampi(coords.x, 0, _width - 1)

## Fusiona losas de la misma altura en rectángulos, sin cubrir huecos.
func _merge_slabs(kind: String, all_open: bool = false) -> void:
	var active: Dictionary[Vector3i, Rect2i] = {}
	var heights: Dictionary[Vector3i, float] = {}
	for r: int in range(_height + 1):
		var next: Dictionary[Vector3i, Rect2i] = {}
		var c: int = 0
		while r < _height and c < _width:
			var tile: Dictionary = _tile(c, r)
			if not _open(tile) or (not all_open and not tile.has(kind)):
				c += 1
				continue
			var height: float = 0.0 if kind == "floor" else _clearance(tile)
			var first: int = c
			c += 1
			while c < _width:
				var neighbour: Dictionary = _tile(c, r)
				if not _open(neighbour) or (not all_open and not neighbour.has(kind)) or (kind == "ceiling" and not is_equal_approx(_clearance(neighbour), height)):
					break
				c += 1
			# El identificador de altura evita fusionar techos distintos entre filas.
			var key: Vector3i = Vector3i(first, c - first, 0)
			while heights.has(key) and not is_equal_approx(heights[key], height):
				key.z += 1
			heights[key] = height
			var rect: Rect2i = active.get(key, Rect2i(first, r, c - first, 0))
			rect.size.y += 1
			next[key] = rect
		for key: Vector3i in active:
			if not next.has(key):
				var rect: Rect2i = active[key]
				var cs: float = _def.cell_size
				var thickness: float = _def.void_skirt_depth if kind == "floor" and _def.open_void else 0.2
				var y: float = -thickness * 0.5 if kind == "floor" else heights[key] + thickness * 0.5
				_shape(Vector3(rect.size.x * cs, thickness, rect.size.y * cs), Vector3((rect.position.x + rect.size.x * 0.5) * cs, y, (rect.position.y + rect.size.y * 0.5) * cs))
		active = next

func _navigation_meta() -> void:
	var heights: PackedFloat32Array = PackedFloat32Array()
	var walkable: PackedByteArray = PackedByteArray()
	var zones: Dictionary = {}
	for index: int in _grid.size():
		var tile: Dictionary = _grid[index]
		var coords: Vector2i = Vector2i(index % _width, index / _width)
		heights.append(_cell_height(tile) if not tile.is_empty() else 0.0)
		var can_walk: bool = _open(tile) and tile.has("floor") and _clearance(tile) >= 2.0 and bool(tile.get("nav", true))
		var center: Vector3 = Vector3((coords.x + 0.5) * _def.cell_size, 0, (coords.y + 0.5) * _def.cell_size)
		if can_walk:
			for obstacle: AABB in _nav_obstacles:
				if center.x + 0.3 >= obstacle.position.x and center.x - 0.3 <= obstacle.end.x and center.z + 0.3 >= obstacle.position.z and center.z - 0.3 <= obstacle.end.z:
					can_walk = false
					break
		walkable.append(1 if can_walk else 0)
		var names: Array[String] = []
		if tile.has("zone"):
			names.append(tile["zone"])
		for zone: String in tile.get("zones", []):
			if not names.has(zone):
				names.append(zone)
		for zone: String in names:
			if not zones.has(zone):
				var cells: Array[Vector2i] = []
				zones[zone] = cells
			(zones[zone] as Array[Vector2i]).append(coords)
	_root.set_meta("grid_width", _width)
	_root.set_meta("grid_height", _height)
	_root.set_meta("cell_heights", heights)
	_root.set_meta("walkable", walkable)
	_root.set_meta("zones", zones)

func _shared_material(key: StringName) -> ShaderMaterial:
	if not _material_cache.has(key):
		_material_cache[key] = _material(key)
	return _material_cache[key]

## Copia cada vértice una vez por bloque, conservando atributos y orden de triángulos.
func _partition(source: SurfaceData) -> Dictionary[Vector2i, SurfaceData]:
	var result: Dictionary[Vector2i, SurfaceData] = {}
	var remaps: Dictionary = {}
	for index: int in source.indices:
		var cell: int = source.chunks[index]
		var coords: Vector2i = Vector2i(cell % _width, cell / _width)
		var chunk: Vector2i = Vector2i(coords.x / _def.chunk_cells, coords.y / _def.chunk_cells)
		if not result.has(chunk):
			result[chunk] = SurfaceData.new()
			remaps[chunk] = {}
		var target: SurfaceData = result[chunk]
		var remap: Dictionary = remaps[chunk]
		if not remap.has(index):
			remap[index] = target.positions.size()
			target.positions.append(source.positions[index])
			target.normals.append(source.normals[index])
			target.uvs.append(source.uvs[index])
			target.uv2s.append(source.uv2s[index])
			target.colors.append(source.colors[index])
		target.indices.append(remap[index])
	return result

func _set_range(instance: MeshInstance3D) -> void:
	if _def.visibility_range > 0.0:
		instance.visibility_range_end = _def.visibility_range
		instance.visibility_range_end_margin = minf(_def.visibility_range * 0.1, _def.cell_size * _def.chunk_cells)
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

func _emit_chunks() -> void:
	var chunks: Node3D = Node3D.new()
	chunks.name = "Chunks"
	_attach(_root, chunks)
	var meshes: Dictionary[Vector2i, ArrayMesh] = {}
	for key: StringName in _surfaces:
		var pieces: Dictionary[Vector2i, SurfaceData] = _partition(_surfaces[key])
		for chunk: Vector2i in pieces:
			if not meshes.has(chunk):
				meshes[chunk] = ArrayMesh.new()
			var mesh: ArrayMesh = meshes[chunk]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, pieces[chunk].arrays())
			mesh.surface_set_material(mesh.get_surface_count() - 1, _shared_material(key))
			mesh.surface_set_name(mesh.get_surface_count() - 1, String(key))
	var nodes: Dictionary[Vector2i, MeshInstance3D] = {}
	for chunk: Vector2i in meshes:
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.name = "Chunk_%d_%d" % [chunk.x, chunk.y]
		instance.mesh = meshes[chunk]
		_set_range(instance)
		_attach(chunks, instance)
		nodes[chunk] = instance
	# Los difusores siguen el bloque de su luminaria y comparten dos materiales.
	var panel_meshes: Dictionary[Vector2i, ArrayMesh] = {}
	for group: int in range(2):
		var pieces: Dictionary[Vector2i, SurfaceData] = _partition(_panels[group])
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load("res://shaders/light_panel.gdshader") as Shader
		material.set_shader_parameter("flicker", group == 1)
		for chunk: Vector2i in pieces:
			if not panel_meshes.has(chunk):
				panel_meshes[chunk] = ArrayMesh.new()
			var mesh: ArrayMesh = panel_meshes[chunk]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, pieces[chunk].arrays())
			mesh.surface_set_material(mesh.get_surface_count() - 1, material)
			mesh.surface_set_name(mesh.get_surface_count() - 1, "flicker" if group == 1 else "steady")
	for chunk: Vector2i in panel_meshes:
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.name = "LightPanels"
		instance.mesh = panel_meshes[chunk]
		_set_range(instance)
		_attach(nodes[chunk], instance)
