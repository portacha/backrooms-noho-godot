class_name LevelDef
extends RefCounted

## Datos del nivel; las definiciones concretas rellenan estos campos en _init().
var name: String = ""
var rows: PackedStringArray = PackedStringArray()
var cell_size: float = 2.0
var wall_height: float = 2.8
var ambient: Color = Color(0.02, 0.02, 0.02)
var bounce: float = 0.25
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
var props: Array[Dictionary] = []


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
