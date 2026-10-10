extends LevelDef
## Nivel 3 — "El Pasaje de las Calaveras" (docs/04, docs/12 §8.3).
## Contaminación 50 %: el nivel EMPIEZA siendo backrooms (papel tapiz, alfombra, fluorescentes) y
## se va volviendo túnel; los restos de oficina siguen apareciendo hasta el final.
## Túnel de mantenimiento inundado. Fotografía: negro húmedo, fosforescencia cian de las
## calaveras como única luz clave (charcos cada 16 m con tramos negros entre ellos), cempasúchil
## naranja flotando como acento, y lo cálido reservado a refugios (veladora en cada boca de
## conducto) y a la cámara de barro, cuyo resplandor es el punto de fuga del último tramo.

const CYAN: Color = Color(0.28, 0.82, 0.9)
const WARM: Color = Color(1.0, 0.5, 0.18)
const MAGENTA: Color = Color(1.0, 0.25, 0.7)
const TUNNEL_HEIGHT: float = 3.4
const SKULL_STEP: int = 8


func _init() -> void:
	name = "level3"
	wall_height = TUNNEL_HEIGHT
	baseboard_height = 0.0
	chunk_cells = 8
	visibility_range = 46.0
	ambient = Color(0.006, 0.010, 0.012)
	bounce = 0.28
	materials = {
		&"concrete": {"texture": "res://assets/textures/tunnel_concrete_wet.png", "uv_scale": 3.4, "texture_gain": 1.25},
		&"wallpaper": {"texture": "res://assets/textures/backrooms_wallpaper.png", "uv_scale": 1.5},
		&"peeling": {"texture": "res://assets/textures/wallpaper_peeling.png", "uv_scale": 2.6},
		&"carpet": {"texture": "res://assets/textures/backrooms_carpet.png", "uv_scale": 2.0},
		&"tiles": {"texture": "res://assets/textures/backrooms_ceiling.png", "uv_scale": 1.2},
		&"metal": {"texture": "res://assets/textures/duct_metal.png", "uv_scale": 1.2},
		&"clay": {"texture": "res://assets/textures/clay_black.png", "uv_scale": 4.0, "texture_gain": 1.0},
		&"glow": {"tint": CYAN, "emissive": true, "energy": 2.2},
		&"flame": {"tint": Color(1.0, 0.72, 0.3), "emissive": true, "energy": 2.4},
	}
	tiles = {
		"#": {"solid": true, "wall": &"concrete"},
		".": {"floor": &"concrete", "ceiling": &"concrete", "wall": &"concrete", "zone": "water"},
		"s": {"floor": &"concrete", "ceiling": &"concrete", "wall": &"concrete"},
		"d": {"floor": &"metal", "ceiling": &"metal", "wall": &"metal", "height": 1.2, "nav": false, "zone": "duct"},
		"r": {"floor": &"concrete", "ceiling": &"concrete", "wall": &"concrete", "zone": "remanso"},
		"w": {"floor": &"concrete", "ceiling": &"concrete", "wall": &"concrete", "zones": ["water", "remanso"]},
		"c": {"floor": &"clay", "ceiling": &"clay", "wall": &"clay", "height": 4.4, "zone": "remanso"},
		"b": {"solid": true, "wall": &"clay"},
		# Backrooms que se deshacen: llegada (A), papel desprendido (B) y alfombra ya bajo el agua (k).
		"W": {"solid": true, "wall": &"wallpaper"},
		"P": {"solid": true, "wall": &"peeling"},
		"A": {"floor": &"carpet", "ceiling": &"tiles", "height": 2.8},
		"L": {"floor": &"carpet", "ceiling": &"tiles", "height": 2.8, "light": {"color": Color(1.0, 0.95, 0.74), "energy": 1.0, "radius": 8.0, "flicker": false}},
		"F": {"floor": &"carpet", "ceiling": &"tiles", "height": 2.8, "light": {"color": Color(1.0, 0.95, 0.74), "energy": 0.9, "radius": 7.0, "flicker": true}},
		"B": {"floor": &"carpet", "ceiling": &"concrete", "height": 3.1},
		"k": {"floor": &"carpet", "ceiling": &"concrete", "zone": "water"},
		"f": {"floor": &"carpet", "ceiling": &"concrete", "zone": "water", "light": {"color": Color(1.0, 0.9, 0.62), "energy": 0.9, "radius": 7.0, "flicker": true}},
	}
	var grid: Array[String] = []
	for y: int in 190:
		grid.append("#".repeat(27))
	_carve(grid, 3, 1, 4, 35, "s")
	_carve(grid, 3, 34, 11, 35, "s")
	_carve(grid, 10, 34, 11, 70)
	_carve(grid, 10, 69, 19, 70)
	_carve(grid, 18, 69, 19, 106)
	_carve(grid, 8, 105, 19, 106)
	_carve(grid, 8, 105, 9, 145)
	_carve(grid, 8, 144, 19, 145)
	_carve(grid, 18, 144, 19, 180)
	# Dos cruces iguales: el segundo paso devuelve al primero sin girar la cámara.
	_carve(grid, 7, 119, 10, 120)
	_carve(grid, 7, 127, 10, 128)
	for section: Vector3i in [Vector3i(3, 8, 32), Vector3i(10, 42, 66), Vector3i(18, 78, 102), Vector3i(8, 112, 136), Vector3i(18, 152, 176)]:
		for y: int in range(section.y, section.z + 1, 8):
			_carve(grid, section.x + 2, y, section.x + 4, y, "d")
	_carve(grid, 12, 41, 15, 43, "r")
	_carve(grid, 12, 42, 13, 42, "d")
	_carve(grid, 14, 42, 15, 42, "d")
	_carve(grid, 14, 160, 17, 162, "r")
	_carve(grid, 17, 161, 17, 161, "w")
	# Cámara sellada al frente; abertura lateral baja accesible desde el túnel.
	_carve(grid, 16, 178, 21, 186, "b")
	_carve(grid, 17, 179, 20, 185, "c")
	_carve(grid, 18, 177, 18, 179, "s")
	_carve(grid, 20, 176, 21, 177, "d")
	_carve(grid, 21, 178, 21, 180, "d")
	_carve(grid, 18, 186, 18, 188, "s")
	_backrooms_remnants(grid)
	rows = PackedStringArray(grid)
	markers = {
		"start": Vector3(8, 0, 4), "cp_start": Vector3(8, 0, 4),
		"cp_r1": Vector3(23, 0, 89), "cp_r1_look": Vector3(23, 0, 93),
		"cp_r2": Vector3(31, 0, 323), "cp_r2_look": Vector3(37, 0, 323),
		"d10": Vector3(30, 0.55, 85), "d11": Vector3(35, 0.2, 323),
		"d12": Vector3(36.04, 1.05, 357), "letter": Vector3(37, 1.2, 367),
		"wall": Vector3(37, 0, 358), "exit": Vector3(37, 0, 354),
		"hunter_gate": Vector3(23, 0, 103),
		"loop_a": Vector3(18, 0, 241), "loop_b": Vector3(18, 0, 257),
		"ambush_0": Vector3(39, 0, 165), "ambush_1": Vector3(19, 0, 281),
		"ambush_2": Vector3(39, 0, 343),
	}
	_dress()


