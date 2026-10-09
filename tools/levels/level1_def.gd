extends LevelDef
## Nivel 1 — "El Laberinto de Papel Tapiz" (docs/04, docs/12 §8.1).
## Backrooms clásicos: papel tapiz amarillento, alfombra húmeda, fluorescentes a parches.

const PAPER: Color = Color(0.88, 0.86, 0.78)
const CANDLES: Array[String] = ["candle_short", "candle_mid", "candle_tall"]
## Alturas del mostrador de recepción (`reception_counter`): frente elevado y encimera.
const COUNTER_FRONT_HEIGHT: float = 1.05
const DESK_HEIGHT: float = 0.74


func _init() -> void:
	name = "level1"
	cell_size = 2.0
	wall_height = 2.8
	ambient = Color(0.012, 0.011, 0.007)
	bounce = 0.45
	baseboard_tint = Color(0.5, 0.42, 0.18)
	rows = PackedStringArray([
		"###############################",
		"#..L..#.....#...F...#....L....#",
		"#.##..#.###.#.#####.#.######..#",
		"#.#..L..#.....#...#...#....#.##",
		"#.#.###.#.###.#.#.###.#.##.#..#",
		"#...#.....#.L.#.#.....#..#.L..#",
		"###.#.###.#.###.#####.##.#.##.#",
		"#...#.#L..#.........#....#..#.#",
		"#.###.#.#####D#####.####.##.#.#",
		"#.#...#.#.........#....#..#.#.#",
		"#.#.###.#.........#.##.##.#.#.#",
		"#.#.....#.........#..#....#L#.#",
		"#.#####.#.........#.###.###.#.#",
		"#.....#.#.........#...#.#...#.#",
		"#.###.#.###########.#.#.#.###.#",
		"#.#.#.#.....#.......#.#.#.###.#",
		"#.#.#.#####.#.#######.#...###.#",
		"#.#.#.....#.#.....L...###.###.#",
		"#.#.#####.#.#####.###...#.###.#",
		"#...#..L..#.....#...#.#.#...#.#",
		"###.#.###.#####.###.#.#.###.#.#",
		"#...#.#.......#...#...#...#...#",
		"#######.##.##.###.#######.#.#.#",
		"#.L...#..L....#.....F.....#...#",
		"#.....#.##.##.#.###########.###",
		"#..L..D.......D...............#",
		"###############################",
	])
	_sprinkle_lights()
	var steady: Dictionary = {"color": Color(1.0, 0.95, 0.74), "energy": 1.1, "radius": 9.0, "flicker": false}
	var flicker: Dictionary = {"color": Color(1.0, 0.95, 0.74), "energy": 1.1, "radius": 9.0, "flicker": true}
	tiles = {
		"#": {"solid": true, "wall": &"wallpaper"},
		".": {"floor": &"carpet", "ceiling": &"ceiling"},
		"L": {"floor": &"carpet", "ceiling": &"ceiling", "light": steady},
		"F": {"floor": &"carpet", "ceiling": &"ceiling", "light": flicker},
		"D": {"floor": &"carpet", "ceiling": &"ceiling", "door": true, "wall": &"wallpaper"},
	}
	materials = {
		&"wallpaper": {"texture": "res://assets/textures/backrooms_wallpaper.png", "uv_scale": 1.5},
		&"carpet": {"texture": "res://assets/textures/backrooms_carpet.png", "uv_scale": 2.0},
		&"ceiling": {"texture": "res://assets/textures/backrooms_ceiling.png", "uv_scale": 1.2},
		&"flame": {"emissive": true, "tint": Color(1.0, 0.72, 0.3), "energy": 2.4},
	}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1142

	# Recepción de entrada: la linterna espera sobre el mostrador (docs/12 §8.1).
	var reception: Vector3 = cell(10, 23)
	_prop("reception_small", reception, 0.0, {"occlude": true})
	markers["flashlight"] = reception + Vector3(0.25, 1.0, 0.22)
	lights.append({"pos": reception + Vector3(0.25, 1.5, 0.3), "color": Color(0.8, 0.9, 1.0), "energy": 0.5, "radius": 3.5, "flicker": false})

	# Remanso: puesto ahogado entre veladoras (D04).
	var nook: Vector3 = cell(3, 15)
	_prop("desk_office", nook + Vector3(0.0, 0.0, -0.58), 0.0, {"occlude": true})
	_prop("chair_tipped", nook + Vector3(0.45, 0.0, 0.75), 70.0)
	_flat(nook + Vector3(-0.25, DESK_HEIGHT + 0.006, -0.5), Vector3(0.3, 0.012, 0.21), PAPER, false)
	_candles(rng, nook + Vector3(-0.2, DESK_HEIGHT, -0.6), Vector2(0.45, 0.22), 9, 0.18)
	_candles(rng, nook + Vector3(-0.2, 0.0, 0.35), Vector2(0.7, 0.4), 16)
	lights.append({"pos": nook + Vector3(0.0, 1.0, -0.3), "color": Color(1.0, 0.6, 0.25), "energy": 1.3, "radius": 7.0, "flicker": false})
	markers["d04"] = nook + Vector3(-0.25, DESK_HEIGHT + 0.04, -0.5)
	markers["remanso"] = nook

	# Sala central anómala: mostrador de recepción bajo las veladoras + la letra N.
	# El lado público del mostrador mira al norte, por donde entra el jugador.
	var altar: Vector3 = cell(13, 11)
	_prop("reception_counter", altar, 180.0, {"occlude": true})
	_candles(rng, altar + Vector3(0.0, COUNTER_FRONT_HEIGHT, -0.36), Vector2(1.4, 0.06), 22, 0.32)
	_candles(rng, altar + Vector3(0.0, 0.0, -1.15), Vector2(2.2, 0.45), 40)
	_candles(rng, altar + Vector3(0.0, 0.0, 1.15), Vector2(2.2, 0.45), 24)
	_candles(rng, altar + Vector3(2.2, 0.0, 0.0), Vector2(0.45, 1.1), 16)
	_candles(rng, altar + Vector3(-2.2, 0.0, 0.0), Vector2(0.45, 1.1), 16)
	lights.append({"pos": altar + Vector3(0.0, 1.5, 1.0), "color": Color(1.0, 0.6, 0.25), "energy": 1.5, "radius": 10.0, "flicker": false})
	lights.append({"pos": altar + Vector3(0.0, 1.5, -1.0), "color": Color(1.0, 0.6, 0.25), "energy": 1.5, "radius": 10.0, "flicker": false})
	lights.append({"pos": altar + Vector3(0.0, 1.7, 0.0), "color": Color(1.0, 0.25, 0.7), "energy": 0.5, "radius": 5.0, "flicker": false})
	markers["letter"] = altar + Vector3(0.0, 1.62, -0.3)
	markers["altar"] = altar

	# Esquina con polvo naranja de pétalos (D05).
	var corner: Vector3 = cell(29, 1)
	_flat(corner + Vector3(0.3, 0.008, -0.3), Vector3(0.21, 0.012, 0.3), PAPER, false)
	_candles(rng, corner + Vector3(0.55, 0.0, -0.6), Vector2(0.2, 0.2), 3)
	markers["d05"] = corner + Vector3(0.3, 0.05, -0.3)
	# Inscripción rayada junto a la entrada de la sala central (D06).
	markers["d06"] = Vector3(25.0, 1.45, 15.96)

	_dress(rng)
	_build_signs()
	markers["start"] = cell(2, 24)
	# Pasillo en bucle (docs/07): columna 29, recta de la fila 5 a la 21.
	markers["loop_trigger"] = cell(29, 11)
		# Polvo de pétalos: uno de cada siete rincones (celda abierta con muro en dos lados contiguos).
	var corner_count: int = 0
	var petal_count: int = 0
	for row: int in rows.size():
		for column: int in rows[row].length():
			if rows[row][column] == "#" or not _is_corner(column, row):
				continue
			corner_count += 1
			if corner_count % 7 == 3:
				markers["petals_%d" % petal_count] = cell(column, row)
				petal_count += 1
	var mirror_cells: Array[Vector2i] = [Vector2i(20, 23), Vector2i(23, 19), Vector2i(21, 14), Vector2i(19, 9), Vector2i(29, 16)]
	for i: int in mirror_cells.size():
		markers["mirror_%d" % i] = cell(mirror_cells[i].x, mirror_cells[i].y)


