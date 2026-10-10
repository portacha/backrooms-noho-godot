extends LevelDef
## Nivel 3 — "El Pasaje de las Calaveras" (docs/04, docs/12 §8.3).
## Contaminación 50 %, en DOBLE REALIDAD: las mismas paredes tienen piel de backrooms (papel tapiz,
## alfombra, fluorescentes: lo que la mente del oficinista pone para soportarlo) y piel real
## (túnel inundado). El guion del nivel las alterna con parpadeos y apagones; no hay frontera.
## Túnel de mantenimiento inundado. Fotografía: negro húmedo, fosforescencia cian de las
## calaveras como única luz clave (charcos cada 16 m con tramos negros entre ellos), cempasúchil
## naranja flotando como acento, y lo cálido reservado a refugios (veladora en cada boca de
## conducto) y a la cámara de barro, cuyo resplandor es el punto de fuga del último tramo.

const CYAN: Color = Color(0.28, 0.82, 0.9)
const WARM: Color = Color(1.0, 0.5, 0.18)
const MAGENTA: Color = Color(1.0, 0.25, 0.7)
const TUNNEL_HEIGHT: float = 3.4
const SKULL_STEP: int = 8
## El agua va en un cauce: el suelo de las celdas inundadas baja y la lámina queda por debajo del
## suelo seco (`Level3.WATER_LEVEL`), nunca posada encima.
const BED: float = -0.24
const SURFACE: float = -0.06
const FLOATING: Array[String] = ["marigold", "candle", "copal", "wallet"]
## Tramos rectos: (columna izquierda, fila inicial, fila final).
const SECTIONS: Array[Vector3i] = [Vector3i(3, 4, 16), Vector3i(10, 23, 41), Vector3i(18, 48, 68)]