## Estaciones de calavera a lo largo de cada tramo recto: (columna izquierda, fila inicial, fila
## final, eje). La columna es la celda izquierda de un túnel de dos celdas de ancho.
func _backrooms_remnants(grid: Array[String]) -> void:
	# Llegada: 24 m de backrooms intactos, 24 m de papel desprendido, y el concreto toma el relevo.
	for y: int in range(0, 14):
		grid[y] = grid[y].replace("#", "W").replace("s", "A")
	for y: int in range(14, 26):
		grid[y] = grid[y].replace("#", "P").replace("s", "B")
	for cell: Vector2i in [Vector2i(3, 3), Vector2i(4, 8)]:
		grid[cell.y] = grid[cell.y].substr(0, cell.x) + "L" + grid[cell.y].substr(cell.x + 1)
	for cell: Vector2i in [Vector2i(3, 12), Vector2i(4, 17), Vector2i(3, 22)]:
		grid[cell.y] = grid[cell.y].substr(0, cell.x) + "F" + grid[cell.y].substr(cell.x + 1)
	# La alfombra sigue bajo la primera agua.
	for y: int in range(36, 46):
		grid[y] = grid[y].replace(".", "k")
	grid[40] = grid[40].substr(0, 10) + "f" + grid[40].substr(11)
	# Más adentro quedan paños de papel tapiz, cada vez más escasos.
	for span: Vector2i in [Vector2i(36, 45)]:
		for y: int in range(span.x, span.y + 1):
			grid[y] = grid[y].replace("#", "P")


