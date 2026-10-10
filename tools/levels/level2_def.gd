extends LevelDef
## Nivel 2 — "Las Ofrendas Infinitas" (docs/04, docs/12 §8.2). Contaminación 35 %, DOBLE REALIDAD.
## Una sola nave de 70 × 50 m y 6,5 m de alto con dos pieles: la de backrooms (sala inmensa de
## papel tapiz y alfombra bajo una retícula de fluorescentes: lo que la mente pone) y la real
## (concreto brutalista a oscuras, humo de copal, y charcos cálidos en las ofrendas).
## Misión, legible sin HUD: en el centro hay una pirámide de archiveros apagada; a lo lejos arden
## tres ofrendas. Encender la veladora mayor de cada una despierta la pirámide y la letra O.

const WARM: Color = Color(1.0, 0.52, 0.18)
const HALL_HEIGHT: float = 6.5
const WIDTH: int = 37
const DEPTH: int = 27
## Celdas de las tres ofrendas y hacia dónde miran (grados; 0 = hacia +Z).
const OFFERINGS: Array[Vector3i] = [Vector3i(9, 4, 0), Vector3i(31, 7, 90), Vector3i(27, 22, 180)]
const PYRAMID: Vector2i = Vector2i(18, 13)


func _init() -> void:
	name = "level2"
	wall_height = HALL_HEIGHT
	baseboard_height = 0.0
	chunk_cells = 6
	visibility_range = 70.0
	ambient = Color(0.026, 0.022, 0.02)
	bounce = 0.3
	ao_strength = 2.4
	contact_strength = 0.6
	dual_reality = true
	flicker_color = Color(1.0, 0.93, 0.7)
	var wallpaper: String = "res://assets/textures/backrooms_wallpaper.png"
	materials = {
		&"wall": {"texture": "res://assets/textures/concrete_brutalist.png", "uv_scale": 4.0, "alt_texture": wallpaper, "alt_uv_scale": 1.5},
		&"floor": {"texture": "res://assets/textures/concrete_floor.png", "uv_scale": 4.0, "alt_texture": "res://assets/textures/backrooms_carpet.png", "alt_uv_scale": 2.0},
		&"ceiling": {"texture": "res://assets/textures/concrete_ceiling_dark.png", "uv_scale": 4.0, "texture_gain": 1.4, "alt_texture": "res://assets/textures/backrooms_ceiling.png", "alt_uv_scale": 1.2},
		&"adobe": {"texture": "res://assets/textures/adobe_dark.png", "uv_scale": 2.5, "texture_gain": 1.3, "alt_texture": wallpaper, "alt_uv_scale": 1.5, "alt_tint": Color(0.82, 0.8, 0.74)},
		&"stone": {"texture": "res://assets/textures/volcanic_stone.png", "uv_scale": 2.5, "texture_gain": 1.3, "alt_texture": "res://assets/textures/backrooms_carpet.png", "alt_uv_scale": 2.0},
		&"flame": {"tint": Color(1.0, 0.72, 0.3), "emissive": true, "energy": 2.4},
	}
	var tube: Dictionary = {"color": Color(1.0, 0.95, 0.74), "energy": 1.25, "radius": 13.0, "flicker": true}
	tiles = {
		"#": {"solid": true, "wall": &"wall"},
		"P": {"solid": true, "wall": &"wall"},
		"A": {"solid": true, "wall": &"adobe"},
		".": {"floor": &"floor", "ceiling": &"ceiling"},
		"L": {"floor": &"floor", "ceiling": &"ceiling", "light": tube},
		"t": {"floor": &"stone", "ceiling": &"ceiling"},
		"r": {"floor": &"stone", "ceiling": &"ceiling", "zone": "remanso"},
		"e": {"floor": &"floor", "ceiling": &"ceiling", "height": 2.8},
		"E": {"floor": &"floor", "ceiling": &"ceiling", "height": 2.8, "light": {"color": Color(1.0, 0.95, 0.74), "energy": 1.0, "radius": 7.0, "flicker": true}},
	}
	var grid: Array[String] = []
	for y: int in DEPTH:
		grid.append("#".repeat(WIDTH))
	_fill(grid, 5, 1, WIDTH - 2, DEPTH - 2, ".")
	# Llegada: un pasillo bajo y estrecho que desemboca en la nave (el techo "salta" a 6,5 m).
	_fill(grid, 1, 13, 4, 13, "e")
	_put(grid, 2, 13, "E")
	# Columnas brutalistas en retícula (se respeta el claro de la pirámide y de las ofrendas).
	for y: int in range(4, DEPTH - 2, 4):
		for x: int in range(8, WIDTH - 2, 4):
			if absi(x - PYRAMID.x) <= 3 and absi(y - PYRAMID.y) <= 3:
				continue
			_put(grid, x, y, "P")
			_column(x, y)
	# Tubos de backrooms entre columnas.
	for y: int in range(2, DEPTH - 1, 4):
		for x: int in range(6, WIDTH - 1, 4):
			if grid[y][x] == ".":
				_put(grid, x, y, "L")
	# Cimientos a la vista: muros de adobe que rompen la vista entre ofrendas y dan dónde apartar la luz.
	for wall: Array in [[Vector2i(13, 2), Vector2i(13, 7)], [Vector2i(22, 9), Vector2i(26, 9)], [Vector2i(21, 17), Vector2i(21, 21)],
			[Vector2i(7, 18), Vector2i(11, 18)], [Vector2i(30, 13), Vector2i(33, 13)], [Vector2i(14, 22), Vector2i(17, 22)]]:
		_fill(grid, wall[0].x, wall[0].y, wall[1].x, wall[1].y, "A")
	# Suelo de piedra volcánica bajo cada ofrenda (remanso: la entidad no entra) y bajo la pirámide.
	for offering: Vector3i in OFFERINGS:
		_fill(grid, offering.x - 1, offering.y - 1, offering.x + 1, offering.y + 1, "r")
	_fill(grid, PYRAMID.x - 2, PYRAMID.y - 2, PYRAMID.x + 2, PYRAMID.y + 2, "t")
	rows = PackedStringArray(grid)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2026
	markers["start"] = cell(1, 13)
	markers["cp_r1"] = cell(9, 7)
	markers["cp_r1_look"] = cell(18, 13)
	markers["cp_r2"] = cell(18, 17)
	markers["cp_r2_look"] = cell(18, 13)
	for i: int in OFFERINGS.size():
		_offering(rng, i, cell(OFFERINGS[i].x, OFFERINGS[i].y), float(OFFERINGS[i].z))
	_pyramid(rng)
	_office_remains(rng)
	# D08: hoja suelta en el suelo, entre pétalos, de camino a la tercera ofrenda.
	var sheet: Vector3 = cell(29, 16) + Vector3(0.3, 0.0, -0.4)
	boxes.append({"pos": sheet + Vector3(0, 0.008, 0), "size": Vector3(0.21, 0.012, 0.3), "material": &"flat", "tint": Color(0.86, 0.83, 0.72), "collide": false, "rot_y": 25.0})
	props.append({"model": "marigold_pile", "pos": sheet + Vector3(0.7, 0, 0.3), "collide": false})
	props.append({"model": "candle_short", "pos": sheet + Vector3(-0.35, 0, 0.2), "collide": false})
	lights.append({"pos": sheet + Vector3(0, 0.5, 0), "color": WARM, "energy": 0.7, "radius": 4.0})
	markers["d08"] = sheet + Vector3(0, 0.05, 0)
	# Luz real de la nave: casi nada. Un resplandor frío y alto cada tanto, lo justo para que las
	# columnas se recorten contra el humo y el suelo pulido devuelva una franja.
	for y: int in range(6, DEPTH - 2, 8):
		for x: int in range(10, WIDTH - 2, 8):
			lights.append({"pos": cell(x, y) + Vector3(1.0, 5.6, 1.0), "color": Color(0.42, 0.5, 0.66), "energy": 1.5, "radius": 17.0})
	# Rótulos pintados en las columnas que flanquean la ruta a la pirámide (los escribe el nivel).
	markers["paint_0"] = cell(12, 12) + Vector3(-1.008, 2.3, 0.0)
	markers["paint_0_n"] = markers["paint_0"] + Vector3(-1, 0, 0)
	markers["paint_1"] = cell(24, 16) + Vector3(0.0, 2.3, 1.008)
	markers["paint_1_n"] = markers["paint_1"] + Vector3(0, 0, 1)
	markers["paint_2"] = cell(24, 8) + Vector3(-1.008, 2.3, 0.0)
	markers["paint_2_n"] = markers["paint_2"] + Vector3(-1, 0, 0)
	markers["paint_3"] = cell(8, 20) + Vector3(1.008, 2.3, 0.0)
	markers["paint_3_n"] = markers["paint_3"] + Vector3(1, 0, 0)
	# Apariciones: lejos, entre columnas, siempre de perfil respecto a la ruta.
	var spots: Array[Vector2i] = [Vector2i(22, 3), Vector2i(34, 18), Vector2i(6, 23), Vector2i(15, 10), Vector2i(26, 14), Vector2i(34, 3), Vector2i(10, 14), Vector2i(23, 24)]
	for i: int in spots.size():
		markers["ambush_%d" % i] = cell(spots[i].x, spots[i].y)
	for i: int in 6:
		markers["manifest_%d" % i] = cell(spots[i].x, spots[i].y)


