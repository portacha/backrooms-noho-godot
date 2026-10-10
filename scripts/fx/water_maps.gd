class_name WaterMaps
extends RefCounted
## Texturas que el agua necesita para leerse como agua (Nivel 3) y que no merece la pena guardar
## en disco: se generan al cargar el nivel a partir de la propia definición.

const SOLID: Array[String] = ["#", "b"]


## Oleaje enlosable: suma de ondas de frecuencia entera. RG = pendiente (0,5 = plano).
static func ripples(size: int = 128, waves: int = 9, seed_value: int = 311) -> ImageTexture:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var set: Array[Vector4] = []
	var total: float = 0.0
	for i: int in waves:
		var k: Vector2 = Vector2(rng.randi_range(-5, 5), rng.randi_range(1, 6))
		var amplitude: float = 1.0 / k.length()
		total += amplitude * k.length()
		set.append(Vector4(k.x, k.y, amplitude, rng.randf() * TAU))
	var image: Image = Image.create_empty(size, size, true, Image.FORMAT_RGB8)
	for y: int in size:
		for x: int in size:
			var slope: Vector2 = Vector2.ZERO
			for wave: Vector4 in set:
				var phase: float = TAU * (wave.x * x + wave.y * y) / size + wave.w
				slope -= Vector2(wave.x, wave.y) * wave.z * sin(phase)
			slope = slope / total * 1.6
			image.set_pixel(x, y, Color(clampf(0.5 + 0.5 * slope.x, 0.0, 1.0), clampf(0.5 + 0.5 * slope.y, 0.0, 1.0), 0.5))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


## Lo que el agua refleja, visto en planta: RGB = lo que brilla arriba (la cara de cada calavera,
## las veladoras) y A = distancia al muro más cercano (0 en el muro, 1 a `shore` metros).
static func ceiling(rows: PackedStringArray, cell_size: float, lights: Array, density: int = 8, shore: float = 0.55) -> ImageTexture:
	var per_cell: int = int(cell_size * density)
	var width: int = rows[0].length() * per_cell
	var height: int = rows.size() * per_cell
	var image: Image = Image.create_empty(width, height, true, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for cy: int in rows.size():
		for cx: int in rows[cy].length():
			if _solid(rows, cx, cy):
				continue
			var walls: Array[Vector2i] = []
			for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if _solid(rows, cx + direction.x, cy + direction.y):
					walls.append(direction)
			if walls.is_empty():
				image.fill_rect(Rect2i(cx * per_cell, cy * per_cell, per_cell, per_cell), Color(0, 0, 0, 1))
				continue
			for py: int in per_cell:
				for px: int in per_cell:
					var u: float = (px + 0.5) / per_cell
					var v: float = (py + 0.5) / per_cell
					var distance: float = 1.0
					for direction: Vector2i in walls:
						var along: float = u if direction.x != 0 else v
						distance = minf(distance, along if direction.x + direction.y < 0 else 1.0 - along)
					image.set_pixel(cx * per_cell + px, cy * per_cell + py, Color(0, 0, 0, clampf(distance * cell_size / shore, 0.0, 1.0)))
	for light: Dictionary in lights:
		if bool(light.get("flicker", false)):
			continue
		var at: Vector3 = light["pos"]
		var colour: Color = light["color"]
		if colour.b > colour.r:
			_stamp_skull(image, Vector2(at.x, at.z) * density, density, colour)
		else:
			_stamp_glow(image, Vector2(at.x, at.z) * density, density * 0.5, colour * float(light["energy"]) * 0.5)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _solid(rows: PackedStringArray, x: int, y: int) -> bool:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return true
	return rows[y][x] in SOLID


## La cara que cuelga del techo, tal como la devuelve el agua: cuencas encendidas, hueso pálido
## y la mandíbula hacia donde se aleja el pasillo (+Z).
static func _stamp_skull(image: Image, centre: Vector2, density: float, glow: Color) -> void:
	var reach: int = int(density * 3.4)
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			# Algo mayor que la calavera real: el reflejo manda sobre la exactitud.
			var at: Vector2 = Vector2(dx, dy) / density / 1.5
			var jaw: float = 1.0 - 0.3 * smoothstep(0.0, 0.8, at.y)
			var face: float = 1.0 - smoothstep(0.78, 1.0, Vector2(at.x / (0.72 * jaw), at.y / 0.86).length())
			var eyes: float = 0.0
			for side: float in [-1.0, 1.0]:
				eyes = maxf(eyes, 1.0 - smoothstep(0.1, 0.26, Vector2(at.x - side * 0.3, (at.y + 0.2) * 1.3).length()))
			var nose: float = 1.0 - smoothstep(0.04, 0.12, Vector2(at.x * 1.4, at.y - 0.22).length())
			var halo: float = pow(maxf(0.0, 1.0 - at.length() / 2.2), 2.0) * 0.4
			var bone: Color = Color(0.5, 0.62, 0.62) * 0.42 * face
			var lit: Color = bone + glow * (maxf(eyes, nose * 0.8) * 1.0 + halo)
			_add(image, int(centre.x) + dx, int(centre.y) + dy, lit)


static func _stamp_glow(image: Image, centre: Vector2, radius: float, glow: Color) -> void:
	var reach: int = int(radius)
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			var falloff: float = maxf(0.0, 1.0 - Vector2(dx, dy).length() / radius)
			_add(image, int(centre.x) + dx, int(centre.y) + dy, glow * falloff * falloff)


static func _add(image: Image, x: int, y: int, light: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	var pixel: Color = image.get_pixel(x, y)
	image.set_pixel(x, y, Color(minf(pixel.r + light.r, 1.0), minf(pixel.g + light.g, 1.0), minf(pixel.b + light.b, 1.0), pixel.a))
