extends LevelDef
## Arena aislada: pilares arquitectónicos, remanso y conducto lateral.
func _init() -> void:
	name = "entity_arena"
	wall_height = 3.0
	ambient = Color(0.12, 0.11, 0.08)
	rows = PackedStringArray([
		"####################",
		"#..................#",
		"#..................#",
		"#..................#",
		"#....#.......#.....#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#....#.......#.....#",
		"#..................#",
		"#..................#",
		"#..................#",
		"################..##",
		"################..##",
		"####################",
	])
	tiles = {"#": {"solid": true, "wall": &"stone"}, ".": {"floor": &"stone", "ceiling": &"stone"}}
	materials = {&"stone": {"tint": Color(0.4, 0.38, 0.3)}}
	markers = {"safe": Vector3(5, 0, 21), "hide": Vector3(35, 0, 27), "spawn": Vector3(5, 0, 5)}
