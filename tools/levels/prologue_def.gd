extends LevelDef
## Prólogo — "La Oficina de la Realidad" (docs/14). Oficina corporativa estéril de estética
## retro-moderna (blanco, piso azul NOHO, terminales): sala de trabajo con filas de puestos, pasillos
## blancos, vestíbulo con recepción y sala de juntas. Todo el mobiliario son modelos de `assets/models` (regla dura 10).

## Mamparas (eje X) que separan las filas de puestos, y posiciones X de los puestos por lado.
const ROW_PARTITIONS: Array[float] = [26.6, 30.4, 34.2]
const WEST_STATIONS: Array[float] = [14.6, 17.8]
const EAST_STATIONS: Array[float] = [24.2, 27.4]
## Puesto del jugador: lado oeste, junto a la pared, fila central.
const MY_ROW: int = 1
const MY_X: float = 14.6
const DESK_HEIGHT: float = 0.74


func _init() -> void:
	name = "prologue"
	cell_size = 2.0
	wall_height = 2.8
	ambient = Color(0.05, 0.055, 0.06)
	bounce = 0.3
	baseboard_tint = Color(0.2, 0.22, 0.21)
	rows = PackedStringArray([
		"######################",
		"########.L.L.#########",
		"########.....#########",
		"########.L.L.#########",
		"########.....#########",
		"##########D###########",
		"#####..F..L..F...#####",
		"#####.##.L.L.###.#####",
		"#####F##.....###F#####",
		"#####.####.#####.#####",
		"#####.####F#####.#####",
		"#####..F..F..F...#####",
		"##########D###########",
		"######L.L.L.L.L#######",
		"######.........#######",
		"######L.L.L.L.L#######",
		"######.........#######",
		"######L.L.L.L.L#######",
		"######.........#######",
		"######################",
	])
	var light: Dictionary = {"color": Color(0.93, 0.97, 1.0), "energy": 0.72, "radius": 9.0, "flicker": false}
	# Tubos de los pasillos: fijos hasta que el guion los hace fallar (`flicker_override`).
	var faulty: Dictionary = light.merged({"flicker": true})
	flicker_color = light["color"]
	tiles = {
		"#": {"solid": true, "wall": &"wall"},
		".": {"floor": &"carpet", "ceiling": &"ceiling"},
		"L": {"floor": &"carpet", "ceiling": &"ceiling", "light": light},
		"F": {"floor": &"carpet", "ceiling": &"ceiling", "light": faulty},
		"D": {"floor": &"carpet", "ceiling": &"ceiling", "door": true, "wall": &"wall"},
	}
	materials = {
		&"wall": {"texture": "res://assets/textures/office_wall.png", "uv_scale": 2.0},
		&"carpet": {"texture": "res://assets/textures/office_carpet.png", "uv_scale": 1.0, "tint": Color("1f5fff"), "texture_saturation": 0.0, "texture_gain": 2.6},
		&"ceiling": {"texture": "res://assets/textures/office_ceiling.png", "uv_scale": 1.2},
		&"screen": {"texture": "res://assets/textures/screen_lock.png", "emissive": true, "energy": 1.5},
		&"mail": {"emissive": true, "tint": Color(0.92, 0.95, 1.0), "energy": 1.6},
	}
	markers = {
		"start": Vector3(MY_X - 0.2, 0.0, ROW_PARTITIONS[MY_ROW] + 1.75),
		"exit_door": Vector3(21.0, 1.2, 37.9),
		"painting": Vector3(21.0, 1.5, 2.04),
		"mirror_frame": Vector3(21.0, 1.65, 3.3),
		"boardroom_door": Vector3(21.0, 0.0, 11.0),
		"d03": Vector3(23.4, 1.5, 2.06),
		"crate": Vector3(21.0, 0.85, 19.74),
		"junction": Vector3(21.0, 0.0, 23.0),
		"logo": Vector3(24.0, 1.75, 17.868),
	}
	_build_workroom()
	_build_corridors()
	_build_lobby()
	_build_boardroom()
	_build_signs()


