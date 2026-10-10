class_name EntityNav
extends RefCounted
## Rejilla erosionada junto a paredes/refugios, con vértices compartidos.
static func build(geo: Node3D, blocked: Array[AABB]) -> NavigationRegion3D:
	var rows: PackedStringArray = geo.get_meta("rows", PackedStringArray())
	var width: int = int(geo.get_meta("grid_width", 0))
	var height: int = int(geo.get_meta("grid_height", rows.size()))
	var size: float = float(geo.get_meta("cell_size", 2.0))
	for row: String in rows:
		width = maxi(width, row.length())
	var grid: PackedByteArray = geo.get_meta("walkable", PackedByteArray())
	if grid.is_empty():
		grid.resize(width * height)
		for z: int in height:
			for x: int in width:
				grid[z * width + x] = int(x < rows[z].length() and rows[z][x] != "#" and rows[z][x] != " ")
	# Dilatación conservadora de bloqueos; incluye los 2 m de escucha en conductos.
	for z: int in height:
		for x: int in width:
			var cell: AABB = AABB(geo.to_global(Vector3(x * size, 0, z * size)), Vector3(size, 2.6, size))
			for zone: AABB in blocked:
				if cell.intersects(zone.grow(0.4)):
					grid[z * width + x] = 0
	# Subceldas uniformes: aristas idénticas también en esquinas y pilares.
	var divisions: int = maxi(2, ceili(size / 0.4))
	var unit: float = size / divisions
	var fine_width: int = width * divisions
	var fine_height: int = height * divisions
	var fine: PackedByteArray = PackedByteArray()
	fine.resize(fine_width * fine_height)
	for z: int in fine_height:
		for x: int in fine_width:
			var valid: bool = true
			for dz: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var gx: int = floori(float(x + dx) / divisions)
					var gz: int = floori(float(z + dz) / divisions)
					if gx < 0 or gz < 0 or gx >= width or gz >= height or grid[gz * width + gx] == 0:
						valid = false
			fine[z * fine_width + x] = int(valid)
	var mesh: NavigationMesh = NavigationMesh.new()
	mesh.agent_radius = 0.4
	var vertices: PackedVector3Array = PackedVector3Array()
	var polygons: Array[PackedInt32Array] = []
	var indices: Dictionary[Vector2i, int] = {}
	var centres: PackedVector3Array = PackedVector3Array()
	for z: int in fine_height:
		for x: int in fine_width:
			if fine[z * fine_width + x] == 0:
				continue
			var polygon: PackedInt32Array = PackedInt32Array()
			for corner: Vector2i in [Vector2i(x, z + 1), Vector2i(x + 1, z + 1), Vector2i(x + 1, z), Vector2i(x, z)]:
				if not indices.has(corner):
					indices[corner] = vertices.size()
					vertices.append(Vector3(corner.x * unit, 0, corner.y * unit))
				polygon.append(indices[corner])
			polygons.append(polygon)
			centres.append(Vector3((x + 0.5) * unit, 0, (z + 0.5) * unit))
	mesh.vertices = vertices
	for polygon: PackedInt32Array in polygons:
		mesh.add_polygon(polygon)
	var region: NavigationRegion3D = NavigationRegion3D.new()
	region.name = "EntityNavigation"
	region.navigation_mesh = mesh
	region.set_meta("centres", centres)
	geo.add_child(region)
	return region

static func random_point(region: NavigationRegion3D) -> Vector3:
	var centres: PackedVector3Array = region.get_meta("centres", PackedVector3Array())
	return region.to_global(centres[randi() % centres.size()]) if not centres.is_empty() else region.global_position
