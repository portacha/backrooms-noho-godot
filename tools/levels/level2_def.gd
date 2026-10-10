extends LevelDef
## Nivel 2 — Las Ofrendas Infinitas: concreto inmenso y memoria administrativa.

const CANDLES: Array[String] = ["candle_short", "candle_mid", "candle_tall"]
const W: int = 35
const H: int = 25

func _init() -> void:
	name = "level2"
	cell_size = 2.0
	wall_height = 6.5
	chunk_cells = 8
	visibility_range = 30.0
	ambient = Color(0.006, 0.005, 0.004)
	bounce = 0.24
	baseboard_height = 0.0
	rows = PackedStringArray()
	for z: int in H:
		var line: String = ""
		for x: int in W:
			var edge: bool = x == 0 or z == 0 or x == W - 1 or z == H - 1
			# Entrada angosta que se abre a una sola nave continua.
			var entrance_wall: bool = z >= 19 and (x < 14 or x > 20)
			line += "#" if edge or entrance_wall else "."
		rows.append(line)

	var warm: Dictionary = {"color": Color(1.0, 0.46, 0.18), "energy": 1.65, "radius": 8.5, "flicker": false, "panel": false, "height": 5.8}
	var cold: Dictionary = {"color": Color(0.34, 0.55, 0.8), "energy": 0.52, "radius": 8.0, "flicker": true, "height": 6.18}
	tiles = {
		"#": {"solid": true, "wall": &"concrete"},
		".": {"floor": &"floor", "ceiling": &"ceiling", "height": 6.5},
		"L": {"floor": &"floor", "ceiling": &"ceiling", "height": 6.5, "light": warm, "zone": "remanso"},
		"A": {"floor": &"adobe", "ceiling": &"ceiling", "height": 6.5},
		"S": {"floor": &"stone", "ceiling": &"ceiling", "height": 6.5},
		"F": {"floor": &"floor", "ceiling": &"ceiling", "height": 6.5, "light": cold},
	}
	materials = {
		&"concrete": {"texture": "res://assets/textures/concrete_brutalist.png", "uv_scale": 1.5},
		&"floor": {"texture": "res://assets/textures/concrete_floor.png", "uv_scale": 2.0},
		&"ceiling": {"texture": "res://assets/textures/concrete_ceiling_dark.png", "uv_scale": 2.0},
		&"adobe": {"texture": "res://assets/textures/adobe_dark.png", "uv_scale": 1.5},
		&"stone": {"texture": "res://assets/textures/volcanic_stone.png", "uv_scale": 1.5},
		&"flame": {"emissive": true, "tint": Color(1.0, 0.48, 0.16), "energy": 2.2},
	}
	for p: Vector2i in [Vector2i(8, 17), Vector2i(25, 8), Vector2i(17, 4)]:
		var line: String = rows[p.y]
		line[p.x] = "L"
		rows[p.y] = line
	for p: Vector2i in [Vector2i(5, 5), Vector2i(5, 13), Vector2i(28, 20)]:
		var line: String = rows[p.y]
		line[p.x] = "A"
		rows[p.y] = line
	for p: Vector2i in [Vector2i(6, 5), Vector2i(28, 13), Vector2i(27, 20)]:
		var line: String = rows[p.y]
		line[p.x] = "S"
		rows[p.y] = line
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 207
	# Retícula de columnas modeladas bajo la nave alta.
	for z: int in range(3, 22, 4):
		for x: int in range(3, 32, 4):
			if (x >= 13 and x <= 21 and z >= 17) or (x >= 11 and x <= 24 and z >= 10 and z <= 15) or (x >= 15 and x <= 19 and z >= 3 and z <= 9):
				continue
			var at: Vector3 = cell(x, z)
			_prop("column_base", at, 0.0, {"collide": false})
			_prop("column_round", at + Vector3(0.0, 0.28, 0.0), 0.0, {"scale": 2.0, "occlude": true})
			_prop("column_capital", at + Vector3(0.0, 5.55, 0.0), 0.0, {"scale": 1.4, "collide": false})

	# Restos de cubículos y cimientos expuestos: tres faros cálidos separados.
	var shrines: Array[Vector3i] = [Vector3i(8, 17, 0), Vector3i(25, 8, 0), Vector3i(17, 4, 0)]
	for i: int in shrines.size():
		var cell_id: Vector3i = shrines[i]
		var at: Vector3 = cell(cell_id.x, cell_id.y)
		_build_offering(rng, at, i == 2)
		if i == 0:
			markers["d07"] = at + Vector3(0.0, 0.82, -0.3)
		if i == 1:
			markers["d08"] = at + Vector3(0.0, 0.05, 1.0)

	# Cimientos bajos: adobe y piedra volcánica entre los muebles huérfanos.
	for x: int in [5, 28]:
		for z: int in [5, 13, 20]:
			var ruin: Vector3 = cell(x, z)
			_prop("clay_wall_broken", ruin, 0.0, {"scale": 1.1, "occlude": true})
			_prop("stone_stele", ruin + Vector3(1.1, 0.0, 0.5), 12.0, {"scale": 0.8})
			_prop("adobe_rubble", ruin + Vector3(-0.7, 0.0, 0.7), 30.0, {"scale": 0.8, "collide": false})

	# Papel desprendido solo en el umbral de entrada.
	for x: int in range(15, 20):
		_prop("wallpaper_peel", cell(x, 22) + Vector3(0.0, 0.0, -0.88), 180.0, {"collide": false})

	# Restos de oficina integrados a la ofrenda principal.
	var altar: Vector3 = cell(17, 4)
	markers["altar"] = altar
	markers["letter"] = altar + Vector3(0.0, 4.3, 0.0)
	markers["d09"] = altar + Vector3(0.0, 0.08, 1.35)
	markers["start"] = cell(17, 23)
	markers["cp_start"] = markers["start"]
	markers["cp_start_look"] = cell(17, 20)
	markers["cp_r1"] = cell(8, 17) + Vector3(0.0, 0.0, 2.1)
	markers["cp_r1_look"] = cell(8, 17)
	markers["cp_r2"] = cell(17, 7)
	markers["cp_r2_look"] = altar
	markers["manifest_0"] = cell(18, 14) + Vector3(0.0, 0.0, 0.4)
	markers["manifest_1"] = cell(12, 11)
	markers["manifest_2"] = cell(25, 17)
	markers["manifest_3"] = cell(9, 7)
	markers["manifest_4"] = cell(21, 9)
	markers["manifest_5"] = cell(16, 13)
	for i: int in 8:
		markers["ambush_%d" % i] = cell([4, 29, 8, 27, 4, 30, 12, 23][i], [7, 6, 14, 18, 21, 12, 4, 21][i])
	# Cambios de silueta en el punto ciego: el nivel elige qué posiciones alternar.
	for i: int in 3:
		markers["mutation_%d" % i] = cell([8, 25, 17][i], [5, 9, 16][i])
	# Uno o dos tubos fríos, muy altos; el resto de la sala queda en sombra.
	for p: Vector2i in [Vector2i(7, 5), Vector2i(27, 18)]:
		var light_tile: String = rows[p.y]
		light_tile[p.x] = "F"
		rows[p.y] = light_tile
		lights.append({"pos": cell(p.x, p.y) + Vector3(0.0, 6.2, 0.0), "color": Color(0.38, 0.55, 0.75), "energy": 0.48, "radius": 7.0, "flicker": true})

