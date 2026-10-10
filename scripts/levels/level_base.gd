class_name LevelBase
extends Node3D
## Base de nivel: geometría pre-horneada (tools/build_levels.gd) + jugador + HUD.
## Los objetos de juego se colocan en los marcadores de la geometría.

signal checkpoint_reached(id: String)

const SIGN_FONT: Font = preload("res://assets/fonts/nunito_bold.tres")
const PETALS_TEXTURE: Texture2D = preload("res://assets/textures/petals.png")
const ENTITY_SCENE: String = "res://scenes/entity/olvidado.tscn"
const SWELL_SOUND: String = "res://assets/audio/sfx/letter_swell.ogg"
## Margen con el que la entidad llegaría a la puerta después del jugador que no deja de correr.
const FINAL_CHASE_MARGIN: float = 1.5
## Altura del centro de cada jirón de bruma sobre el suelo del jugador (`rise` en `mist.gdshader`).
const MIST_RISE: float = 1.4

## El Olvidado de este nivel, si lo hay (`spawn_entity`).
var entity: Olvidado = null

## 0 = backrooms (lo que la mente pone), 1 = lo real. Solo en niveles con `dual_reality`.
var reality: float = 1.0

## Niebla de cada piel (densidad < 0 = el nivel no la cambia): polvo claro de oficina frente a la
## bruma espesa y teñida de lo real.
var fog_real_color: Color = Color(0.03, 0.03, 0.03)
var fog_real_density: float = -1.0
var fog_backrooms_color: Color = Color(0.05, 0.045, 0.02)
var fog_backrooms_density: float = 0.012

var _checkpoints: Array[Dictionary] = []
var _reality_tween: Tween = null
var _petal_count: int = 0
var _mist: MultiMesh = null
var _mist_material: ShaderMaterial = null
var _mist_reach: float = 15.0
var _mist_indoors: bool = true

@onready var geo: Node3D = $Geo
@onready var player: Player = $Player
@onready var hud: Hud = $Hud
@onready var screen_fx: ScreenFx = $ScreenFx
@onready var pause_menu: Node = get_node_or_null("PauseMenu")
@onready var touch_controls: Node = get_node_or_null("TouchControls")


func _ready() -> void:
	RenderingServer.global_shader_parameter_set(&"world_light", 1.0)
	RenderingServer.global_shader_parameter_set(&"flicker_override", -1.0)
	set_reality(1.0)
	_spawn_hero_props()
	hud.reading_started.connect(_on_reading_changed.bind(true))
	hud.reading_finished.connect(_on_reading_changed.bind(false))


func _process(_delta: float) -> void:
	_update_checkpoints()
	_update_mist()


func marker(marker_name: String) -> Vector3:
	var node: Node3D = geo.get_node_or_null("Markers/" + marker_name) as Node3D
	if node == null:
		push_error("Falta el marcador '%s' en %s" % [marker_name, geo.name])
		return Vector3.ZERO
	return node.global_position


func has_marker(marker_name: String) -> bool:
	return geo.has_node("Markers/" + marker_name)


func add_interactable(at: Vector3, interaction_range: float = 2.0, hold_time: float = 0.0) -> Interactable:
	var node: Interactable = Interactable.new()
	node.interaction_range = interaction_range
	node.hold_time = hold_time
	add_child(node)
	node.global_position = at
	return node


func add_document(at: Vector3, path: String, interaction_range: float = 2.0) -> DocumentPickup:
	var node: DocumentPickup = DocumentPickup.new()
	node.document = load(path) as DocumentData
	node.interaction_range = interaction_range
	add_child(node)
	node.global_position = at
	return node