func _prop(model: String, pos: Vector3, rot_y: float = 0.0, extra: Dictionary = {}) -> void:
	var prop: Dictionary = {"model": model, "pos": pos, "rot_y": rot_y}
	prop.merge(extra)
	props.append(prop)


## Puesto de trabajo: mesa, terminal, teclado y silla. El usuario se sienta al sur mirando al norte.
func _station(x: float, partition_z: float, index: int) -> void:
	var desk_z: float = partition_z + 0.46
	var mine: bool = is_equal_approx(x, MY_X) and is_equal_approx(partition_z, ROW_PARTITIONS[MY_ROW])
	var neighbour: bool = is_equal_approx(x, WEST_STATIONS[1]) and is_equal_approx(partition_z, ROW_PARTITIONS[MY_ROW])
	_prop("desk_office", Vector3(x, 0.0, desk_z), 0.0, {"occlude": true})
	var terminal: Dictionary = {"collide": false}
	if mine:
		terminal["screen_marker"] = "my_screen"
	elif neighbour:
		terminal["screen_marker"] = "d02_screen"
	_prop("terminal_crt", Vector3(x - 0.22, DESK_HEIGHT, desk_z - 0.1), 0.0, terminal)
	_prop("keyboard_retro", Vector3(x - 0.22, DESK_HEIGHT, desk_z + 0.21), 0.0, {"collide": false})
	markers["pc_%d" % index] = Vector3(x - 0.22, 1.0, desk_z)
	if index % 3 == 0:
		_prop("phone_desk", Vector3(x + 0.42, DESK_HEIGHT, desk_z - 0.08), -12.0, {"collide": false})
	if mine:
		# Silla apartada: el jugador acaba de levantarse. Taza membretada sobre la mesa.
		_prop("chair_office", Vector3(x - 1.0, 0.0, desk_z + 1.2), 125.0)
		_prop("mug", Vector3(x + 0.3, DESK_HEIGHT, desk_z + 0.15), 40.0, {"collide": false})
	else:
		_prop("chair_office", Vector3(x - 0.22, 0.0, desk_z + 0.82), 180.0 + (index * 37 % 30) - 15.0)
	if index % 4 == 1:
		_prop("trash_bin", Vector3(x + 0.95, 0.0, desk_z + 0.1))


func _build_workroom() -> void:
	var index: int = 0
	for partition_z: float in ROW_PARTITIONS:
		for side: Array[float] in [WEST_STATIONS, EAST_STATIONS]:
			var first: float = side[0] - 0.8
			for panel: int in 4:
				_prop("partition_panel", Vector3(first + panel * 1.6, 0.0, partition_z), 0.0, {"occlude": true})
			for x: float in side:
				_station(x, partition_z, index)
				index += 1
	# Archivadores contra la pared sur, dispensador de agua y reloj detenido en las 23:47.
	for i: int in 5:
		_prop("filing_cabinet", Vector3(13.0 + i * 0.5, 0.0, 37.68), 180.0, {"occlude": true})
	_prop("filing_cabinet", Vector3(29.5, 0.0, 37.68), 180.0, {"occlude": true})
	_prop("filing_cabinet", Vector3(29.0, 0.0, 37.68), 180.0, {"occlude": true})
	_prop("water_cooler", Vector3(23.0, 0.0, 26.3), 0.0)
	_prop("wall_clock", Vector3(24.6, 2.1, 26.0), 0.0, {"collide": false})
	# Puerta de salida (cerrada) y su letrero apagado.
	_prop("door_exit", Vector3(21.0, 0.0, 38.0), 180.0, {"collide": false})
	_prop("exit_sign", Vector3(21.0, 2.42, 38.0), 180.0, {"collide": false})