func _init() -> void:
	name = "level3"
	wall_height = TUNNEL_HEIGHT
	baseboard_height = 0.0
	chunk_cells = 8
	visibility_range = 46.0
	ambient = Color(0.006, 0.010, 0.012)
	bounce = 0.28
	ao_strength = 2.6
	contact_strength = 0.6
	dual_reality = true
	flicker_color = Color(1.0, 0.93, 0.7)
	var wallpaper: String = "res://assets/textures/backrooms_wallpaper.png"
	# Cada superficie lleva dos pieles: la real (túnel) y la de backrooms que la mente le pone.
	materials = {
		&"wall": {"texture": "res://assets/textures/tunnel_concrete_wet.png", "uv_scale": 3.4, "normal_texture": "res://assets/textures/tunnel_concrete_wet_n.png", "normal_strength": 1.5, "roughness": 0.4, "specular": 0.5, "sheen": 0.18, "texture_gain": 1.25, "alt_texture": wallpaper, "alt_uv_scale": 1.5},
		&"floor": {"texture": "res://assets/textures/tunnel_concrete_wet.png", "uv_scale": 3.4, "normal_texture": "res://assets/textures/tunnel_concrete_wet_n.png", "normal_strength": 1.2, "roughness": 0.3, "specular": 0.5, "sheen": 0.3, "alt_texture": "res://assets/textures/backrooms_carpet.png", "alt_uv_scale": 2.0},
		&"ceiling": {"texture": "res://assets/textures/tunnel_concrete_wet.png", "uv_scale": 3.4, "normal_texture": "res://assets/textures/tunnel_concrete_wet_n.png", "normal_strength": 1.5, "roughness": 0.5, "specular": 0.4, "texture_gain": 0.9, "alt_texture": "res://assets/textures/backrooms_ceiling.png", "alt_uv_scale": 1.2},
		&"clay": {"texture": "res://assets/textures/clay_black.png", "uv_scale": 2.6, "texture_gain": 0.75, "alt_texture": wallpaper, "alt_uv_scale": 1.5},
		&"glow": {"tint": CYAN, "emissive": true, "energy": 2.2, "reality_side": 1.0},
		&"flame": {"tint": Color(1.0, 0.72, 0.3), "emissive": true, "energy": 2.4},
	}
	var tube: Dictionary = {"color": Color(1.0, 0.95, 0.74), "energy": 1.15, "radius": 9.5, "flicker": true}
	tiles = {
		"#": {"solid": true, "wall": &"wall"},
		".": {"floor": &"floor", "ceiling": &"ceiling", "zone": "water", "floor_y": BED},
		",": {"floor": &"floor", "ceiling": &"ceiling", "zone": "water", "floor_y": BED, "light": tube},
		"s": {"floor": &"floor", "ceiling": &"ceiling"},
		"S": {"floor": &"floor", "ceiling": &"ceiling", "light": tube},
		# Hueco a oscuras: misma obra que el túnel, sin luz propia. Refugio (zona `duct` por compatibilidad).
		"d": {"floor": &"floor", "ceiling": &"ceiling", "nav": false, "zone": "duct"},
		"r": {"floor": &"floor", "ceiling": &"ceiling", "zone": "remanso"},
		"w": {"floor": &"floor", "ceiling": &"ceiling", "zones": ["water", "remanso"], "floor_y": BED},
		"c": {"floor": &"clay", "ceiling": &"clay", "wall": &"clay", "height": 4.4, "zone": "remanso"},
		"b": {"solid": true, "wall": &"clay"},
	}
	# Recorrido corto (≈ 190 m) en tres tramos con dos estancias que lo rompen: la sala de
	# válvulas y el ensanche de los archiveros. Columna = celda izquierda de un túnel de 2 celdas.
	var grid: Array[String] = []
	for y: int in 84:
		grid.append("#".repeat(27))
	_carve(grid, 3, 1, 4, 20, "s")
	_carve(grid, 3, 19, 11, 20, "s")
	_carve(grid, 10, 21, 11, 45)
	_carve(grid, 10, 44, 19, 45)
	_carve(grid, 18, 44, 19, 71)
	# Sala de válvulas: el túnel se abre y deja una repisa seca (respiro de D10).
	_carve(grid, 8, 30, 13, 34)
	_carve(grid, 12, 31, 13, 33, "r")
	# Ensanche a mitad del último tramo, con su repisa (respiro de D11).
	_carve(grid, 17, 58, 21, 62)
	_carve(grid, 21, 59, 21, 61, "w")
	# Huecos a oscuras, de la misma obra que el túnel: dentro, la entidad no te ve.
	for hollow: Vector2i in [Vector2i(5, 12), Vector2i(8, 24), Vector2i(12, 39), Vector2i(16, 50), Vector2i(20, 54), Vector2i(16, 66)]:
		_carve(grid, hollow.x, hollow.y, hollow.x + 1, hollow.y + 1, "d")
	# Cámara de barro, sellada al frente; se entra por un pasadizo lateral a oscuras.
	_carve(grid, 16, 72, 21, 80, "b")
	_carve(grid, 17, 73, 20, 79, "c")
	_carve(grid, 18, 72, 18, 72, "s")
	_carve(grid, 20, 70, 21, 71, "d")
	_carve(grid, 21, 72, 21, 74, "d")
	_backrooms_remnants(grid)
	rows = PackedStringArray(grid)
	_wet = grid
	markers = {
		"start": Vector3(8, 0, 4), "cp_start": Vector3(8, 0, 4),
		"cp_r1": Vector3(23, 0, 73), "cp_r1_look": Vector3(23, 0, 79),
		"cp_r2": Vector3(41, 0, 121), "cp_r2_look": Vector3(37, 0, 129),
		"d10": Vector3(26.6, 0.8, 65), "d11": Vector3(41.6, 0.2, 119.4),
		"d12": Vector3(36.04, 1.05, 141.4), "letter": Vector3(37, 1.2, 155),
		"wall": Vector3(37, 0, 145), "exit": Vector3(37, 0, 140),
		"hunter_gate": Vector3(37, 0, 95),
		"hollow": Vector3(18, 0, 50),
		"ambush_0": Vector3(23, 0, 55), "ambush_1": Vector3(39, 0, 111),
		"ambush_2": Vector3(39, 0, 135),
	}
	_dress()


## Estaciones de calavera a lo largo de cada tramo recto: (columna izquierda, fila inicial, fila
## final, eje). La columna es la celda izquierda de un túnel de dos celdas de ancho.
## Fluorescentes de backrooms a media distancia entre calavera y calavera: cuando la mente
## vuelve a poner la oficina, alumbran ellos; en lo real están muertos.
func _backrooms_remnants(grid: Array[String]) -> void:
	for section: Vector3i in SECTIONS:
		for y: int in range(section.y + 4, section.z + 1, SKULL_STEP):
			var symbol: String = grid[y][section.x]
			if symbol in [".", "s"]:
				grid[y] = grid[y].substr(0, section.x) + ("," if symbol == "." else "S") + grid[y].substr(section.x + 1)


var _wet: Array[String] = []