## Fluorescentes a parches: la mayoría del laberinto queda en penumbra amarilla y quedan
## bolsas de oscuridad (el cuadrante noreste, el pasillo en bucle y la sala central).
func _sprinkle_lights() -> void:
	for row: int in rows.size():
		var line: String = rows[row]
		for column: int in line.length():
			if line[column] != ".":
				continue
			var in_central: bool = column >= 9 and column <= 17 and row >= 9 and row <= 13
			var in_dark_quadrant: bool = column >= 20 and column <= 27 and row <= 6
			var in_loop: bool = column >= 28
			var in_nook: bool = column == 3 and row >= 15 and row <= 18
			if in_central or in_dark_quadrant or in_loop or in_nook:
				continue
			var roll: int = (column * 7 + row * 13 + column * row) % 11
			if roll == 0 or roll == 5:
				line[column] = "F" if (column + row * 3) % 9 == 0 else "L"
		rows[row] = line


## Mobiliario huérfano: pocas piezas, siempre solas y contra un rincón (liminalidad, docs/01).
func _dress(rng: RandomNumberGenerator) -> void:
	var spots: Array[Vector2i] = [
		Vector2i(1, 1), Vector2i(11, 1), Vector2i(17, 3), Vector2i(21, 7), Vector2i(1, 13), Vector2i(7, 15),
		Vector2i(15, 19), Vector2i(19, 23), Vector2i(23, 21), Vector2i(27, 25), Vector2i(9, 5), Vector2i(21, 13),
	]
	var kind: int = 0
	for spot: Vector2i in spots:
		if rows[spot.y][spot.x] == "#":
			continue
		var corner: Vector3 = _corner_direction(spot.x, spot.y)
		var at: Vector3 = cell(spot.x, spot.y) + corner * 0.6
		# Los muebles dan la espalda a la pared del fondo de su rincón.
		var facing: float = 180.0 if corner.z > 0.0 else 0.0
		match kind % 5:
			0:
				_prop("filing_cabinet", at, facing, {"occlude": true})
			1:
				_prop("chair_office", at - corner * 0.15, facing + 180.0 + rng.randf_range(-25.0, 25.0))
			2:
				_prop("box_cardboard_closed", at, rng.randf_range(-20.0, 20.0))
				_prop("box_cardboard_open", at + Vector3(0.03, 0.42, 0.02), rng.randf_range(10.0, 50.0), {"collide": false})
			3:
				_prop("ceiling_tile_fallen", cell(spot.x, spot.y) + Vector3(0.1, 0.0, -0.1), rng.randf_range(10.0, 50.0), {"collide": false})
			4:
				_prop("chair_tipped", at - corner * 0.2, rng.randf_range(0.0, 360.0))
		kind += 1


