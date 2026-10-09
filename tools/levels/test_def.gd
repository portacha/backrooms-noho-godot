extends LevelDef

## Muestra técnica: pared central, dintel, vacío, paneles y mobiliario.
func _init() -> void:
	name = "test"
	rows = PackedStringArray([
		"#########",
		"#sL.#...#",
		"#...#...#",
		"#m..#..m#",
		"#...D.F.#",
		"#...#v ?#",
		"#########",
	])
	ambient = Color(0.025, 0.025, 0.025)
	bounce = 0.25
	materials = {
		&"wall": {"tint": Color(0.65, 0.57, 0.36), "texture": "res://assets/textures/pending_test_wall.png", "uv_scale": 2.0},
		&"floor": {"tint": Color(0.28, 0.25, 0.18), "uv_scale": 1.0},
		&"ceiling": {"tint": Color(0.68, 0.65, 0.5)},
		&"screen": {"tint": Color(0.12, 0.5, 0.75), "emissive": true, "energy": 1.5},
	}
	tiles = {
		"#": {"solid": true, "wall": &"wall"},
		".": {"floor": &"floor", "ceiling": &"ceiling"},
		"s": {"floor": &"floor", "ceiling": &"ceiling", "marker": "camera"},
		"m": {"floor": &"floor", "ceiling": &"ceiling", "marker": "repeat"},
		"D": {"floor": &"floor", "ceiling": &"ceiling", "door": true, "wall": &"wall"},
		"v": {"floor": &"floor", "void_wall": &"wall"},
		"L": {"floor": &"floor", "ceiling": &"ceiling", "light": {"color": Color(1.0, 0.9, 0.7), "energy": 2.0, "radius": 14.0}},
		"F": {"floor": &"floor", "ceiling": &"ceiling", "light": {"color": Color(1.0, 0.9, 0.72), "energy": 1.4, "radius": 5.0, "flicker": true}},
	}
	boxes = [
		{"pos": Vector3(3.2, 0.6, 5.0), "size": Vector3(1.0, 1.2, 0.8), "material": &"wall", "occlude": true},
		{"pos": Vector3(6.6, 0.4, 7.0), "size": Vector3(0.7, 0.8, 0.7), "material": &"floor", "rot_y": 25.0},
		{"pos": Vector3(4.6, 1.4, 2.06), "size": Vector3(1.0, 0.65, 0.04), "material": &"screen", "uv_fit": true, "collide": false},
	]
	lights = [{"pos": Vector3(3.0, 1.5, 9.0), "color": Color(0.7, 0.3, 0.08), "energy": 0.4, "radius": 3.0, "flicker": false}]
	markers = {"bright": Vector3(5, 0, 3), "shadow": Vector3(11, 0, 3), "exit": Vector3(11, 0, 9)}