## Instancia un modelo de `assets/models` para objetos dinámicos (los estáticos se hornean en la
## geometría). Sin luz en tiempo real, se ven por emisión: `glow` para el cuerpo, `special_glow`
## para las superficies `Glow`, `Flame` y `Screen`.
func spawn_model(model: String, parent: Node3D, glow: float = 0.35, special_glow: float = 2.5) -> Node3D:
	var packed: PackedScene = load("res://assets/models/%s.glb" % model) as PackedScene
	var instance: Node3D = packed.instantiate() as Node3D
	parent.add_child(instance)
	for node: Node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface: int in mesh_instance.mesh.get_surface_count():
			var source: BaseMaterial3D = mesh_instance.get_active_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var material: StandardMaterial3D = StandardMaterial3D.new()
			var special: bool = source.resource_name in ["Glow", "Flame", "Screen"]
			material.albedo_color = Color.BLACK if special else source.albedo_color
			material.roughness = 1.0
			material.emission_enabled = true
			material.emission = source.albedo_color
			material.emission_energy_multiplier = special_glow if special else glow
			mesh_instance.set_surface_override_material(surface, material)
	return instance


## Escribe el texto de los letreros que dejó la definición del nivel (`LevelDef.add_sign`).
## `texts`: clave del letrero → texto. Los colgantes (clave que empieza por "h") llevan letra mayor.
func build_signs(texts: Dictionary, ink: Color) -> void:
	for node: Node in geo.get_node("Markers").get_children():
		var marker_name: String = node.name
		if not marker_name.begins_with("sign_") or marker_name.ends_with("_n"):
			continue
		var key: String = marker_name.trim_prefix("sign_").rsplit("_", true, 1)[0]
		if not texts.has(key):
			continue
		var at: Vector3 = (node as Node3D).global_position
		var facing: Vector3 = marker(marker_name + "_n") - at
		var label: Label3D = Label3D.new()
		label.text = texts[key]
		label.font = SIGN_FONT
		label.font_size = 96 if key.begins_with("h") else 64
		label.pixel_size = 0.0011 if key.begins_with("h") else 0.00078
		label.outline_size = 0
		label.modulate = ink
		add_child(label)
		label.global_position = at
		label.rotation.y = atan2(facing.x, facing.z)


func set_can_pause(value: bool) -> void:
	if pause_menu != null:
		pause_menu.set("can_pause", value)


func set_touch_button(property: StringName, value: bool) -> void:
	if touch_controls != null:
		touch_controls.set(property, value)