func _dress() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1142
	var station: int = 0
	for section: Vector3i in SECTIONS:
		var centre_x: float = section.x * 2.0 + 2.0
		for y: int in range(section.y, section.z + 1, SKULL_STEP):
			var at: Vector3 = Vector3(centre_x, TUNNEL_HEIGHT, y * 2.0 + 1.0)
			station += 1
			# Una de cada seis está muerta: el tramo negro donde la linterna es todo lo que hay.
			var dead: bool = station % 6 == 4
			# Incrustada en el techo y volcada hacia quien llega: se le ve la cara desde el pasillo.
			props.append({"model": "sugar_skull_giant", "pos": at + Vector3(0, 0.25, 0), "rot_y": 180.0, "tilt": Vector3(-52, 0, 0), "scale": 1.35, "collide": false,
				"tints": {} if not dead else {"Glow": Color(0.05, 0.08, 0.09)}})
			if not dead:
				lights.append({"pos": at - Vector3(0, 1.25, 0), "color": CYAN, "energy": 1.5, "radius": 7.5})
			if section.x == 3:
				continue
			for i: int in 3:
				props.append({"model": "marigold_raft", "pos": Vector3(at.x + rng.randf_range(-1.5, 1.5), 0.13, at.z + rng.randf_range(-3.0, 3.0)),
					"rot_y": rng.randf_range(0.0, 360.0), "scale": rng.randf_range(0.8, 1.5), "collide": false})
		# Tubería corrida por el muro izquierdo: línea de fuga hacia la siguiente calavera.
		for y: int in range(section.y, section.z + 1):
			props.append({"model": "pipe_run", "pos": Vector3(section.x * 2.0 + 0.12, 2.75, y * 2.0 + 1.0), "rot_y": 90.0, "collide": false})
			if y % SKULL_STEP == (section.y + 4) % SKULL_STEP:
				props.append({"model": "pipe_elbow_valve", "pos": Vector3(section.x * 2.0 + 0.16, 2.3, y * 2.0 + 1.0), "rot_y": 90.0, "collide": false})

	# Primer tramo, seco: pasarela de rejilla y un par de manchas de flores que anuncian el agua.
	for y: int in range(14, 20, 3):
		props.append({"model": "ledge_walkway", "pos": Vector3(7.0, 0.0, y * 2.0 + 1.0), "rot_y": 90.0, "collide": false})
	for y: int in [15, 17, 19]:
		props.append({"model": "marigold_pile", "pos": Vector3(8.6, 0.0, y * 2.0), "rot_y": y * 37.0, "collide": false})

	# Restos de oficina: solos, torcidos, medio hundidos (liminalidad, docs/01).
	props.append({"model": "filing_cabinet", "pos": Vector3(7.0, 0.0, 9.0), "rot_y": 90.0})
	props.append({"model": "chair_tipped", "pos": Vector3(9.2, 0.0, 30.0), "rot_y": 40.0, "collide": false})
	props.append({"model": "water_cooler", "pos": Vector3(20.7, 0.0, 52.0), "rot_y": 90.0})
	props.append({"model": "chair_office", "pos": Vector3(22.8, -0.25, 80.0), "rot_y": 200.0, "tilt": Vector3(14, 0, 8), "collide": false})
	for at: Vector3 in [Vector3(6.06, 1.5, 24.0), Vector3(20.06, 1.6, 56.0), Vector3(36.06, 1.6, 104.0)]:
		props.append({"model": "wallpaper_peel", "pos": at, "rot_y": 90.0, "collide": false})

	# Sala de válvulas (respiro de D10): tuberías, volantes, y la repisa seca con el escritorio.
	for z: float in [61.0, 63.0, 65.0, 67.0, 69.0]:
		props.append({"model": "pipe_run", "pos": Vector3(16.12, 2.4, z), "rot_y": 90.0, "collide": false})
		props.append({"model": "pipe_run", "pos": Vector3(16.12, 1.5, z), "rot_y": 90.0, "collide": false})
	for z: float in [62.0, 66.0]:
		props.append({"model": "pipe_elbow_valve", "pos": Vector3(16.2, 1.0, z), "rot_y": 90.0, "collide": false})
	props.append({"model": "desk_office", "pos": Vector3(26.6, 0.0, 65.0), "rot_y": 90.0, "tilt": Vector3(0, 0, 3)})
	props.append({"model": "chair_tipped", "pos": Vector3(25.2, 0.0, 66.6), "rot_y": 200.0, "collide": false})
	_candles(rng, Vector3(26.4, 0.0, 63.2), 9)
	_candles(rng, Vector3(26.6, 0.74, 65.0), 3, 0.3)
	props.append({"model": "copal_censer", "pos": Vector3(27.2, 0, 67.0), "collide": false})
	lights.append({"pos": Vector3(26.0, 1.2, 64.6), "color": WARM, "energy": 1.4, "radius": 7.5})
	# Ensanche de los archiveros (respiro de D11): un fichero volcado y la cartera flotando.
	props.append({"model": "filing_cabinet", "pos": Vector3(35.4, -0.2, 119.0), "rot_y": 20.0, "tilt": Vector3(0, 0, 70), "collide": false})
	props.append({"model": "filing_cabinet", "pos": Vector3(35.2, 0.0, 122.6), "rot_y": -10.0})
	props.append({"model": "desk_office", "pos": Vector3(36.4, -0.3, 124.0), "rot_y": 80.0, "tilt": Vector3(6, 0, -10), "collide": false})
	props.append({"model": "wallet_open", "pos": Vector3(41.6, 0.15, 119.4), "rot_y": 25.0, "collide": false})
	_candles(rng, Vector3(43.0, 0, 121.0), 9, 0.5)
	props.append({"model": "copal_censer", "pos": Vector3(43.2, 0, 122.4), "collide": false})
	lights.append({"pos": Vector3(42.6, 0.9, 121.0), "color": WARM, "energy": 1.35, "radius": 6.5})

	# Cámara de barro negro: altar de la H. Su luz se derrama por el vano y es el punto de fuga.
	var altar: Vector3 = Vector3(37, 0, 155)
	for i: int in 5:
		var x: float = 33.6 + i * 1.7
		props.append({"model": "clay_pot_black", "pos": Vector3(x, 0, 157.6), "rot_y": i * 71.0, "scale": 1.0 + 0.25 * (i % 2), "collide": false})
		if i != 2:
			props.append({"model": "sugar_skull", "pos": Vector3(x, 0.45 + 0.11 * (i % 2), 157.6), "rot_y": 180.0, "collide": false})
	props.append({"model": "ofrenda_tier", "pos": altar + Vector3(0, 0, 0.9), "collide": false})
	props.append({"model": "marigold_vase", "pos": altar + Vector3(-0.7, 0.45, 0.9), "collide": false})
	props.append({"model": "marigold_vase", "pos": altar + Vector3(0.7, 0.45, 0.9), "collide": false})
	props.append({"model": "copal_censer", "pos": altar + Vector3(0, 0.45, 1.0), "collide": false})
	_candles(rng, altar + Vector3(0, 0, -0.5), 14, 1.5)
	_candles(rng, altar + Vector3(-2.2, 0, 0.3), 8, 0.7)
	_candles(rng, altar + Vector3(2.2, 0, 0.3), 8, 0.7)
	for x: float in [34.5, 39.5]:
		props.append({"model": "marigold_pile", "pos": Vector3(x, 0, 152.6), "rot_y": x * 20.0, "collide": false})
	lights.append({"pos": altar + Vector3(0, 1.1, -0.4), "color": WARM, "energy": 1.5, "radius": 8.0})
	lights.append({"pos": altar + Vector3(0, 2.0, 0.3), "color": MAGENTA, "energy": 0.45, "radius": 9.0})
	# Etiqueta de calaverita junto al muro (D12): una veladora la señala.
	props.append({"model": "sugar_skull", "pos": Vector3(36.1, 0.0, 141.0), "rot_y": 90.0, "collide": false})
	props.append({"model": "candle_mid", "pos": Vector3(36.15, 0.0, 141.6), "collide": false})
	lights.append({"pos": Vector3(36.5, 0.5, 141.4), "color": WARM, "energy": 0.6, "radius": 3.0})
	_settle()