## Ofrenda monumental incrustada en lo que queda de un cubículo. `yaw`: hacia dónde mira.
func _offering(rng: RandomNumberGenerator, index: int, centre: Vector3, yaw: float) -> void:
	var basis: Basis = Basis(Vector3.UP, deg_to_rad(yaw))
	var place: Callable = func(model: String, offset: Vector3, extra: Dictionary = {}) -> void:
		var prop: Dictionary = {"model": model, "pos": centre + basis * offset, "rot_y": yaw + float(extra.get("turn", 0.0)), "collide": false}
		prop.merge(extra)
		prop.erase("turn")
		props.append(prop)
	place.call("ofrenda_arch", Vector3(0, 0, -1.9), {"scale": 1.25})
	place.call("ofrenda_tier", Vector3(0, 0, -2.0), {"scale": 1.3, "collide": true})
	place.call("ofrenda_tier", Vector3(0, 0.58, -2.25), {"scale": 0.95})
	place.call("papel_picado_string", Vector3(0, 3.4, -1.8), {"scale": 1.5})
	place.call("papel_picado_string", Vector3(0, 4.1, -2.1), {"scale": 1.9})
	place.call("copal_censer", Vector3(0.0, 0.58, -1.75))
	place.call("pan_de_muerto", Vector3(-0.45, 1.0, -2.25))
	place.call("photo_frame_empty", Vector3(0.0, 1.0, -2.3), {"turn": 180.0})
	place.call("sugar_skull", Vector3(0.5, 1.0, -2.2), {"turn": 0.0})
	place.call("sugar_skull", Vector3(-0.85, 0.58, -1.8), {"turn": 20.0})
	place.call("sugar_skull", Vector3(0.9, 0.58, -1.8), {"turn": -20.0})
	place.call("marigold_vase", Vector3(-1.75, 0, -1.6))
	place.call("marigold_vase", Vector3(1.75, 0, -1.6))
	place.call("marigold_pile", Vector3(-2.3, 0, -0.3), {"turn": 40.0})
	place.call("marigold_pile", Vector3(2.4, 0, -0.6), {"turn": 110.0})
	# El cubículo que la ofrenda reventó.
	place.call("partition_panel", Vector3(-2.7, 0, -1.9), {"turn": 90.0, "tilt": Vector3(0, 0, 6)})
	place.call("partition_panel", Vector3(2.9, 0, -1.4), {"turn": 75.0, "tilt": Vector3(8, 0, 0)})
	place.call("chair_tipped", Vector3(2.6, 0, 1.8), {"turn": 140.0})
	for i: int in 26:
		var model: String = ["candle_short", "candle_mid", "candle_tall"][rng.randi() % 3]
		var on_tier: bool = i < 8
		var offset: Vector3 = Vector3(rng.randf_range(-1.1, 1.1), 0.58, rng.randf_range(-2.3, -1.6)) if on_tier else Vector3(rng.randf_range(-2.2, 2.2), 0.0, rng.randf_range(-1.0, 0.6))
		if absf(offset.x) < 0.35 and not on_tier:
			continue
		place.call(model, offset, {"turn": rng.randf_range(0.0, 360.0), "scale": rng.randf_range(0.9, 1.4)})
	lights.append({"pos": centre + basis * Vector3(0, 1.3, -0.9), "color": WARM, "energy": 1.5, "radius": 9.0})
	lights.append({"pos": centre + basis * Vector3(0, 3.6, -1.2), "color": WARM, "energy": 0.9, "radius": 12.0})
	# La veladora mayor (dinámica: la enciende el jugador) va delante, a la altura de la mano.
	markers["offering_%d" % index] = centre + basis * Vector3(0, 0.0, -0.75)
	markers["offering_%d_front" % index] = centre + basis * Vector3(0, 0.0, 1.2)
	if index == 0:
		# D07 sobre el archivero que hace de costado a la primera ofrenda.
		place.call("filing_cabinet", Vector3(-1.9, 0, 0.9), {"turn": 90.0, "collide": true, "tints": {"Metal_Grey": Color(0.42, 0.24, 0.14)}})
		boxes.append({"pos": centre + basis * Vector3(-1.9, 1.326, 0.9), "size": Vector3(0.21, 0.012, 0.3), "material": &"flat", "tint": Color(0.86, 0.83, 0.72), "collide": false})
		markers["d07"] = centre + basis * Vector3(-1.9, 1.36, 0.9)