func _dress() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1142
	var station: int = 0
	for section: Vector3i in [Vector3i(3, 4, 32), Vector3i(10, 38, 68), Vector3i(18, 74, 104), Vector3i(8, 110, 142), Vector3i(18, 150, 174)]:
		var centre_x: float = section.x * 2.0 + 2.0
		for y: int in range(section.y, section.z + 1, SKULL_STEP):
			if y < 26 or (y >= 36 and y < 46):
				continue
			var at: Vector3 = Vector3(centre_x, TUNNEL_HEIGHT, y * 2.0 + 1.0)
			# Entre calavera y calavera, una luminaria muerta de la oficina que esto fue.
			props.append({"model": "ceiling_fixture", "pos": at + Vector3(0.0, 0.0, 8.0), "collide": false})
			station += 1
			# Una de cada seis está muerta: el tramo negro donde la linterna es todo lo que hay.
			var dead: bool = station % 6 == 4
			props.append({"model": "sugar_skull_giant", "pos": at, "rot_y": 180.0, "collide": false,
				"tints": {} if not dead else {"Glow": Color(0.05, 0.08, 0.09)}})
			if not dead:
				lights.append({"pos": at - Vector3(0, 1.25, 0), "color": CYAN, "energy": 1.5, "radius": 7.5})
			if section.x == 3:
				continue
			for i: int in 3:
				props.append({"model": "marigold_raft", "pos": Vector3(at.x + rng.randf_range(-1.5, 1.5), 0.13, at.z + rng.randf_range(-3.0, 3.0)),
					"rot_y": rng.randf_range(0.0, 360.0), "scale": rng.randf_range(0.8, 1.5), "collide": false})
		# Tubería corrida por el muro izquierdo: línea de fuga hacia la siguiente calavera.
		for y: int in range(maxi(section.y, 26), section.z + 1):
			props.append({"model": "pipe_run", "pos": Vector3(section.x * 2.0 + 0.12, 2.75, y * 2.0 + 1.0), "rot_y": 90.0, "collide": false})
			if y % SKULL_STEP == (section.y + 4) % SKULL_STEP:
				props.append({"model": "pipe_elbow_valve", "pos": Vector3(section.x * 2.0 + 0.16, 2.3, y * 2.0 + 1.0), "rot_y": 90.0, "collide": false})

	# Bocas de conducto: rejilla en el muro derecho y una veladora en el umbral (lo cálido = refugio).
	for section: Vector3i in [Vector3i(3, 8, 32), Vector3i(10, 42, 66), Vector3i(18, 78, 102), Vector3i(8, 112, 136), Vector3i(18, 152, 176)]:
		for y: int in range(section.y, section.z + 1, 8):
			var mouth: Vector3 = Vector3((section.x + 2) * 2.0, 0.0, y * 2.0 + 1.0)
			props.append({"model": "duct_grille", "pos": mouth + Vector3(-0.03, 0.62, 0.0), "rot_y": 90.0, "collide": false})
			props.append({"model": "candle_short", "pos": mouth + Vector3(0.45, 0.0, 0.55), "collide": false})
			lights.append({"pos": mouth + Vector3(0.5, 0.35, 0.3), "color": WARM, "energy": 0.55, "radius": 3.2})

	# Primer tramo, seco: pasarela de rejilla y un par de manchas de flores que anuncian el agua.
	for y: int in range(26, 35, 3):
		props.append({"model": "ledge_walkway", "pos": Vector3(7.0, 0.0, y * 2.0 + 1.0), "rot_y": 90.0, "collide": false})
	for y: int in [26, 30, 33]:
		props.append({"model": "marigold_pile", "pos": Vector3(8.6, 0.0, y * 2.0), "rot_y": y * 37.0, "collide": false})

	# Restos de oficina: solos, torcidos, medio hundidos (liminalidad, docs/01).
	props.append({"model": "filing_cabinet", "pos": Vector3(7.0, 0.0, 9.0), "rot_y": 90.0})
	props.append({"model": "chair_tipped", "pos": Vector3(9.2, 0.0, 30.0), "rot_y": 40.0, "collide": false})
	props.append({"model": "water_cooler", "pos": Vector3(6.9, 0.0, 44.0), "rot_y": 90.0})
	props.append({"model": "chair_office", "pos": Vector3(22.8, -0.25, 96.0), "rot_y": 200.0, "tilt": Vector3(14, 0, 8), "collide": false})
	props.append({"model": "filing_cabinet", "pos": Vector3(39.0, -0.35, 190.0), "rot_y": -90.0, "tilt": Vector3(0, 0, 18), "collide": false})
	props.append({"model": "desk_office", "pos": Vector3(18.6, -0.3, 262.0), "rot_y": 80.0, "tilt": Vector3(6, 0, -10), "collide": false})
	props.append({"model": "chair_tipped", "pos": Vector3(38.4, -0.1, 318.0), "rot_y": 130.0, "collide": false})
	for at: Vector3 in [Vector3(6.06, 1.5, 34.0), Vector3(20.06, 1.6, 120.0), Vector3(36.06, 1.6, 172.0), Vector3(16.06, 1.6, 236.0)]:
		props.append({"model": "wallpaper_peel", "pos": at, "rot_y": 90.0, "collide": false})

	# Respiro de D10: escritorio hundido al fondo del conducto, entre veladoras.
	props.append({"model": "desk_office", "pos": Vector3(30, -0.18, 85), "tilt": Vector3(9, 0, -8), "collide": false})
	_candles(rng, Vector3(30, 0, 84.0), 7)
	lights.append({"pos": Vector3(30, 0.9, 84.4), "color": WARM, "energy": 1.25, "radius": 5.5})
	# Respiro de D11: la cartera flota junto a la repisa seca.
	props.append({"model": "wallet_open", "pos": Vector3(35, 0.15, 323), "rot_y": 25.0, "collide": false})
	_candles(rng, Vector3(31, 0, 322.0), 9)
	props.append({"model": "copal_censer", "pos": Vector3(30.2, 0, 323.4), "collide": false})
	lights.append({"pos": Vector3(31, 0.9, 322.4), "color": WARM, "energy": 1.35, "radius": 6.0})

	# Cámara de barro negro: altar de la H. Su luz se derrama por el vano y es el punto de fuga.
	var altar: Vector3 = Vector3(37, 0, 367)
	for i: int in 5:
		var x: float = 33.6 + i * 1.7
		props.append({"model": "clay_pot_black", "pos": Vector3(x, 0, 369.0), "rot_y": i * 71.0, "scale": 1.0 + 0.25 * (i % 2), "collide": false})
		if i != 2:
			props.append({"model": "sugar_skull", "pos": Vector3(x, 0.45 + 0.11 * (i % 2), 369.0), "rot_y": 180.0, "collide": false})
	props.append({"model": "ofrenda_tier", "pos": altar + Vector3(0, 0, 0.9), "collide": false})
	props.append({"model": "marigold_vase", "pos": altar + Vector3(-0.7, 0.45, 0.9), "collide": false})
	props.append({"model": "marigold_vase", "pos": altar + Vector3(0.7, 0.45, 0.9), "collide": false})
	props.append({"model": "copal_censer", "pos": altar + Vector3(0, 0.45, 1.0), "collide": false})
	_candles(rng, altar + Vector3(0, 0, -0.5), 14, 1.5)
	_candles(rng, altar + Vector3(-2.2, 0, 0.3), 8, 0.7)
	_candles(rng, altar + Vector3(2.2, 0, 0.3), 8, 0.7)
	for x: float in [34.5, 39.5]:
		props.append({"model": "marigold_pile", "pos": Vector3(x, 0, 365.5), "rot_y": x * 20.0, "collide": false})
	lights.append({"pos": altar + Vector3(0, 1.1, -0.4), "color": WARM, "energy": 1.5, "radius": 8.0})
	lights.append({"pos": altar + Vector3(0, 2.0, 0.3), "color": MAGENTA, "energy": 0.45, "radius": 9.0})
	# Etiqueta de calaverita junto al muro (D12): una veladora la señala.
	props.append({"model": "sugar_skull", "pos": Vector3(36.1, 0.0, 356.4), "rot_y": 90.0, "collide": false})
	props.append({"model": "candle_mid", "pos": Vector3(36.15, 0.0, 356.9), "collide": false})
	lights.append({"pos": Vector3(36.5, 0.5, 356.8), "color": WARM, "energy": 0.6, "radius": 3.0})


func _candles(rng: RandomNumberGenerator, centre: Vector3, count: int, spread: float = 0.9) -> void:
	for i: int in count:
		var model: String = ["candle_short", "candle_mid", "candle_tall"][rng.randi() % 3]
		props.append({"model": model, "pos": centre + Vector3(rng.randf_range(-spread, spread), 0.0, rng.randf_range(-0.35, 0.35)),
			"rot_y": rng.randf_range(0.0, 360.0), "scale": rng.randf_range(0.9, 1.3), "collide": false})


func _carve(grid: Array[String], x0: int, y0: int, x1: int, y1: int, tile: String = ".") -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			grid[y] = grid[y].substr(0, x) + tile + grid[y].substr(x + 1)