func is_touch() -> bool:
	return DisplayServer.is_touchscreen_available() and (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"))


func play_sound(stream: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	var audio: AudioStreamPlayer = AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume_db
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)
	return audio


func add_loop(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var audio: AudioStreamPlayer = AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume_db
	add_child(audio)
	audio.play()
	return audio


# --- Checkpoints ---------------------------------------------------------------------------

## Coloca al jugador en el checkpoint guardado (`cp_<id>`; mirada hacia `cp_<id>_look` si existe)
## o en `start_marker`. Devuelve el id usado ("" = inicio).
func spawn_at_checkpoint(start_marker: String = "start", yaw: float = 0.0) -> String:
	var id: String = Game.current_checkpoint()
	if not id.is_empty() and has_marker("cp_" + id):
		var at: Vector3 = marker("cp_" + id)
		var facing: float = yaw
		if has_marker("cp_%s_look" % id):
			var look: Vector3 = marker("cp_%s_look" % id) - at
			facing = atan2(-look.x, -look.z)
		player.respawn_at(at, facing)
		return id
	player.respawn_at(marker(start_marker), yaw)
	Game.set_checkpoint("")
	return ""


## Autosave silencioso al entrar en el radio del marcador (docs/13 §8).
func add_checkpoint(id: String, marker_name: String, radius: float = 3.0) -> void:
	_checkpoints.append({"id": id, "at": marker(marker_name), "radius": radius})


func _update_checkpoints() -> void:
	for i: int in _checkpoints.size():
		var checkpoint: Dictionary = _checkpoints[i]
		var offset: Vector3 = player.global_position - (checkpoint["at"] as Vector3)
		offset.y = 0.0
		if offset.length() < float(checkpoint["radius"]):
			_checkpoints.remove_at(i)
			# Nunca se guarda en mitad de una persecución (docs/12 §4.3).
			if entity != null and entity.current_state() in [&"Chase", &"Attack"]:
				_checkpoints.append(checkpoint)
				return
			Game.set_checkpoint(String(checkpoint["id"]))
			checkpoint_reached.emit(String(checkpoint["id"]))
			return


# --- Zonas del constructor (clave de tile "zone") -----------------------------------------

func zone_cells(zone: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var zones: Dictionary = geo.get_meta("zones", {})
	if zones.has(zone):
		cells.assign(zones[zone])
	return cells


func cell_of(at: Vector3) -> Vector2i:
	var size: float = geo.get_meta("cell_size")
	var local: Vector3 = at - geo.global_position
	return Vector2i(floori(local.x / size), floori(local.z / size))


func cell_center(cell: Vector2i) -> Vector3:
	var size: float = geo.get_meta("cell_size")
	return geo.global_position + Vector3((cell.x + 0.5) * size, 0.0, (cell.y + 0.5) * size)


func in_zone(at: Vector3, zone: String) -> bool:
	return cell_of(at) in zone_cells(zone)


## Una caja por celda de la zona, con la altura de esa celda.
func zone_bounds(zone: String) -> Array[AABB]:
	var bounds: Array[AABB] = []
	var size: float = geo.get_meta("cell_size")
	var width: int = geo.get_meta("grid_width", 0)
	var heights: PackedFloat32Array = geo.get_meta("cell_heights", PackedFloat32Array())
	for cell: Vector2i in zone_cells(zone):
		var index: int = cell.y * width + cell.x
		var height: float = heights[index] if index < heights.size() and heights[index] > 0.0 else 3.0
		bounds.append(AABB(geo.global_position + Vector3(cell.x * size, 0.0, cell.y * size), Vector3(size, height, size)))
	return bounds


# --- El Olvidado ---------------------------------------------------------------------------

## Instancia la entidad con el perfil del nivel. Remansos (`remanso`) y conductos (`duct`) son
## refugio; los marcadores `ambush_<n>` son sus puntos de reubicación. Arranca oculta.
func spawn_entity(profile_path: String) -> Olvidado:
	entity = (load(ENTITY_SCENE) as PackedScene).instantiate() as Olvidado
	entity.profile = (load(profile_path) as EntityProfile).duplicate() as EntityProfile
	entity.profile.starts_hidden = true
	entity.safe_zones = zone_bounds("remanso")
	entity.hide_zones = zone_bounds("duct")
	var index: int = 0
	while has_marker("ambush_%d" % index):
		entity.relocation_points.append(marker("ambush_%d" % index))
		index += 1
	add_child(entity)
	entity.setup(player, geo, screen_fx)
	return entity


## Leer es el respiro: el ajuste decide si congela la presión, la deja decaer o la sube (docs/12 §4).
func _on_reading_changed(_document: DocumentData, reading: bool) -> void:
	if entity == null:
		return
	var rate: float = Game.difficulty.reading_stimulus_per_second
	entity.pressure_frozen = reading and rate < 0.0
	if reading and rate > 0.0:
		_reading_pressure(rate)


func _reading_pressure(rate: float) -> void:
	while hud.is_reading and entity != null:
		entity.add_stimulus(rate * 0.5, player.global_position)
		await get_tree().create_timer(0.5).timeout


## Carrera final (docs/12 §8.4, docs/13 §11): la entidad, enfurecida, sale de `from` hacia el
## jugador con el retraso justo para alcanzarlo solo si deja de correr antes de `goal`. No hay
## fallo automático.
func begin_final_chase(from: Vector3, goal: Vector3) -> void:
	var difficulty: Difficulty = Game.difficulty
	var player_time: float = player.global_position.distance_to(goal) / player.sprint_speed
	entity.set_enraged(true)
	var speed: float = difficulty.entity_chase_speed * entity.profile.speed_scale
	var delay: float = maxf(0.0, player_time + FINAL_CHASE_MARGIN - from.distance_to(goal) / speed)
	await get_tree().create_timer(delay).timeout
	if entity == null or Game.is_dead:
		return
	entity.teleport_to(from)
	entity.add_stimulus(100.0, player.global_position)
	entity.force_state(&"Chase")


# --- Letras-altar --------------------------------------------------------------------------

func add_letter(model: String, marker_name: String, yaw: float = PI, interaction_range: float = 2.6) -> LetterAltar:
	var altar: LetterAltar = LetterAltar.new()
	add_child(altar)
	altar.global_position = marker(marker_name)
	altar.build(self, model, yaw, interaction_range)
	return altar


## Aberración que crece al mantener la interacción con la letra; llamar cada fotograma.
func update_letter_fx(altar: LetterAltar) -> void:
	if not altar.is_taken:
		screen_fx.aberration = altar.hold_ratio * 0.35


## Secuencia estándar de recogida (docs/12 §9, ≈ 6 s): swell, aberración, temblor, bajón de luz,
## `on_mutate` en el punto ciego (cambiar variantes, revelar contaminación) y `on_done` con el
## control ya devuelto. `shake_camera` gasta uno de los tres temblores de la partida (docs/13 §7).
func play_letter_ritual(altar: LetterAltar, on_mutate: Callable, on_done: Callable, shake_camera: bool = true) -> void:
	set_can_pause(false)
	player.controls_enabled = false
	var swell: AudioStream = load_audio(SWELL_SOUND)
	if swell != null:
		play_sound(swell, -1.0)
	Game.caption("[las veladoras se encienden]")
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(altar, "scale", Vector3.ZERO, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(screen_fx, "aberration", 1.0, 1.2)
	if shake_camera:
		tween.tween_method(shake, 1.0, 0.0, 1.4).set_delay(0.9)
	tween.tween_method(set_world_light, 1.0, 0.25, 0.25).set_delay(1.2)
	tween.tween_callback(on_mutate).set_delay(1.3)
	tween.tween_method(set_world_light, 0.25, 0.8, 1.6).set_delay(1.6)
	tween.tween_property(screen_fx, "aberration", 0.15, 1.5).set_delay(1.4)
	tween.chain().tween_callback(func() -> void:
		player.controls_enabled = true
		set_can_pause(true)
		on_done.call())


## Fin del nivel: fundido y siguiente escena de `Game.LEVEL_ORDER`.
func finish_level(from_color: Color = Color.BLACK, fade_time: float = 2.0) -> void:
	set_can_pause(false)
	player.controls_enabled = false
	screen_fx.fade_color = from_color
	var tween: Tween = create_tween()
	tween.tween_property(screen_fx, "fade", 1.0, fade_time)
	tween.tween_callback(func() -> void: Game.next_level(from_color))


# --- Elementos principales con textura (Meshy) --------------------------------------------

const HERO_SHADER: Shader = preload("res://shaders/hero_prop.gdshader")

## Instancia los modelos "hero" que el constructor dejó aparte y les da las cuatro luces
## horneadas más fuertes de su sitio. Sigue sin haber luces en tiempo real (regla dura 4).
func _spawn_hero_props() -> void:
	var records: Array = geo.get_meta("hero_props", [])
	if records.is_empty():
		return
	var lights: Array = geo.get_meta("lights", [])
	var tube_color: Color = geo.get_meta("flicker_color", Color(1.0, 0.93, 0.7))
	var dual: bool = _is_dual()
	var holder: Node3D = Node3D.new()
	holder.name = "HeroProps"
	add_child(holder)
	var cache: Dictionary = {}
	for record: Dictionary in records:
		var model: String = record["model"]
		if not cache.has(model):
			cache[model] = load("res://assets/models/hero/%s.glb" % model)
		var instance: Node3D = (cache[model] as PackedScene).instantiate() as Node3D
		holder.add_child(instance)
		instance.global_transform = geo.global_transform * (record["transform"] as Transform3D)
		light_hero(instance, lights, tube_color, dual, 1.0 if model.ends_with("_giant") else 0.0)


## Aplica el shader de elemento principal a un modelo texturizado ya colocado.
func light_hero(instance: Node3D, lights: Array, tube_color: Color, dual: bool, glow_energy: float = 0.0) -> void:
	var bounds_centre: Vector3 = instance.global_position
	var meshes: Array[Node] = instance.find_children("*", "MeshInstance3D", true, false)
	if not meshes.is_empty():
		var first: MeshInstance3D = meshes[0] as MeshInstance3D
		bounds_centre = first.global_transform * first.get_aabb().get_center()
	# Las cuatro luces reales que más aportan en el centro del objeto; los tubos van aparte.
	var ranked: Array[Dictionary] = []
	var tubes: float = 0.0
	for light: Dictionary in lights:
		var radius: float = light["radius"]
		var distance: float = (light["pos"] as Vector3).distance_to(bounds_centre)
		if distance >= radius:
			continue
		var falloff: float = 1.0 - distance / radius
		var weight: float = float(light["energy"]) * falloff * falloff
		if bool(light.get("flicker", false)):
			tubes += weight
		else:
			ranked.append({"weight": weight, "light": light})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["weight"] > b["weight"])
	var positions: PackedVector3Array = PackedVector3Array()
	var colors: PackedVector3Array = PackedVector3Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	for i: int in 4:
		if i < ranked.size():
			var light: Dictionary = ranked[i]["light"]
			var color: Color = (light["color"] as Color) * float(light["energy"])
			positions.append(light["pos"])
			colors.append(Vector3(color.r, color.g, color.b))
			radii.append(light["radius"])
		else:
			positions.append(Vector3.ZERO)
			colors.append(Vector3.ZERO)
			radii.append(0.01)
	for node: Node in meshes:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface: int in mesh_instance.mesh.get_surface_count():
			var source: BaseMaterial3D = mesh_instance.get_active_material(surface) as BaseMaterial3D
			var material: ShaderMaterial = ShaderMaterial.new()
			material.shader = HERO_SHADER
			if source != null:
				material.set_shader_parameter("albedo_tex", source.albedo_texture)
			material.set_shader_parameter("light_pos", positions)
			material.set_shader_parameter("light_col", colors)
			material.set_shader_parameter("light_rad", radii)
			material.set_shader_parameter("tube_light", Vector3(tube_color.r, tube_color.g, tube_color.b) * tubes)
			material.set_shader_parameter("glow_energy", glow_energy)
			# Lo fosforescente se alumbra a sí mismo: sus colores no dependen de la luz cian.
			material.set_shader_parameter("self_light", 0.3 if glow_energy > 0.0 else 0.0)
			material.set_shader_parameter("dual", dual)
			mesh_instance.set_surface_override_material(surface, material)


## ¿El nivel se horneó con doble realidad? (lo delata el parámetro `dual` de sus materiales).
func _is_dual() -> bool:
	for node: Node in geo.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (node as MeshInstance3D).mesh
		if mesh != null and mesh.get_surface_count() > 0:
			var material: ShaderMaterial = mesh.surface_get_material(0) as ShaderMaterial
			if material != null:
				return material.get_shader_parameter("dual") == true
	return false


# --- Doble realidad ------------------------------------------------------------------------
# Los backrooms son la forma en que la mente del oficinista compensa lo que de verdad hay. Las
# paredes son las mismas; cambia su piel. Nunca hay un corte limpio: parpadea o se va la luz.

func set_reality(value: float) -> void:
	reality = clampf(value, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set(&"reality", reality)
	var world: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment
	if fog_real_density >= 0.0 and world != null:
		world.environment.fog_light_color = fog_backrooms_color.lerp(fog_real_color, reality)
		world.environment.fog_density = lerpf(fog_backrooms_density, fog_real_density, reality)
	_on_reality_changed()


## Los niveles lo redefinen para lo que no pasa por el shader horneado (agua, audio, objetos).
func _on_reality_changed() -> void:
	pass


## Las texturas tartamudean entre las dos pieles y se quedan en `target` (≈ `duration` s).
func flicker_reality(target: float, duration: float = 1.4) -> void:
	if _reality_tween != null:
		_reality_tween.kill()
	var from: float = reality
	_reality_tween = create_tween()
	var steps: int = maxi(4, int(duration / 0.09))
	for i: int in steps:
		var progress: float = float(i + 1) / steps
		# Cada salto cae en un punto distinto entre las dos pieles y reordena los parches.
		var value: float = target if i == steps - 1 else clampf(lerpf(from, target, progress) + randf_range(-0.45, 0.45), 0.0, 1.0)
		_reality_tween.tween_callback(func() -> void:
			RenderingServer.global_shader_parameter_set(&"reality_seed", randf() * 100.0)
			set_reality(value))
		_reality_tween.tween_interval(randf_range(0.03, 0.14))
	Game.caption("[las paredes parpadean]", 2.0)


## Se va toda la luz; cuando vuelve, el lugar es otro (`dark` s a oscuras).
func blackout_reality(target: float, dark: float = 1.1) -> void:
	if _reality_tween != null:
		_reality_tween.kill()
	_reality_tween = create_tween()
	_reality_tween.tween_method(set_world_light, 1.0, 0.0, 0.12)
	_reality_tween.tween_callback(func() -> void:
		player.flashlight.pulse_blackout(dark + 0.25)
		RenderingServer.global_shader_parameter_set(&"reality_seed", randf() * 100.0)
		set_reality(target))
	_reality_tween.tween_interval(dark)
	_reality_tween.tween_method(set_world_light, 0.0, 1.0, 0.35)
	Game.caption("[se va la luz]", 2.0)


## Recaída breve: la otra piel asoma `seconds` y se va (alucinación pasajera).
func glimpse_reality(value: float, seconds: float = 0.5) -> void:
	var back: float = reality
	RenderingServer.global_shader_parameter_set(&"reality_seed", randf() * 100.0)
	set_reality(value)
	await get_tree().create_timer(seconds).timeout
	if is_equal_approx(reality, value):
		set_reality(back)


# --- Utilidades ----------------------------------------------------------------------------

func set_world_light(value: float) -> void:
	RenderingServer.global_shader_parameter_set(&"world_light", value)


func shake(strength: float) -> void:
	if Game.reduced_camera_motion:
		return
	player.camera.h_offset = randf_range(-1.0, 1.0) * 0.05 * strength
	player.camera.v_offset = randf_range(-1.0, 1.0) * 0.05 * strength


## Bruma de la dimensión oscura: un puñado de jirones que acompañan al jugador y se recolocan
## fuera de su alcance visible. Con `dual` siguen a `reality` (solo en lo real); con `indoors`
## solo ocupan celdas transitables. La niebla del
## `Environment` da la distancia; esto es lo que se ve moverse en el aire y en el haz de la linterna.
func add_mist(tint: Color, density: float = 0.3, count: int = 14, reach: float = 15.0, dual: bool = true, indoors: bool = true, sheet: Vector2 = Vector2(7.0, 3.6)) -> void:
	_mist_indoors = indoors
	_mist_material = ShaderMaterial.new()
	_mist_material.shader = load("res://shaders/mist.gdshader") as Shader
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	var image: Image = noise.get_seamless_image(128, 128)
	image.generate_mipmaps()
	_mist_material.set_shader_parameter("noise_tex", ImageTexture.create_from_image(image))
	_mist_material.set_shader_parameter("density", density)
	_mist_material.set_shader_parameter("reach", reach)
	_mist_material.set_shader_parameter("dual", 1.0 if dual else 0.0)
	set_mist_tint(tint)
	_mist_reach = reach
	var quad: QuadMesh = QuadMesh.new()
	quad.size = sheet
	_mist = MultiMesh.new()
	_mist.transform_format = MultiMesh.TRANSFORM_3D
	_mist.mesh = quad
	_mist.instance_count = count
	for i: int in count:
		_mist.set_instance_transform(i, Transform3D(Basis.IDENTITY, _mist_spot(0.0)))
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = "Bruma"
	instance.multimesh = _mist
	instance.material_override = _mist_material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.custom_aabb = AABB(Vector3.ONE * -4096.0, Vector3.ONE * 8192.0)
	add_child(instance)


func set_mist_tint(tint: Color) -> void:
	if _mist_material != null:
		_mist_material.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))


## Punto para un jirón, entre `inner` y el alcance, a media altura sobre el suelo del jugador.
func _mist_spot(inner: float) -> Vector3:
	var at: Vector3 = player.global_position
	var spot: Vector3 = at
	# En niveles cerrados solo vale el aire de un pasillo: dentro de un muro no se vería.
	for attempt: int in 10:
		var angle: float = randf() * TAU
		var distance: float = lerpf(inner, 1.0, sqrt(randf())) * _mist_reach
		spot = Vector3(at.x + cos(angle) * distance, at.y + MIST_RISE, at.z + sin(angle) * distance)
		if not _mist_indoors or _walkable(spot):
			break
	return spot


func _walkable(at: Vector3) -> bool:
	var cell: Vector2i = cell_of(at)
	var width: int = geo.get_meta("grid_width", 0)
	var walkable: PackedByteArray = geo.get_meta("walkable", PackedByteArray())
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y * width + cell.x >= walkable.size():
		return false
	return walkable[cell.y * width + cell.x] == 1


func _update_mist() -> void:
	if _mist == null:
		return
	var at: Vector3 = player.global_position
	for i: int in _mist.instance_count:
		var origin: Vector3 = _mist.get_instance_transform(i).origin
		var away: float = origin.distance_to(at)
		# Tras una reaparición quedan todos lejos: se reparten de nuevo alrededor, no solo al borde.
		if away > _mist_reach * 1.05:
			_mist.set_instance_transform(i, Transform3D(Basis.IDENTITY, _mist_spot(0.85 if away < _mist_reach * 1.6 else 0.0)))


## Mancha de pétalos a ras de suelo (superficie plana). `hidden` = contaminación por revelar.
func add_petals(at: Vector3, size: float, hidden: bool = false) -> MeshInstance3D:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(size, size)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = PETALS_TEXTURE
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission_texture = PETALS_TEXTURE
	material.emission_energy_multiplier = 0.22
	material.roughness = 1.0
	var petals: MeshInstance3D = MeshInstance3D.new()
	petals.mesh = quad
	petals.material_override = material
	petals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(petals)
	_petal_count += 1
	petals.global_position = at + Vector3(0.0, 0.012 + 0.0004 * (_petal_count % 40), 0.0)
	petals.rotation = Vector3(-PI * 0.5, fmod(at.x * 12.9898 + at.z * 78.233, TAU), 0.0)
	petals.visible = not hidden
	return petals


## Carga un recurso de audio que puede faltar (lo produce otra canalización). `null` si no está.
func load_audio(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("Falta el audio %s" % path)
		return null
	return load(path) as AudioStream


func play_sound_at(stream: AudioStream, at: Vector3, volume_db: float = 0.0, max_distance: float = 30.0) -> AudioStreamPlayer3D:
	var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	audio.stream = stream
	audio.volume_db = volume_db
	audio.unit_size = max_distance * 0.25
	audio.max_distance = max_distance
	add_child(audio)
	audio.global_position = at
	audio.play()
	return audio


## Corta de golpe todo el audio del nivel (el cruce de la puerta final, docs/13 §11).
func cut_all_audio() -> void:
	for node: Node in find_children("*", "", true, false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
			node.call("stop")