## Pirámide de tres niveles de archiveros oxidados. Apagada hasta que arden las tres ofrendas.
func _pyramid(rng: RandomNumberGenerator) -> void:
	var centre: Vector3 = cell(PYRAMID.x, PYRAMID.y)
	var rust: Dictionary = {"Metal_Grey": Color(0.2, 0.19, 0.2), "Metal_Dark": Color(0.08, 0.075, 0.08)}
	for level: int in 3:
		var half: float = 1.9 - level * 0.62
		var count: int = 7 - level * 2
		for side: int in 4:
			var basis: Basis = Basis(Vector3.UP, side * PI * 0.5)
			for i: int in count:
				var along: float = lerpf(-half + 0.3, half - 0.3, float(i) / maxf(count - 1, 1.0)) if count > 1 else 0.0
				props.append({"model": "filing_cabinet", "pos": centre + basis * Vector3(along, level * 1.32, half), "rot_y": side * 90.0 + rng.randf_range(-3.0, 3.0), "scale": 1.0,
					"collide": level == 0, "occlude": false, "tints": rust})
	# Cada repisa de la pirámide es altar: veladoras, calaveritas, flores, retratos sin foto y un
	# paño rojo colgando al frente de cada cara (superficie plana).
	for level: int in 3:
		var inner: float = 1.28 - level * 0.62
		var ledge: float = 1.62 - level * 0.62
		var top: float = (level + 1) * 1.32
		for side: int in 4:
			var basis: Basis = Basis(Vector3.UP, side * PI * 0.5)
			var yaw: float = side * 90.0
			boxes.append({"pos": centre + basis * Vector3(0, top - 0.55, ledge + 0.335), "size": Vector3(0.95, 1.1, 0.02) if side % 2 == 0 else Vector3(0.02, 1.1, 0.95),
				"material": &"flat", "tint": Color(0.5, 0.1, 0.09), "collide": false})
			if level == 2:
				continue
			for i: int in 5:
				var along: float = lerpf(-inner, inner, i / 4.0)
				var kind: int = (i + side + level) % 5
				var spot: Vector3 = centre + basis * Vector3(along + rng.randf_range(-0.08, 0.08), top, ledge + rng.randf_range(-0.1, 0.1))
				match kind:
					0:
						props.append({"model": "sugar_skull", "pos": spot, "rot_y": yaw + rng.randf_range(-25.0, 25.0), "scale": 1.4, "collide": false})
					1:
						props.append({"model": "photo_frame_empty", "pos": spot, "rot_y": yaw + 180.0, "scale": 1.3, "collide": false})
					2:
						props.append({"model": "marigold_pile", "pos": spot, "scale": 0.45, "rot_y": rng.randf_range(0.0, 360.0), "collide": false})
					_:
						props.append({"model": ["candle_mid", "candle_tall"][rng.randi() % 2], "pos": spot, "scale": rng.randf_range(1.3, 1.9), "collide": false})
			lights.append({"pos": centre + basis * Vector3(0, top + 0.5, ledge + 0.5), "color": WARM, "energy": 0.55, "radius": 4.5})
	props.append({"model": "copal_censer", "pos": centre + Vector3(0, 3.96, 0), "scale": 1.6, "collide": false})
	for i: int in 30:
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(2.5, 3.6)
		props.append({"model": ["candle_short", "candle_mid", "candle_tall"][rng.randi() % 3], "pos": centre + Vector3(cos(angle) * radius, 0, sin(angle) * radius), "scale": rng.randf_range(1.0, 1.5), "collide": false})
	for angle_index: int in 6:
		var angle: float = angle_index * TAU / 6.0 + 0.4
		props.append({"model": "marigold_pile", "pos": centre + Vector3(cos(angle) * 4.2, 0, sin(angle) * 4.2), "rot_y": angle_index * 50.0, "collide": false})
	for side: int in 4:
		var out: Vector3 = Basis(Vector3.UP, side * PI * 0.5) * Vector3(0, 0.7, 3.3)
		lights.append({"pos": centre + out, "color": WARM, "energy": 0.8, "radius": 7.0})
	lights.append({"pos": centre + Vector3(0, 5.6, 0), "color": Color(1.0, 0.3, 0.6), "energy": 0.35, "radius": 9.0})
	markers["pyramid"] = centre
	markers["letter"] = centre + Vector3(0, 5.25, 0)
	# D09: servilleta en el primer peldaño, del lado por el que se llega desde la tercera ofrenda.
	boxes.append({"pos": centre + Vector3(0.9, 1.326, 2.0), "size": Vector3(0.16, 0.012, 0.16), "material": &"flat", "tint": Color(0.9, 0.88, 0.8), "collide": false, "rot_y": 18.0})
	markers["d09"] = centre + Vector3(0.9, 1.36, 2.0)


