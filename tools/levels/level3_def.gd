extends LevelDef
## Pasaje lineal: cinco recodos, refugios bajos y cámara de barro.

func _init() -> void:
	name = "level3"
	wall_height = 2.8
	baseboard_height = 0.0
	chunk_cells = 8
	visibility_range = 24.0
	ambient = Color(0.022, 0.029, 0.031)
	bounce = 0.22
	materials = {
		&"concrete": {"texture": "res://assets/textures/tunnel_concrete_wet.png", "uv_scale": 2.0},
		&"metal": {"texture": "res://assets/textures/duct_metal.png", "uv_scale": 1.0},
		&"clay": {"texture": "res://assets/textures/clay_black.png", "uv_scale": 2.0},
		&"glow": {"tint": Color(0.32, 0.76, 0.8), "emissive": true, "energy": 0.65},
	}
	tiles = {
		"#": {"solid": true, "wall": &"concrete"},
		".": {"floor": &"concrete", "ceiling": &"concrete", "wall": &"concrete", "zone": "water"},
		"s": {"floor": &"concrete", "ceiling": &"concrete", "wall": &"concrete"},
		"d": {"floor": &"metal", "ceiling": &"metal", "wall": &"metal", "height": 1.2, "nav": false, "zone": "duct"},
		"r": {"floor": &"concrete", "ceiling": &"concrete", "wall": &"concrete", "zone": "remanso"},
		"w": {"floor": &"concrete", "ceiling": &"concrete", "wall": &"concrete", "zones": ["water", "remanso"]},
		"c": {"floor": &"clay", "ceiling": &"clay", "wall": &"clay", "zone": "remanso"},
		"b": {"solid": true, "wall": &"clay"},
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
			props.append({"model": "duct_grille", "pos": Vector3((section.x + 2) * 2.0, 1.16, y * 2.0 + 1.0), "rot_y": 90.0, "collide": false})
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
	props.append({"model": "desk_office", "pos": Vector3(30, -0.18, 85), "tilt": Vector3(9, 0, -8), "collide": false})
	props.append({"model": "wallet_open", "pos": Vector3(35, 0.16, 323), "collide": false})
	for x: int in range(34, 41, 2):
		props.append({"model": "clay_pot_black", "pos": Vector3(x, 0, 368), "collide": false})
		props.append({"model": "sugar_skull", "pos": Vector3(x, 0.46, 368), "rot_y": 180.0, "collide": false})
	for at: Vector3 in [Vector3(30, 0, 83), Vector3(31, 0, 321), Vector3(37, 0, 367)]:
		for i: int in 4:
			props.append({"model": "candle_mid", "pos": at + Vector3((i - 1.5) * 0.32, 0, 0.65), "collide": false})
		lights.append({"pos": at + Vector3(0, 1.0, 0), "color": Color(1, 0.48, 0.16), "energy": 1.1, "radius": 5.0, "panel": false})
	for section: Vector3i in [Vector3i(3, 4, 32), Vector3i(10, 38, 68), Vector3i(18, 74, 104), Vector3i(8, 110, 142), Vector3i(18, 150, 174)]:
		for y: int in range(section.y, section.z + 1, 8):
			var at: Vector3 = Vector3(section.x * 2.0 + 2.0, 2.8, y * 2.0 + 1.0)
			props.append({"model": "sugar_skull_giant", "pos": at, "rot_y": 180.0, "collide": false})
			lights.append({"pos": at - Vector3(0, 0.75, 0), "color": Color(0.3, 0.78, 0.84), "energy": 1.15, "radius": 8.5, "panel": false})
			props.append({"model": "pipe_elbow_valve", "pos": at + Vector3(-1.4, -0.6, 0), "collide": false})
			if section.x == 3:
				props.append({"model": "ledge_walkway", "pos": Vector3(7, 0, y * 2.0 + 1), "rot_y": 90.0, "collide": false})
			else:
				props.append({"model": "marigold_raft", "pos": Vector3(at.x - 0.7, 0.14, at.z), "collide": false})


func _carve(grid: Array[String], x0: int, y0: int, x1: int, y1: int, tile: String = ".") -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			grid[y] = grid[y].substr(0, x) + tile + grid[y].substr(x + 1)
