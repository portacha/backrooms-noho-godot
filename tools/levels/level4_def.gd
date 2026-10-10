extends LevelDef
## El Umbral del Mictlán: oficinas suspendidas, papel picado y una salida en el vacío.

var _grid: Array[PackedStringArray] = []

func _init() -> void:
	name = "level4"
	open_void = true
	void_skirt_depth = 0.8
	chunk_cells = 6
	visibility_range = 48.0
	baseboard_height = 0.0
	ambient = Color(0.045, 0.039, 0.05)
	bounce = 0.2
	materials = {
		&"carpet": {"texture": "res://assets/textures/office_carpet_torn.png", "uv_scale": 1.0},
		&"rock": {"texture": "res://assets/textures/cavern_rock.png", "uv_scale": 1.0},
		&"paper": {"texture": "res://assets/textures/papel_picado.png", "uv_scale": 1.0},
		&"flame": {"emissive": true, "tint": Color(1.0, 0.48, 0.1), "energy": 2.2},
	}
	tiles = {
		"I": {"floor": &"carpet", "edge": &"rock"},
		"R": {"floor": &"carpet", "edge": &"rock", "zone": "remanso"},
		"B": {"floor": &"paper", "edge": &"paper", "zone": "bridge"},
	}
	for z: int in 78:
		var line: PackedStringArray = PackedStringArray()
		for x: int in 40:
			line.append(" ")
		_grid.append(line)
	_island(4, 4, 3, "I")
	_island(20, 12, 2, "I")
	_island(10, 26, 3, "R")
	_island(30, 34, 3, "I")
	_island(30, 72, 2, "I")
	_island(30, 23, 1, "I") # Presencia distante, sin conexión con el jugador.
	_bridge(Vector2i(4, 7), Vector2i(4, 12), 0)
	_bridge(Vector2i(4, 12), Vector2i(18, 12), -1)
	_bridge(Vector2i(20, 15), Vector2i(20, 20), 1)
	_bridge(Vector2i(20, 20), Vector2i(10, 20), -1)
	_bridge(Vector2i(10, 20), Vector2i(10, 23), -1)
	_bridge(Vector2i(10, 30), Vector2i(10, 34), 2)
	_bridge(Vector2i(10, 34), Vector2i(27, 34), -1)
	_bridge(Vector2i(30, 38), Vector2i(30, 69), 3)
	# Ramales falsos: suelo real, sin sendero de pétalos, terminan en el abismo.
	_bridge(Vector2i(4, 12), Vector2i(4, 18), -2)
	_bridge(Vector2i(15, 20), Vector2i(15, 16), -2)
	_bridge(Vector2i(18, 34), Vector2i(18, 39), -2)
	for line: PackedStringArray in _grid:
		rows.append("".join(line))
	markers.merge({
		"start": Vector3(9, 0, 9), "cp_start": Vector3(9, 0, 9), "cp_start_look": Vector3(9, 0, 25),
		"cp_r1": Vector3(21, 0, 53), "cp_r1_look": Vector3(21, 0, 69),
		"cp_altar": Vector3(61, 0, 67), "cp_altar_look": Vector3(61, 1.5, 70),
		"letter": Vector3(61, 1.55, 70), "altar": Vector3(61, 0, 69),
		"door": Vector3(61, 0, 145), "neon": Vector3(61, 4.3, 145),
		"d13": Vector3(6.1, 0.78, 10), "d14": Vector3(21.55, 1.0, 61), "d15": Vector3(62.6, 1.3, 144.5),
		"presence_trigger": Vector3(47, 0, 69), "presence": Vector3(61, 0, 47),
		"chase_from": Vector3(61, 0, 67),
	})
	_prop("desk_office", Vector3(6, 0, 10), {"tilt": Vector3(0, 0, 4)})
	# Dorso de fotografía y página arrancada: superficies realmente planas.
	boxes.append({"pos": markers["d13"], "size": Vector3(0.25, 0.012, 0.18), "material": &"flat", "tint": Color(0.8, 0.72, 0.58), "collide": false})
	_prop("papel_picado_string", Vector3(21.6, 1.15, 61), {"rot_y": 90.0, "collide": false})
	boxes.append({"pos": markers["d14"], "size": Vector3(0.25, 0.3, 0.01), "material": &"flat", "tint": Color(0.82, 0.75, 0.6), "collide": false})
	_prop("sign_wall", markers["d15"], {"rot_y": 180.0, "collide": false})
	for at: Vector3 in [Vector3(9, 0, 12), Vector3(21, 0, 53), Vector3(61, 0, 70)]:
		for i: int in 12:
			_prop("candle_mid", at + Vector3(-2.4 + (i % 2) * 4.8, 0, (i / 2) * 0.24 - 0.7), {"collide": false})
		lights.append({"pos": at + Vector3.UP, "color": Color(1, 0.55, 0.2), "energy": 1.2, "radius": 9.0, "panel": false})

func _island(x: int, z: int, radius: int, tile: String) -> void:
	for row: int in range(z - radius, z + radius + 1):
		for column: int in range(x - radius, x + radius + 1):
			if absi(column - x) == radius and absi(row - z) == radius:
				continue
			_grid[row][column] = tile
			_prop("island_underside", Vector3(column * 2 + 1, -0.75, row * 2 + 1), {"collide": false})
	var center: Vector3 = Vector3(x * 2 + 1, 0, z * 2 + 1)
	_prop("door_frame_lone", center + Vector3(-2.5, 0, -1.5), {"collide": false, "tilt": Vector3(0, 0, -7)})
	_prop("filing_cabinet", center + Vector3(2.5, 0, 1), {"tilt": Vector3(8, 0, 4)})
	_prop("chair_office", center + Vector3(-2.4, 0, 2), {"tilt": Vector3(0, 0, 19)})
	_prop("stalagmite", center + Vector3(2.7, 0, -2.5))

func _bridge(from: Vector2i, to: Vector2i, id: int) -> void:
	var direction: Vector2i = (to - from).sign()
	var count: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
	if id >= 0:
		var at: Vector3 = Vector3(from.x * 2 + 1, 0, from.y * 2 + 1)
		markers["bridge_%d" % id] = at
		markers["bridge_%d_look" % id] = at + Vector3(direction.x, 0, direction.y) * 2
		_prop("petal_cairn", at + Vector3(0.72, 0, 0.0), {"collide": false})
		lights.append({"pos": at + Vector3(0.7, 0.7, 0), "color": Color(1, 0.48, 0.15), "energy": 0.8, "radius": 6.0, "panel": false})
	for i: int in count + 1:
		var cell: Vector2i = from + direction * i
		if _grid[cell.y][cell.x] != " ":
			continue
		_grid[cell.y][cell.x] = "B"
		var at: Vector3 = Vector3(cell.x * 2 + 1, 0, cell.y * 2 + 1)
		_prop("papel_picado_bridge", at + Vector3(0, -0.035, 0), {"collide": false})
		if id != -2:
			markers["path_%d" % markers.size()] = at

func _prop(model: String, at: Vector3, extra: Dictionary = {}) -> void:
	var prop: Dictionary = {"model": model, "pos": at}
	prop.merge(extra)
	props.append(prop)
