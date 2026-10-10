extends LevelDef

## Muestra técnica: alturas, conducto, islas, zonas y mobiliario inclinado.
func _init() -> void:
	name = "test"
	open_void = true
	void_skirt_depth = 0.6
	chunk_cells = 2
	visibility_range = 24.0
	rows = PackedStringArray([
		"########",
		"#L.hc  #",
		"#.n.p  #",
		"#F..r  #",
		"########",
	])
	ambient = Color(0.025, 0.025, 0.025)
	bounce = 0.25
	materials = {
		&"wall": {"tint": Color(0.65, 0.57, 0.36)},
		&"floor": {"tint": Color(0.28, 0.25, 0.18)},
		&"ceiling": {"tint": Color(0.68, 0.65, 0.5)},
		&"edge": {"tint": Color(0.16, 0.14, 0.1)},
	}
	tiles = {
		"#": {"solid": true, "wall": &"wall"},
		".": {"floor": &"floor", "ceiling": &"ceiling"},
		"h": {"floor": &"floor", "ceiling": &"ceiling", "height": 4.8, "zone": "agua", "zones": ["agua", "disparador"], "edge": &"edge"},
		"c": {"floor": &"floor", "ceiling": &"ceiling", "height": 1.2, "wall": &"wall", "zone": "conducto"},
		"n": {"floor": &"floor", "ceiling": &"ceiling", "nav": false},
		"p": {"floor": &"floor", "zone": "remanso"},
		"r": {"ceiling": &"ceiling", "height": 3.6},
		"L": {"floor": &"floor", "ceiling": &"ceiling", "light": {"panel": false, "height": 1.5, "energy": 2.0, "radius": 8.0}},
		"F": {"floor": &"floor", "ceiling": &"ceiling", "light": {"height": 2.4, "radius": 5.0, "flicker": true}},
	}
	# Tabique arquitectónico: comprueba la huella de colisión sin crear utilería primitiva.
	boxes = [{"pos": Vector3(3.0, 0.6, 5.0), "size": Vector3(0.7, 1.2, 0.2), "material": &"wall", "rot_y": 25.0, "occlude": false}]
	props = [{"model": "desk_office", "pos": Vector3(9.0, 0.0, 5.0), "rot_y": 30.0, "tilt": Vector3(15.0, 0.0, -12.0), "occlude": true}]
	markers = {"start": Vector3(3.0, 0.0, 3.0), "void": Vector3(11.0, 0.0, 5.0)}
