extends LevelDef
## Nivel 4 — "El Umbral del Mictlán" (docs/04, docs/12 §8.4). Contaminación 80 %.
## Fotografía: vacío índigo (nunca negro puro) con profundidad por niebla, pétalos que suben y
## restos de oficina flotando a distintas alturas. Cada isla tiene su propia luz: el tubo que aún
## parpadea en el jirón de backrooms de la llegada, las veladoras del remanso, el altar, y al
## fondo —visible desde el altar— el neón magenta de la puerta, único punto de fuga.

const WARM: Color = Color(1.0, 0.52, 0.18)
const MAGENTA: Color = Color(1.0, 0.16, 0.62)

var _grid: Array[PackedStringArray] = []

func _init() -> void:
	name = "level4"
	open_void = true
	void_skirt_depth = 0.8
	chunk_cells = 6
	visibility_range = 110.0
	wall_height = 2.7
	baseboard_height = 0.0
	ambient = Color(0.016, 0.013, 0.026)
	bounce = 0.3
	ao_strength = 2.0
	contact_strength = 0.6
	materials = {
		&"carpet": {"texture": "res://assets/textures/office_carpet_torn.png", "uv_scale": 2.0, "texture_saturation": 0.55},
		&"rock": {"texture": "res://assets/textures/cavern_rock.png", "uv_scale": 2.0, "texture_gain": 1.3},
		&"paper": {"texture": "res://assets/textures/papel_picado.png", "uv_scale": 2.0, "texture_saturation": 0.8},
		&"wallpaper": {"texture": "res://assets/textures/wallpaper_peeling.png", "uv_scale": 1.4},
		&"tiles": {"texture": "res://assets/textures/backrooms_ceiling.png", "uv_scale": 1.2},
		&"flame": {"emissive": true, "tint": Color(1.0, 0.6, 0.2), "energy": 2.6},
		&"glow": {"emissive": true, "tint": Color(1.0, 0.16, 0.62), "energy": 2.0},
	}
	var tube: Dictionary = {"color": Color(1.0, 0.95, 0.74), "energy": 1.0, "radius": 8.0, "flicker": true}
	tiles = {
		"I": {"floor": &"carpet", "edge": &"rock"},
		"R": {"floor": &"carpet", "edge": &"rock", "zone": "remanso"},
		"B": {"floor": &"paper", "edge": &"paper", "zone": "bridge"},
		# Jirones de backrooms que aún flotan: muro de papel tapiz y un trozo de techo con su tubo.
		"W": {"solid": true, "wall": &"wallpaper"},
		"C": {"floor": &"carpet", "edge": &"rock", "ceiling": &"tiles"},
		"L": {"floor": &"carpet", "edge": &"rock", "ceiling": &"tiles", "light": tube},
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
	_dress()
	for line: PackedStringArray in _grid:
		rows.append("".join(line))


func _island(x: int, z: int, radius: int, tile: String) -> void:
	for row: int in range(z - radius, z + radius + 1):
		for column: int in range(x - radius, x + radius + 1):
			if absi(column - x) == radius and absi(row - z) == radius:
				continue
			_grid[row][column] = tile
			if (column + row) % 2 == 0:
				_prop("island_underside", Vector3(column * 2 + 1, -0.8, row * 2 + 1), {"collide": false, "rot_y": 90.0 * ((column * 3 + row) % 4)})

func _bridge(from: Vector2i, to: Vector2i, id: int) -> void:
	var direction: Vector2i = (to - from).sign()
	var count: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
	if id >= 0:
		var at: Vector3 = Vector3(from.x * 2 + 1, 0, from.y * 2 + 1)
		markers["bridge_%d" % id] = at
		markers["bridge_%d_look" % id] = at + Vector3(direction.x, 0, direction.y) * 2
		_prop("petal_cairn", at + Vector3(0.72, 0, 0.0), {"collide": false})
		lights.append({"pos": at + Vector3(0.7, 0.6, 0), "color": WARM, "energy": 0.9, "radius": 5.0})
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


## Composición de cada isla, a mano: ninguna repite a otra.
func _dress() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 404
	# 1. Llegada: esquina de pasillo de backrooms arrancada de su edificio (muros al norte y al
	# oeste, un trozo de techo con el tubo parpadeando). De aquí se viene; hacia el vacío se va.
	for x: int in range(2, 7):
		_grid[1][x] = "W"
	for z: int in range(2, 7):
		_grid[z][1] = "W"
	for z: int in range(2, 5):
		for x: int in range(2, 5):
			_grid[z][x] = "C"
	_grid[3][3] = "L"
	_prop("desk_office", Vector3(6, 0, 10), {"tilt": Vector3(0, 0, 4)})
	_prop("chair_tipped", Vector3(7.6, 0, 11.4), {"rot_y": 60.0, "collide": false})
	_prop("filing_cabinet", Vector3(5.0, 0, 5.0), {"rot_y": 180.0})
	_prop("wallpaper_peel", Vector3(9.0, 1.4, 4.08), {"collide": false})
	_prop("exit_sign", Vector3(11.0, 2.2, 4.06), {"collide": false})
	boxes.append({"pos": markers["d13"], "size": Vector3(0.25, 0.012, 0.18), "material": &"flat", "tint": Color(0.8, 0.72, 0.58), "collide": false})
	_prop("candle_mid", Vector3(6.5, 0.74, 9.7), {"collide": false})
	lights.append({"pos": Vector3(6.4, 1.1, 9.9), "color": WARM, "energy": 0.6, "radius": 3.5})

	# 2. Isla de oficina: un puesto entero, intacto y solo, con la luminaria caída aún encendida.
	_prop("partition_panel", Vector3(39.0, 0, 23.6), {"collide": false})
	_prop("partition_panel", Vector3(37.4, 0, 25.0), {"rot_y": 90.0, "collide": false})
	_prop("desk_office", Vector3(39.2, 0, 24.6), {})
	_prop("chair_office", Vector3(39.4, 0, 25.9), {"rot_y": 200.0})
	_prop("terminal_crt", Vector3(39.2, 0.74, 24.5), {"collide": false})
	_prop("water_cooler", Vector3(44.0, 0, 27.0), {"tilt": Vector3(0, 0, 12)})
	_prop("ceiling_fixture", Vector3(42.6, 0.12, 22.6), {"rot_y": 35.0, "tilt": Vector3(180, 0, 9), "collide": false})
	lights.append({"pos": Vector3(42.6, 0.5, 22.6), "color": Color(0.85, 0.92, 1.0), "energy": 0.9, "radius": 7.0, "flicker": true})

	# 3. Remanso: la ofrenda. Arco, peldaños, veladoras por decenas: el charco de luz más cálido
	# del nivel, visible desde el primer puente.
	var remanso: Vector3 = Vector3(21, 0, 53)
	_prop("ofrenda_arch", remanso + Vector3(0, 0, -3.2), {"collide": false})
	_prop("ofrenda_tier", remanso + Vector3(0, 0, -3.4), {})
	_prop("ofrenda_tier", remanso + Vector3(0, 0.45, -3.7), {"scale": 0.7, "collide": false})
	_prop("copal_censer", remanso + Vector3(0, 0.45, -3.1), {"collide": false})
	_prop("sugar_skull", remanso + Vector3(-0.6, 0.45, -3.2), {"rot_y": 180.0, "collide": false})
	_prop("sugar_skull", remanso + Vector3(0.6, 0.45, -3.2), {"rot_y": 180.0, "collide": false})
	_prop("pan_de_muerto", remanso + Vector3(0.0, 0.77, -3.7), {"collide": false})
	_prop("photo_frame_empty", remanso + Vector3(-0.3, 0.77, -3.7), {"rot_y": 170.0, "collide": false})
	_prop("marigold_vase", remanso + Vector3(-1.5, 0, -3.0), {"collide": false})
	_prop("marigold_vase", remanso + Vector3(1.5, 0, -3.0), {"collide": false})
	_prop("marigold_pile", remanso + Vector3(-2.4, 0, -1.4), {"collide": false})
	_prop("marigold_pile", remanso + Vector3(2.6, 0, -1.9), {"rot_y": 70.0, "collide": false})
	_prop("papel_picado_string", remanso + Vector3(0, 2.75, -3.0), {"collide": false})
	_prop("bench_waiting", remanso + Vector3(-3.6, 0, 1.6), {"rot_y": 90.0})
	_candles(rng, remanso + Vector3(0, 0, -2.2), 26, Vector2(2.4, 0.5))
	_candles(rng, remanso + Vector3(0, 0, 1.2), 14, Vector2(3.4, 2.4))
	lights.append({"pos": remanso + Vector3(0, 1.0, -2.2), "color": WARM, "energy": 1.7, "radius": 10.0})
	lights.append({"pos": remanso + Vector3(0, 2.2, 0.5), "color": WARM, "energy": 0.8, "radius": 12.0})
	# D14 a mitad del puente siguiente: la página cuelga de un cordel de papel picado.
	_prop("papel_picado_string", Vector3(21.6, 1.55, 61), {"rot_y": 90.0, "collide": false})
	boxes.append({"pos": markers["d14"], "size": Vector3(0.012, 0.3, 0.22), "material": &"flat", "tint": Color(0.82, 0.75, 0.6), "collide": false})

	# 4. Isla del altar: la última O flota en mitad de un umbral de ofrendas. El eje queda libre:
	# a través de la letra, al fondo, se ve el neón de la puerta; por ahí se corre.
	var altar: Vector3 = markers["altar"]
	for side: float in [-1.0, 1.0]:
		_prop("ofrenda_tier", altar + Vector3(side * 2.5, 0, 1.0), {"rot_y": 90.0})
		_prop("ofrenda_tier", altar + Vector3(side * 2.75, 0.45, 1.0), {"rot_y": 90.0, "scale": 0.7, "collide": false})
		_prop("sugar_skull", altar + Vector3(side * 2.3, 0.45, 0.4), {"rot_y": -side * 90.0, "collide": false})
		_prop("sugar_skull", altar + Vector3(side * 2.3, 0.45, 1.6), {"rot_y": -side * 90.0, "collide": false})
		_prop("copal_censer", altar + Vector3(side * 2.7, 0.77, 1.0), {"collide": false})
		_prop("marigold_vase", altar + Vector3(side * 2.4, 0, 2.5), {"collide": false})
		_prop("marigold_vase", altar + Vector3(side * 2.4, 0, -0.5), {"collide": false})
		_prop("marigold_pile", altar + Vector3(side * 3.9, 0, 0.2), {"rot_y": side * 40.0, "collide": false})
		_prop("stalagmite", altar + Vector3(side * 5.4, 0, 2.6), {"rot_y": side * 90.0})
		_candles(rng, altar + Vector3(side * 1.75, 0, 1.0), 12, Vector2(0.25, 2.4))
	_prop("papel_picado_string", altar + Vector3(0, 3.0, 1.0), {"scale": 2.4, "collide": false})
	lights.append({"pos": altar + Vector3(0, 1.0, 0.6), "color": WARM, "energy": 1.4, "radius": 9.0})
	lights.append({"pos": altar + Vector3(0, 2.2, 1.0), "color": MAGENTA, "energy": 0.5, "radius": 7.0})

	# 5. Isla de la puerta: nada más que la puerta. El neón baña de magenta el final del puente.
	var door: Vector3 = markers["door"]
	_prop("sign_wall", markers["d15"], {"rot_y": 180.0, "collide": false})
	lights.append({"pos": door + Vector3(0, 3.6, -1.6), "color": MAGENTA, "energy": 1.8, "radius": 13.0})
	lights.append({"pos": door + Vector3(0, 1.0, -8.0), "color": MAGENTA, "energy": 0.6, "radius": 9.0})

	# 6. Isla inalcanzable (la presencia): un marco de puerta solo, a contraluz de una veladora.
	_prop("door_frame_lone", Vector3(61, 0, 47.6), {"collide": false})
	_prop("candle_tall", Vector3(62.0, 0, 48.4), {"collide": false})
	lights.append({"pos": Vector3(62.0, 0.6, 48.6), "color": WARM, "energy": 0.7, "radius": 5.0})

	_scatter_void(rng)


## Restos de oficina a la deriva en el vacío, a alturas distintas, fuera de los caminos. Unos
## pocos llevan su veladora: puntos cálidos lejanos que dan escala (y no se pueden alcanzar).
func _scatter_void(rng: RandomNumberGenerator) -> void:
	var models: Array[String] = ["desk_office", "chair_office", "filing_cabinet", "door_frame_lone", "partition_panel", "chair_tipped", "ceiling_tile_fallen", "box_cardboard_closed", "stalagmite"]
	var placed: int = 0
	var attempts: int = 0
	while placed < 46 and attempts < 600:
		attempts += 1
		var at: Vector3 = Vector3(rng.randf_range(-30.0, 110.0), rng.randf_range(-9.0, 12.0), rng.randf_range(-20.0, 175.0))
		if _near_floor(at, 7.0):
			continue
		placed += 1
		var model: String = models[rng.randi() % models.size()]
		_prop(model, at, {"rot_y": rng.randf_range(0.0, 360.0), "tilt": Vector3(rng.randf_range(-35.0, 35.0), 0, rng.randf_range(-35.0, 35.0)),
			"scale": rng.randf_range(0.9, 1.5), "collide": false})
		if placed % 3 == 0:
			_prop("candle_tall", at + Vector3(0.3, 0.95, 0.0), {"collide": false})
			lights.append({"pos": at + Vector3(0.4, 1.3, 0.3), "color": WARM, "energy": 1.6, "radius": 6.5})
		elif placed % 7 == 0:
			_prop("ceiling_fixture", at + Vector3(0, 2.6, 0), {"tilt": Vector3(0, 0, 14), "collide": false})
			lights.append({"pos": at + Vector3(0, 2.0, 0), "color": Color(0.8, 0.9, 1.0), "energy": 1.0, "radius": 6.0, "flicker": true})
		else:
			lights.append({"pos": at + Vector3(0, 2.5, 1.5), "color": Color(0.4, 0.32, 0.8), "energy": 0.9, "radius": 7.0})


## ¿Hay suelo (isla o puente) a menos de `margin` metros en planta?
func _near_floor(at: Vector3, margin: float) -> bool:
	var reach: int = ceili(margin / 2.0)
	var cx: int = floori(at.x / 2.0)
	var cz: int = floori(at.z / 2.0)
	for z: int in range(cz - reach, cz + reach + 1):
		for x: int in range(cx - reach, cx + reach + 1):
			if z >= 0 and z < _grid.size() and x >= 0 and x < _grid[z].size() and _grid[z][x] != " ":
				return true
	return false


func _candles(rng: RandomNumberGenerator, centre: Vector3, count: int, half: Vector2) -> void:
	for i: int in count:
		var model: String = ["candle_short", "candle_mid", "candle_tall"][rng.randi() % 3]
		_prop(model, centre + Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y)),
			{"rot_y": rng.randf_range(0.0, 360.0), "scale": rng.randf_range(0.9, 1.35), "collide": false})