## Señalética corporativa (docs/14 §4): guía hacia la sala de juntas sin marcadores de HUD.
func _build_signs() -> void:
	var south: Vector3 = Vector3(0.0, 0.0, 1.0)
	# Colgante sobre el pasillo central de la sala de trabajo, ante la puerta norte.
	add_sign("hjuntas", Vector3(21.0, 2.37, 27.2), south, 0, true)
	# Cruce tras la puerta: el paso directo está cortado por la caja; los dos rodeos valen.
	add_sign("juntas", Vector3(18.6, 1.7, 22.0), south, -1)
	add_sign("juntas", Vector3(23.4, 1.7, 22.0), south, 1)
	# Esquinas de los rodeos (oeste y este): giro al norte y luego hacia el centro.
	add_sign("juntas", Vector3(10.0, 1.7, 23.0), Vector3(1.0, 0.0, 0.0), 1)
	add_sign("juntas", Vector3(34.0, 1.7, 23.0), Vector3(-1.0, 0.0, 0.0), -1)
	add_sign("juntas", Vector3(11.0, 1.7, 12.0), south, 1)
	add_sign("juntas", Vector3(33.0, 1.7, 12.0), south, -1)
	# Junto a la puerta de la sala.
	add_sign("juntas", Vector3(19.4, 1.7, 12.0), south, 0)


func _build_corridors() -> void:
	# La caja del lienzo, atravesada en el pasillo directo (docs/14 §4).
	_prop("crate_painting", Vector3(21.0, 0.0, 19.5), 0.0, {"occlude": true})
	_prop("box_cardboard_closed", Vector3(20.35, 0.0, 20.25), 18.0)
	_prop("box_cardboard_open", Vector3(21.55, 0.0, 20.3), -14.0)
	_prop("bubble_wrap_roll", Vector3(21.75, 0.0, 18.95), 0.0)
	# Cuadros pequeños con aplique en los dos rodeos, alternando de pared.
	var east: Vector3 = Vector3(1.0, 0.0, 0.0)
	for z: float in [15.6, 20.6]:
		_frame(Vector3(10.0, 1.55, z), east)
		_frame(Vector3(34.0, 1.55, z), -east)
	_frame(Vector3(12.0, 1.55, 18.4), -east)
	_frame(Vector3(32.0, 1.55, 18.4), east)


## Cuadro de pasillo: marco con aplique, luz cálida horneada y marcadores para que el nivel
## ponga el lienzo (`art_<n>` centro, `art_<n>_n` un metro por delante).
func _frame(pos: Vector3, facing: Vector3) -> void:
	_prop("frame_small", pos, rad_to_deg(atan2(facing.x, facing.z)), {"collide": false})
	var index: int = 0
	while markers.has("art_%d" % index):
		index += 1
	markers["art_%d" % index] = pos + facing * 0.014
	markers["art_%d_n" % index] = pos + facing
	lights.append({"pos": pos + facing * 0.45 + Vector3(0.0, 0.4, 0.0), "color": Color(1.0, 0.84, 0.6), "energy": 0.5, "radius": 2.4, "flicker": false})