func _build_offering(rng: RandomNumberGenerator, at: Vector3, pyramid: bool) -> void:
	# Archiveros, altar y restos de cubículo en una composición legible y baja.
	_prop("partition_panel", at + Vector3(-1.2, 0.0, -0.8), 0.0, {"scale": 0.9, "collide": false})
	_prop("desk_office", at + Vector3(2.0, 0.0, 0.2), 180.0, {"occlude": true})
	_prop("filing_cabinet", at + Vector3(-1.25, 0.0, -0.5), 0.0, {"occlude": true})
	_prop("ofrenda_arch", at + Vector3(0.0, 0.0, -0.25), 0.0, {"scale": 0.95, "collide": false})
	_prop("copal_censer", at + Vector3(1.1, 0.0, -0.8), 0.0, {"collide": false})
	_prop("pan_de_muerto", at + Vector3(-0.4, 0.76, -0.35), 25.0, {"collide": false})
	_prop("sugar_skull", at + Vector3(0.4, 0.78, -0.35), 0.0, {"collide": false})
	_prop("photo_frame_empty", at + Vector3(-1.7, 0.0, 0.4), 10.0, {"collide": false})
	_prop("marigold_pile", at + Vector3(-0.5, 0.0, 0.8), 0.0, {"scale": 1.1, "collide": false})
	_prop("papel_picado_string", at + Vector3(0.0, 2.5, -0.8), 0.0, {"collide": false})
	for i: int in 6:
		_prop(CANDLES[rng.randi() % CANDLES.size()], at + Vector3(rng.randf_range(-1.1, 1.1), 0.0, rng.randf_range(-0.7, 0.75)), 0.0, {"collide": false})
	lights.append({"pos": at + Vector3(0.0, 1.2, 0.0), "color": Color(1.0, 0.49, 0.2), "energy": 1.55, "radius": 8.0, "flicker": false})
	if pyramid:
		for x: int in range(-2, 3):
			_prop("cabinet_rusty_stack", at + Vector3(float(x) * 0.92, 0.0, 0.0), 0.0, {"scale": 1.0, "occlude": true})
		for x: int in range(-1, 2):
			_prop("filing_cabinet", at + Vector3(float(x) * 0.92, 1.55, 0.0), 0.0, {"scale": 0.88, "occlude": true})
		_prop("ofrenda_tier", at + Vector3(0.0, 2.75, -0.2), 0.0, {"collide": false})
		_prop("sugar_skull", at + Vector3(0.0, 3.15, -0.35), 0.0, {"collide": false})

func cell(x: int, z: int) -> Vector3:
	return Vector3((x + 0.5) * cell_size, 0.0, (z + 0.5) * cell_size)

func _prop(model: String, pos: Vector3, rot_y: float = 0.0, extra: Dictionary = {}) -> void:
	var prop: Dictionary = {"model": model, "pos": pos, "rot_y": rot_y}
	prop.merge(extra)
	props.append(prop)