## Lo que queda de la oficina: islas de cubículos solos, lejos unos de otros.
func _office_remains(rng: RandomNumberGenerator) -> void:
	for spot: Vector2i in [Vector2i(6, 9), Vector2i(15, 15), Vector2i(23, 5), Vector2i(33, 22), Vector2i(10, 23), Vector2i(25, 12)]:
		var at: Vector3 = cell(spot.x, spot.y)
		var yaw: float = float(rng.randi() % 4) * 90.0
		var basis: Basis = Basis(Vector3.UP, deg_to_rad(yaw))
		props.append({"model": "desk_office", "pos": at, "rot_y": yaw, "occlude": false})
		props.append({"model": "partition_panel", "pos": at + basis * Vector3(0, 0, -0.5), "rot_y": yaw, "collide": false})
		props.append({"model": "chair_office", "pos": at + basis * Vector3(0.2, 0, 0.9), "rot_y": yaw + 180.0 + rng.randf_range(-40.0, 40.0), "collide": false})
		if rng.randi() % 2 == 0:
			props.append({"model": "terminal_crt", "pos": at + Vector3(0, 0.74, 0) + basis * Vector3(-0.3, 0, -0.1), "rot_y": yaw, "collide": false})
		else:
			props.append({"model": "box_cardboard_closed", "pos": at + basis * Vector3(1.2, 0, 0.2), "rot_y": yaw + 20.0, "collide": false})
	for spot: Vector2i in [Vector2i(19, 6), Vector2i(31, 17), Vector2i(12, 12)]:
		props.append({"model": "adobe_rubble", "pos": cell(spot.x, spot.y), "rot_y": float(spot.x * 37), "occlude": false})
	for spot: Vector2i in [Vector2i(24, 18), Vector2i(8, 13)]:
		props.append({"model": "stone_stele", "pos": cell(spot.x, spot.y) + Vector3(0.5, 0, 0.5), "rot_y": float(spot.y * 20)})


func _column(x: int, y: int) -> void:
	var at: Vector3 = cell(x, y)
	props.append({"model": "column_capital", "pos": at + Vector3(0, HALL_HEIGHT, 0), "scale": 1.7, "collide": false})
	props.append({"model": "column_base", "pos": at, "scale": 1.6, "collide": false})


func cell(x: int, y: int) -> Vector3:
	return Vector3((x + 0.5) * cell_size, 0.0, (y + 0.5) * cell_size)


func _fill(grid: Array[String], x0: int, y0: int, x1: int, y1: int, tile: String) -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			_put(grid, x, y, tile)


func _put(grid: Array[String], x: int, y: int, tile: String) -> void:
	grid[y] = grid[y].substr(0, x) + tile + grid[y].substr(x + 1)