## Vestíbulo ante la sala de juntas: portada de nogal, dos columnas, recepción al este (D01) y
## espera al oeste, con muros de listones al fondo de cada nicho.
func _build_lobby() -> void:
	_prop("door_portal", Vector3(21.0, 0.0, 12.053), 0.0, {"collide": false})
	_prop("column_round", Vector3(19.7, 0.0, 14.3), 0.0)
	_prop("column_round", Vector3(22.3, 0.0, 14.3), 0.0)
	for x: float in [18.0, 24.0]:
		_prop("wall_slats", Vector3(x, 0.0, 17.9575), 180.0, {"collide": false})
		lights.append({"pos": Vector3(x, 2.3, 17.1), "color": Color(1.0, 0.82, 0.6), "energy": 0.6, "radius": 4.5, "flicker": false})
	# Recepción: mostrador en L que mira al paso; se entra por detrás, desde el eje central.
	_prop("reception_desk", Vector3(24.3, 0.0, 15.0), 180.0, {"occlude": true})
	_prop("reception_wing", Vector3(22.925, 0.0, 16.125), -90.0, {"occlude": true})
	_prop("terminal_crt", Vector3(24.5, DESK_HEIGHT, 15.0), 0.0, {"collide": false, "screen_material": &"mail", "screen_marker": "d01"})
	_prop("keyboard_retro", Vector3(24.5, DESK_HEIGHT, 15.33), 0.0, {"collide": false})
	_prop("phone_desk", Vector3(25.35, DESK_HEIGHT, 15.1), -10.0, {"collide": false})
	_prop("mug", Vector3(23.75, DESK_HEIGHT, 15.2), 70.0, {"collide": false})
	_prop("chair_office", Vector3(24.5, 0.0, 16.1), 195.0, {"collide": false})
	_prop("trash_bin", Vector3(25.65, 0.0, 15.95))
	_prop("filing_cabinet", Vector3(25.68, 0.0, 16.9), -90.0)
	_prop("logo_plate", Vector3(24.0, 1.75, 17.915), 180.0, {"collide": false})
	markers["pc_reception"] = Vector3(24.5, 1.0, 15.0)
	lights.append({"pos": Vector3(24.5, 1.1, 15.7), "color": Color(0.9, 0.95, 1.0), "energy": 0.4, "radius": 3.5, "flicker": false})
	lights.append({"pos": Vector3(24.0, 1.75, 17.5), "color": Color(0.8, 0.88, 1.0), "energy": 0.35, "radius": 2.5, "flicker": false})
	# Espera: banca contra el muro oeste y jardineras en las esquinas.
	_prop("bench_waiting", Vector3(16.34, 0.0, 15.7), 90.0)
	_prop("planter", Vector3(16.5, 0.0, 17.35), 20.0)
	_prop("planter", Vector3(19.5, 0.0, 17.45), 110.0)


func _build_boardroom() -> void:
	_prop("table_conference", Vector3(21.0, 0.0, 6.9), 0.0, {"occlude": true})
	for i: int in 3:
		var z: float = 5.8 + i * 1.1
		_prop("chair_office", Vector3(22.25, 0.0, z), -90.0 + (i * 23 % 16) - 8.0)
		_prop("chair_office", Vector3(19.75, 0.0, z), 90.0 + (i * 31 % 16) - 8.0)
	# Restos de la instalación: cierran el lado oeste de la mesa (docs/14 §3).
	_prop("box_cardboard_closed", Vector3(16.4, 0.0, 5.3), 8.0)
	_prop("box_cardboard_closed", Vector3(17.1, 0.0, 5.4), -12.0)
	_prop("box_cardboard_open", Vector3(16.75, 0.42, 5.35), 30.0, {"collide": false})
	_prop("bubble_wrap_roll", Vector3(17.85, 0.0, 5.25), 0.0)
	_prop("box_cardboard_open", Vector3(18.45, 0.0, 5.35), 20.0)
	_prop("ladder_a_frame", Vector3(19.4, 0.0, 5.3), 90.0)
	_prop("bubble_wrap_roll", Vector3(16.5, 0.0, 3.0), 0.0)
	# Marco del lienzo (2,4 × 1,8 m) y placa del acta (D03).
	_prop("painting_frame", Vector3(21.0, 1.5, 2.0), 0.0, {"collide": false})
	_prop("plaque", Vector3(23.4, 1.5, 2.0), 0.0, {"collide": false})
	lights.append({"pos": Vector3(21.0, 1.5, 2.9), "color": Color(1.0, 0.62, 0.4), "energy": 0.3, "radius": 7.0, "flicker": false})
	lights.append({"pos": Vector3(20.2, 1.5, 2.9), "color": Color(0.35, 0.5, 1.0), "energy": 0.2, "radius": 6.0, "flicker": false})