## Esquina de la celda con muro en ambos lados, o (1, 0, 1) si no hay ninguna.
func _corner_direction(column: int, row: int) -> Vector3:
	for direction: Vector2i in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		if rows[row][column + direction.x] == "#" and rows[row + direction.y][column] == "#":
			return Vector3(direction.x, 0.0, direction.y)
	return Vector3(1.0, 0.0, 1.0)


func _is_corner(column: int, row: int) -> bool:
	for direction: Vector2i in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		if rows[row][column + direction.x] == "#" and rows[row + direction.y][column] == "#" and rows[row][column] == ".":
			return true
	return false


## Centro de una celda a ras de suelo.
func cell(column: int, row: int) -> Vector3:
	return Vector3((column + 0.5) * cell_size, 0.0, (row + 0.5) * cell_size)


func _flat(pos: Vector3, size: Vector3, tint: Color, collide: bool = true, occlude: bool = false) -> void:
	boxes.append({"pos": pos, "size": size, "material": &"flat", "tint": tint, "collide": collide, "occlude": occlude})


## Señalética vieja de oficina hacia la "recepción" (la sala central): un letrero en la pared del
## fondo de cada recodo de la ruta principal, con la flecha hacia donde sigue el camino.
func _build_signs() -> void:
	var aged: Dictionary = {"Paper": Color(0.72, 0.66, 0.42), "Metal_Dark": Color(0.3, 0.27, 0.17), "Dark_Plastic": Color(0.16, 0.12, 0.06)}
	var route: Array[Vector2i] = [
		Vector2i(2, 24), Vector2i(5, 24), Vector2i(5, 25), Vector2i(15, 25), Vector2i(15, 23), Vector2i(25, 23),
		Vector2i(25, 21), Vector2i(23, 21), Vector2i(23, 18), Vector2i(21, 18), Vector2i(21, 13), Vector2i(19, 13),
		Vector2i(19, 7), Vector2i(13, 7), Vector2i(13, 9),
	]
	for i: int in range(1, route.size() - 1):
		var incoming: Vector2i = (route[i] - route[i - 1]).sign()
		var outgoing: Vector2i = (route[i + 1] - route[i]).sign()
		var ahead: Vector2i = route[i] + incoming
		# Solo en recodos con pared al fondo, y no en todos: la guía ayuda, no lleva de la mano.
		if rows[ahead.y][ahead.x] != "#" or i % 2 == 0:
			continue
		var facing: Vector3 = Vector3(-incoming.x, 0.0, -incoming.y)
		var right: Vector2i = Vector2i(-incoming.y, incoming.x)
		var at: Vector3 = cell(route[i].x, route[i].y) - facing * (cell_size * 0.5 - 0.012) + Vector3(0.0, 1.7, 0.0)
		add_sign("recepcion", at, facing, 1 if outgoing == right else -1, false, aged)
	# Colgante ante la entrada de la sala central.
	add_sign("hrecepcion", cell(13, 7) + Vector3(0.0, 2.37, 0.75), Vector3(0.0, 0.0, -1.0), 0, true, aged)
	# Y uno en la sala de llegada, junto a su única puerta.
	add_sign("recepcion", cell(5, 25) + Vector3(0.988, 1.7, -2.0), Vector3(-1.0, 0.0, 0.0), 1, false, aged)


func _prop(model: String, pos: Vector3, rot_y: float = 0.0, extra: Dictionary = {}) -> void:
	var prop: Dictionary = {"model": model, "pos": pos, "rot_y": rot_y}
	prop.merge(extra)
	props.append(prop)


## Veladoras modeladas (tres alturas) repartidas en un rectángulo (`half` = semiejes X/Z).
func _candles(rng: RandomNumberGenerator, center: Vector3, half: Vector2, count: int, exclude_radius: float = 0.0) -> void:
	for i: int in count:
		var offset: Vector3 = Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y))
		if exclude_radius > 0.0 and absf(offset.x) < exclude_radius:
			continue
		_prop(CANDLES[rng.randi() % CANDLES.size()], center + offset, rng.randf_range(0.0, 360.0), {"scale": rng.randf_range(0.85, 1.2), "collide": false})