## Lo que cae en celda inundada baja al fondo del cauce; lo que flota se queda en la lámina.
func _settle() -> void:
	for prop: Dictionary in props:
		var at: Vector3 = prop["pos"]
		var row: int = floori(at.z / 2.0)
		var column: int = floori(at.x / 2.0)
		if at.y > 0.3 or row < 0 or row >= _wet.size() or not _wet[row][column] in [".", ",", "w"]:
			continue
		var floats: bool = false
		for word: String in FLOATING:
			floats = floats or String(prop["model"]).begins_with(word)
		prop["pos"] = Vector3(at.x, SURFACE - 0.01 if floats else at.y + BED, at.z)


func _candles(rng: RandomNumberGenerator, centre: Vector3, count: int, spread: float = 0.9) -> void:
	for i: int in count:
		var model: String = ["candle_short", "candle_mid", "candle_tall"][rng.randi() % 3]
		props.append({"model": model, "pos": centre + Vector3(rng.randf_range(-spread, spread), 0.0, rng.randf_range(-0.35, 0.35)),
			"rot_y": rng.randf_range(0.0, 360.0), "scale": rng.randf_range(0.9, 1.3), "collide": false})


func _carve(grid: Array[String], x0: int, y0: int, x1: int, y1: int, tile: String = ".") -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			grid[y] = grid[y].substr(0, x) + tile + grid[y].substr(x + 1)
