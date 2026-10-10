class_name LevelDef
extends RefCounted

## Datos del nivel; las definiciones concretas rellenan estos campos en _init().
var name: String = ""
var rows: PackedStringArray = PackedStringArray()
var cell_size: float = 2.0
var wall_height: float = 2.8
## true = suelo/techo solo en celdas que los declaren; el resto es abismo sin colisión.
var open_void: bool = false
## Grosor de las islas: faldón e inferior con `edge` o material de suelo. Finito y > 0.
var void_skirt_depth: float = 0.5
## Bloques de N×N celdas bajo Chunks; 0 conserva Geometry. Entero >= 0.
var chunk_cells: int = 0
## Distancia de ocultación por bloque; 0 desactiva. Finita y >= 0; margen con histéresis.
var visibility_range: float = 0.0
var ambient: Color = Color(0.02, 0.02, 0.02)
var bounce: float = 0.25
## Tiles: `height: float` finito > 0 (defecto wall_height; puerta >= 2.1),
## `floor_y: float` <= 0 (suelo hundido: contrahuella vista y rampa de colisión hacia el vecino),
## `edge: StringName` (faldón/inferior), `nav: bool` (false fuerza no transitable),
## `zone: String` o `zones: Array[String]` (nombres no vacíos, sin duplicados por celda).
## `light.panel: bool` (defecto true; false omite luminaria y difusor),
## `light.height: float` finito > 0 (altura absoluta del foco; defecto height - 0.02).
## Metas de raíz: grid_width/grid_height; cell_heights y walkable en orden fila×ancho+columna;
## zones: Dictionary de nombre a Array[Vector2i]. Altura efectiva de puertas = 2.1 para navegación.
var tiles: Dictionary = {}
var materials: Dictionary = {}
var boxes: Array[Dictionary] = []
var lights: Array[Dictionary] = []
var markers: Dictionary = {}
## Zócalo a lo largo de todos los muros; altura 0 = sin zócalo. Usa la paleta de tintes.
var baseboard_tint: Color = Color(0.2, 0.2, 0.2)
var baseboard_height: float = 0.1
## Color de la luz de los fluorescentes que parpadean (van aparte, en el canal alfa del horneado).
var flicker_color: Color = Color(1.0, 0.9, 0.72)
## Modelos low-poly (regla dura 10): `assets/models/<model>.glb` fundido en la malla horneada.
## Claves: `model: String`, `pos: Vector3` (origen del modelo), `rot_y: float` grados, `scale: float`,
## `collide: bool` (caja a partir de sus límites, por defecto true), `occlude: bool` (da sombra en el
## horneado; solo con giros múltiplos de 90°), `screen_material: StringName` (material del nivel para
## la superficie `Screen`, por defecto `screen`), `screen_marker: String` (marcador delante de la pantalla),
## `tints: Dictionary` (nombre de material de Blender → Color, para variantes envejecidas).
## `tilt: Vector3` finito, grados X/Z (Y debe ser 0; se usa rot_y). Defecto Vector3.ZERO.
## Un prop inclinado usa la AABB mundial como colisión/oclusor; sin inclinación conserva su caja.
var props: Array[Dictionary] = []
## Doble realidad: cada material puede llevar su piel de backrooms (`alt_texture`, `alt_uv_scale`,
## `alt_tint`) y el global de shader `reality` (0 = backrooms, 1 = real) elige cuál se ve. Con esto
## activo, las luces `flicker: true` son las de backrooms (solo alumbran con reality = 0) y el
## resto las reales. Emisivos: `reality_side` 1 = solo en lo real, -1 = solo en backrooms.
var dual_reality: bool = false
## Los modelos con versión texturizada en `assets/models/hero/` (Meshy) no se funden en la malla:
## quedan en el meta `hero_props` y el nivel los instancia con `shaders/hero_prop.gdshader`.
var hero_props: bool = true
## Oclusión ambiental horneada: exponente sobre la luz real (1 = como siempre; 2–3 = rincones y
## encuentros muro-suelo bien marcados) y sombra de contacto bajo los objetos apoyados en el suelo.
var ao_strength: float = 1.0
var contact_radius: float = 0.55
var contact_strength: float = 0.0


## Letrero de pared o colgante (modelos `sign_*`). `facing` = hacia dónde mira su cara (unitario).
## Deja dos marcadores para que el nivel escriba el texto: `sign_<key>_<n>` (centro del texto) y
## `sign_<key>_<n>_n` (un metro por delante, para orientarlo). `arrow`: -1 izquierda, 0 sin flecha, 1 derecha.
func add_sign(key: String, pos: Vector3, facing: Vector3, arrow: int = 0, hanging: bool = false, tints: Dictionary = {}) -> void:
	var model: String = "sign_hanging" if hanging else ["sign_wall_left", "sign_wall", "sign_wall_right"][arrow + 1]
	props.append({"model": model, "pos": pos, "rot_y": rad_to_deg(atan2(facing.x, facing.z)), "collide": false, "tints": tints})
	# El texto se aparta de la flecha; "derecha" es la del que mira el letrero de frente.
	var viewer_right: Vector3 = Vector3(facing.z, 0.0, -facing.x)
	var index: int = 0
	while markers.has("sign_%s_%d" % [key, index]):
		index += 1
	var text_at: Vector3 = pos + facing * (0.02 if hanging else 0.022) - viewer_right * 0.07 * arrow
	markers["sign_%s_%d" % [key, index]] = text_at
	markers["sign_%s_%d_n" % [key, index]] = text_at + facing
