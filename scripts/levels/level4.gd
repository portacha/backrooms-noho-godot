extends LevelBase
## Nivel 4: la luz descubre el camino; la última O desata la huida.

signal bridge_reset(id: int)
signal distant_presence
signal final_chase_started
signal door_crossed

var altar: LetterAltar
var chase_started: bool = false
var crossing: bool = false
var current_bridge: int = 0
var presence_seen: bool = false
var _falling: bool = false
## Sendero de pétalos: una cinta por cadena de puentes. `_trail_points` son sus muestras (una
## cada TRAIL_STEP) y `_reveals` cuánto recuerda cada una haber sido alumbrada.
var _trails: Array[Dictionary] = []
var _trail_points: PackedVector3Array = PackedVector3Array()
var _reveal_sound: AudioStream
var _reveal_cooldown: float = 0.0
var _door_closed: Node3D
var _door_open: Node3D
var _beacons: Array[Node3D] = []
var _alarm: AudioStreamPlayer
var _candles: Array[Node3D] = []
var _emergency_time: float = 0.0
var _path_shader: Shader
var _reveals: PackedFloat32Array = PackedFloat32Array()

const MAGENTA: Color = Color(1.0, 0.16, 0.62)
const CANDLE: Color = Color(1.0, 0.55, 0.16)
const ALARM: Color = Color(1.0, 0.03, 0.04)
const FOG_COLOR: Color = Color(0.07, 0.026, 0.06)
const TRAIL_STEP: float = 0.5
const TRAIL_CORNER: float = 0.7

func _ready() -> void:
	super()
	if geo == null or not geo.has_node("Markers"):
		set_process(false)
		push_error("Nivel 4 requiere reconstruir su geometría.")
		return
	# El vacío se mira lejos: el neón de la puerta se ve desde el altar, a 75 m.
	player.camera.far = 260.0
	_path_shader = load("res://shaders/petal_path.gdshader") as Shader
	player.flashlight.available = true
	player.sprint_enabled = true
	# Todo el nivel es la dimensión oscura: la bruma no depende de `reality`.
	# Niebla de profundidad, color vino (concept/art/04): la isla siguiente y los islotes con su
	# luz se adivinan a 30–50 m y se pierden más allá; el neón no la sufre y sigue guiando.
	var environment: Environment = ($WorldEnvironment as WorldEnvironment).environment
	environment.fog_light_color = FOG_COLOR
	environment.fog_density = 0.03
	# El cielo se hunde en la misma niebla: las islas lejanas no se recortan más claras que el fondo.
	environment.fog_sky_affect = 0.85
	var sky: ProceduralSkyMaterial = environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_horizon_color = Color(0.1, 0.022, 0.06)
	sky.ground_horizon_color = Color(0.1, 0.022, 0.06)
	add_mist(Color(0.13, 0.06, 0.13), 0.4, 28, 18.0, false, false, Vector2(11.0, 3.6))
	var checkpoint: String = spawn_at_checkpoint("start", PI)
	current_bridge = {"r1": 2, "altar": 3}.get(checkpoint, 0)
	presence_seen = checkpoint == "altar"
	if checkpoint.is_empty() or checkpoint == "start":
		add_checkpoint("start", "cp_start")
		add_checkpoint("r1", "cp_r1")
	if checkpoint != "altar":
		add_checkpoint("altar", "cp_altar", 2.0)
	spawn_entity("res://resources/entity/profile_level4.tres")
	entity.pressure_frozen = true
	# Ni lectura ni ruido liberan una persecución antes de la O.
	entity.profile.chase_enabled = false
	entity.profile.ambush_enabled = false
	entity.profile.stagnation_ambush = false
	for id: String in ["d13", "d14", "d15"]:
		var path: String = "res://resources/documents/%s.tres" % id
		if ResourceLoader.exists(path):
			add_document(marker(id), path, 2.2)
	altar = add_letter("letter_o", "letter", PI)
	altar.taken.connect(_take_letter)
	_build_paths()
	_reveal_sound = load_audio("res://assets/audio/sfx/petal_reveal.wav")
	_optional_loop("res://assets/audio/ambient/level4_abyss_loop.ogg", -11.0)
	var buzz: AudioStream = load_audio("res://assets/audio/ambient/neon_buzz_loop.ogg")
	if buzz != null:
		play_sound_at(buzz, marker("neon"), -14.0, 18.0)
	_door_closed = _hero_model("oak_door_monumental", marker("door"))
	_door_open = _model("oak_door_open", marker("door"), 0.15)
	if _door_open != null:
		_door_open.visible = false
	_build_neon()
	_build_motes()
	for at: Vector3 in [Vector3(58.8, 0, 70), Vector3(63.2, 0, 70), Vector3(61.7, 0, 85), Vector3(60.3, 0, 113), Vector3(63, 0, 143)]:
		var beacon: Node3D = _model("emergency_beacon", at, 0.08, 0.02)
		if beacon != null:
			_beacons.append(beacon)
	for i: int in 10:
		var candle: Node3D = _model("candle_tall", marker("altar") + Vector3(-1.3 + (i % 2) * 2.6, 0, -1.2 + (i / 2) * 0.9), 0.1, 0.02)
		if candle != null:
			_candles.append(candle)

func _process(delta: float) -> void:
	super(delta)
	if crossing or Game.is_dead or entity == null or altar == null:
		return
	if not chase_started:
		entity.pressure_frozen = true
	update_letter_fx(altar)
	_reveal_cooldown = maxf(0.0, _reveal_cooldown - delta)
	_update_paths(delta)
	if not _falling and player.global_position.y < -6.0:
		_reset_bridge()
	if not _falling:
		for id: int in 4:
			if player.global_position.distance_to(marker("bridge_%d" % id)) < 1.8:
				current_bridge = id
	if not presence_seen and not altar.is_taken and player.global_position.distance_to(marker("presence_trigger")) < 4.0:
		_show_presence()
	if chase_started:
		_emergency_time += delta
		set_world_light(0.5 + 0.1 * sin(_emergency_time * 8.0))
		if not _falling and player.global_position.distance_to(marker("door")) < 1.1:
			_cross_door()

func _build_paths() -> void:
	var texture: Texture2D = load("res://assets/textures/petals_path.png") as Texture2D
	var trail: int = 0
	while has_marker("trail_%d_0" % trail):
		var corners: PackedVector3Array = PackedVector3Array()
		while has_marker("trail_%d_%d" % [trail, corners.size()]):
			corners.append(marker("trail_%d_%d" % [trail, corners.size()]))
		_add_trail(_resample(_round_corners(corners)), texture, trail)
		trail += 1
	_reveals.resize(_trail_points.size())


## Las esquinas del puente se vuelven curvas: el sendero dobla, no se quiebra.
func _round_corners(corners: PackedVector3Array) -> PackedVector3Array:
	var line: PackedVector3Array = PackedVector3Array([corners[0]])
	for index: int in range(1, corners.size() - 1):
		var corner: Vector3 = corners[index]
		var from: Vector3 = corner + (corners[index - 1] - corner).limit_length(TRAIL_CORNER)
		var to: Vector3 = corner + (corners[index + 1] - corner).limit_length(TRAIL_CORNER)
		for step: int in 7:
			var t: float = step / 6.0
			line.append(from.lerp(corner, t).lerp(corner.lerp(to, t), t))
	line.append(corners[corners.size() - 1])
	return line


## Muestras equidistantes (TRAIL_STEP) a lo largo de una polilínea.
func _resample(line: PackedVector3Array) -> PackedVector3Array:
	var samples: PackedVector3Array = PackedVector3Array([line[0]])
	var pending: float = TRAIL_STEP
	for index: int in range(1, line.size()):
		var from: Vector3 = line[index - 1]
		var length: float = from.distance_to(line[index])
		var walked: float = 0.0
		while length - walked >= pending:
			walked += pending
			pending = TRAIL_STEP
			samples.append(from.lerp(line[index], walked / length))
		pending -= length - walked
	return samples


## Cinta de pétalos sobre una polilínea: serpentea y cambia de ancho como algo que se derramó a
## mano, sin salirse del puente (2 m de ancho).
func _add_trail(line: PackedVector3Array, texture: Texture2D, seed: int) -> void:
	var count: int = line.size()
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var uv2s: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for index: int in count:
		var tangent: Vector3 = (line[mini(index + 1, count - 1)] - line[maxi(index - 1, 0)]).normalized()
		var side: Vector3 = tangent.cross(Vector3.UP)
		var along: float = index * TRAIL_STEP
		var centre: Vector3 = line[index] + side * (0.2 * sin(along * 0.5 + seed * 1.9) + 0.08 * sin(along * 1.63 + seed)) + Vector3.UP * 0.03
		var half: float = 0.52 + 0.14 * sin(along * 0.83 + seed * 2.7)
		_trail_points.append(centre)
		for edge: int in 2:
			vertices.append(centre + side * half * (edge * 2.0 - 1.0))
			normals.append(Vector3.UP)
			uvs.append(Vector2(edge, along / 1.95))
			uv2s.append(Vector2((index + 0.5) / count, 0.0))
		if index > 0:
			var base: int = index * 2
			indices.append_array(PackedInt32Array([base - 2, base, base - 1, base - 1, base, base + 1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var image: Image = Image.create(count, 1, false, Image.FORMAT_R8)
	var memory: ImageTexture = ImageTexture.create_from_image(image)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = _path_shader
	material.set_shader_parameter("petals", texture)
	material.set_shader_parameter("reveal_tex", memory)
	var ribbon: MeshInstance3D = MeshInstance3D.new()
	ribbon.name = "Sendero%d" % seed
	ribbon.mesh = mesh
	ribbon.material_override = material
	ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ribbon)
	_trails.append({"first": _trail_points.size() - count, "count": count, "image": image, "memory": memory, "material": material})


func _update_paths(delta: float) -> void:
	var beam: Flashlight = player.flashlight
	var beam_on: bool = beam.is_lighting(beam.global_position)
	for trail: Dictionary in _trails:
		var material: ShaderMaterial = trail["material"]
		material.set_shader_parameter("beam_on", 1.0 if beam_on else 0.0)
		if beam_on:
			material.set_shader_parameter("beam_origin", beam.global_position)
			material.set_shader_parameter("beam_direction", -beam.global_transform.basis.z)
			material.set_shader_parameter("beam_cos", cos(deg_to_rad(beam.cone_half_angle_degrees)))
			material.set_shader_parameter("beam_range", beam.lighting_range)
		var image: Image = trail["image"]
		var first: int = trail["first"]
		var changed: bool = false
		for offset: int in int(trail["count"]):
			var index: int = first + offset
			var old: float = _reveals[index]
			if not beam_on and old <= 0.0:
				continue
			var lit: bool = beam_on and beam.is_lighting(_trail_points[index])
			_reveals[index] = move_toward(old, 1.0 if lit else 0.0, delta * (3.0 if lit else 0.12))
			if _reveals[index] != old:
				changed = true
				image.set_pixel(offset, 0, Color(_reveals[index], 0.0, 0.0))
			if lit and old < 0.1 and _reveal_cooldown <= 0.0:
				_reveal_cooldown = 2.5
				if _reveal_sound != null:
					play_sound_at(_reveal_sound, _trail_points[index], -17.0, 10.0)
				Game.caption("[los pétalos resplandecen]", 2.0)
		if changed:
			(trail["memory"] as ImageTexture).update(image)


## El neón de la puerta: lo único que atraviesa toda la niebla (docs/13 §11). Ni él ni su halo
## reciben niebla; el halo es resplandor (disco aditivo), no un objeto.
func _build_neon() -> void:
	var sign: Node3D = _model("neon_noho_sign", marker("neon"), 0.1, 4.0, PI)
	if sign == null:
		return
	_set_glow(sign, MAGENTA, 4.0, true)
	# El trazo diagonal de la N viene invertido en el modelo: se voltea sobre su propio centro.
	var diagonal: MeshInstance3D = sign.find_child("*002*", true, false) as MeshInstance3D
	if diagonal != null:
		var centre: float = diagonal.get_aabb().get_center().x
		diagonal.scale.x = -1.0
		diagonal.position.x += 2.0 * centre
		for surface: int in diagonal.mesh.get_surface_count():
			(diagonal.get_surface_override_material(surface) as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_halo(marker("neon") + Vector3(0.0, -0.3, -0.4), Vector2(11.0, 7.0), Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.42))
	# El resplandor rojo que envuelve la puerta en el concept: se ve desde el altar, a 75 m.
	_add_halo(marker("neon") + Vector3(0.0, 0.5, 3.0), Vector2(64.0, 40.0), Color(1.0, 0.06, 0.1, 0.2))


## Resplandor: disco aditivo que mira a cámara y no recibe niebla.
func _add_halo(at: Vector3, size: Vector2, color: Color) -> void:
	var falloff: Gradient = Gradient.new()
	falloff.set_color(0, Color.WHITE)
	falloff.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = falloff
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = color
	material.albedo_texture = texture
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.disable_fog = true
	var quad: QuadMesh = QuadMesh.new()
	quad.size = size
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.mesh = quad
	halo.material_override = material
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	halo.global_position = at


## Pétalos de cempasúchil que suben despacio desde el abismo: dan escala al vacío. Cada uno es
## una hoja con forma y pliegue que gira sobre sí misma (`shaders/petal_drift.gdshader`).
func _build_motes() -> void:
	var extent: Vector3 = Vector3(24.0, 10.0, 24.0)
	# Pétalo: base estrecha, vientre ancho y punta mellada, doblado por su nervio.
	var outline: PackedVector3Array = PackedVector3Array([
		Vector3(0.0, 0.0, 0.0), Vector3(-0.03, 0.045, 0.012), Vector3(-0.022, 0.1, 0.006), Vector3(0.0, 0.088, -0.004),
		Vector3(0.022, 0.1, 0.006), Vector3(0.03, 0.045, 0.012), Vector3(0.0, 0.05, -0.012)])
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	for index: int in 6:
		var corners: Array[Vector3] = [outline[6], outline[index], outline[(index + 1) % 6]]
		var normal: Vector3 = (corners[1] - corners[0]).cross(corners[2] - corners[0]).normalized()
		for corner: Vector3 in corners:
			vertices.append(corner - Vector3(0.0, 0.05, 0.0))
			normals.append(normal)
			uvs.append(Vector2(0.5, corner.y / 0.1))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var petal: ArrayMesh = ArrayMesh.new()
	petal.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/petal_drift.gdshader") as Shader
	material.set_shader_parameter("extent", extent)
	var cloud: MultiMesh = MultiMesh.new()
	cloud.transform_format = MultiMesh.TRANSFORM_3D
	cloud.use_custom_data = true
	cloud.mesh = petal
	cloud.instance_count = 340
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4104
	for index: int in cloud.instance_count:
		var home: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * extent
		cloud.set_instance_transform(index, Transform3D(Basis.IDENTITY, home))
		cloud.set_instance_custom_data(index, Color(rng.randf(), rng.randf(), rng.randf(), rng.randf()))
	var motes: MultiMeshInstance3D = MultiMeshInstance3D.new()
	motes.name = "Petalos"
	motes.multimesh = cloud
	motes.material_override = material
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# La nube sigue a la cámara en el shader: nunca debe descartarse por su caja.
	motes.custom_aabb = AABB(Vector3.ONE * -4096.0, Vector3.ONE * 8192.0)
	add_child(motes)


## Cambia el brillo de las superficies especiales (`Glow`, `Flame`) de un modelo dinámico.
func _set_glow(root: Node3D, color: Color, energy: float, no_fog: bool = false) -> void:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		for surface: int in instance.mesh.get_surface_count():
			var source: Material = instance.mesh.surface_get_material(surface)
			var material: StandardMaterial3D = instance.get_surface_override_material(surface) as StandardMaterial3D
			if source == null or material == null or source.resource_name not in ["Glow", "Flame", "Screen"]:
				continue
			material.emission = color
			material.emission_energy_multiplier = energy
			material.disable_fog = no_fog


func _reset_bridge() -> void:
	_falling = true
	player.controls_enabled = false
	screen_fx.fade_color = Color.BLACK
	await screen_fx.fade_to(1.0, 0.12).finished
	_sound("fall_sting.ogg", -6.0)
	Game.caption("[caída al vacío]", 2.0)
	var start: Vector3 = marker("bridge_%d" % current_bridge)
	var look: Vector3 = marker("bridge_%d_look" % current_bridge) - start
	player.respawn_at(start, atan2(-look.x, -look.z))
	entity.add_stimulus(Game.difficulty.fall_stimulus, start)
	# Reubicar detrás mantiene la ventaja del sprint tras una caída, sin matar por caer.
	if chase_started:
		entity.vanish()
		begin_final_chase(marker("chase_from"), marker("door"))
	bridge_reset.emit(current_bridge)
	await screen_fx.fade_to(0.0, 0.18).finished
	player.controls_enabled = true
	_falling = false

func _show_presence() -> void:
	presence_seen = true
	entity.manifest_at(marker("presence"))
	distant_presence.emit()
	await get_tree().create_timer(2.5).timeout
	if not chase_started:
		entity.vanish()

func _take_letter() -> void:
	# El altar no gasta otro temblor: el único es la ruptura que sigue.
	play_letter_ritual(altar, _break_world, _start_chase, false)
	for i: int in _candles.size():
		create_tween().tween_callback(_set_glow.bind(_candles[i], CANDLE, 3.0)).set_delay(i * 0.09)

func _break_world() -> void:
	entity.vanish()
	var environment: Environment = ($WorldEnvironment as WorldEnvironment).environment
	environment.fog_light_color = Color(0.13, 0.008, 0.016)
	set_mist_tint(Color(0.3, 0.03, 0.05))
	var sky: ProceduralSkyMaterial = environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_horizon_color = Color(0.3, 0.012, 0.03)
	sky.ground_horizon_color = Color(0.3, 0.012, 0.03)
	screen_fx.distortion = 0.35
	create_tween().tween_property(screen_fx, "distortion", 0.0, 1.6)
	create_tween().tween_method(shake, 1.0, 0.0, 1.2)
	for beacon: Node3D in _beacons:
		_set_glow(beacon, ALARM, 4.0)
	_alarm = _optional_loop("res://assets/audio/ambient/alarm_red_loop.ogg", -4.0)
	Game.caption("[alarma; el vacío cruje]", 4.0)

func _start_chase() -> void:
	chase_started = true
	current_bridge = 3
	# Altar a la espalda; objetivo único al frente, sin giro obligatorio al ganar control.
	player.set_view(PI, 0.0)
	entity.profile.chase_enabled = true
	entity.pressure_frozen = false
	entity.set_enraged(true)
	begin_final_chase(marker("chase_from"), marker("door"))
	final_chase_started.emit()
	await get_tree().create_timer(3.0).timeout
	if not crossing and not Game.is_dead:
		player.flashlight.kill()
		Game.caption("[la linterna muere]", 2.0)

func _cross_door() -> void:
	crossing = true
	set_can_pause(false)
	player.controls_enabled = false
	entity.vanish()
	if _door_closed != null:
		_door_closed.visible = false
	if _door_open != null:
		_door_open.visible = true
	_sound("door_oak_open.ogg", -2.0)
	await get_tree().create_timer(0.25).timeout
	# Inmoviliza también la respiración y la FSM para que no reinicien audio en el negro.
	player.process_mode = Node.PROCESS_MODE_DISABLED
	entity.process_mode = Node.PROCESS_MODE_DISABLED
	cut_all_audio()
	for node: Node in get_tree().root.find_children("*", "", true, false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D:
			node.call("stop")
	screen_fx.fade_color = Color.BLACK
	screen_fx.fade = 1.0
	door_crossed.emit()
	await get_tree().create_timer(0.5).timeout
	finish_level(Color.BLACK, 0.0)

func _model(model: String, at: Vector3, glow: float, special_glow: float = 2.5, yaw: float = PI) -> Node3D:
	if not ResourceLoader.exists("res://assets/models/%s.glb" % model):
		return null
	var result: Node3D = spawn_model(model, self, glow, special_glow)
	result.global_position = at
	result.rotation.y = yaw
	return result


## Modelo texturizado (`assets/models/hero/`) con la luz horneada del nivel; si no existe, el plano.
func _hero_model(model: String, at: Vector3) -> Node3D:
	var path: String = "res://assets/models/hero/%s.glb" % model
	if not ResourceLoader.exists(path):
		return _model(model, at, 0.15)
	var instance: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	add_child(instance)
	instance.global_position = at
	instance.rotation.y = PI
	light_hero(instance, geo.get_meta("lights", []), geo.get_meta("flicker_color", Color(1.0, 0.93, 0.7)), false)
	return instance


func _sound(file: String, volume: float) -> void:
	var stream: AudioStream = load_audio("res://assets/audio/sfx/" + file)
	if stream != null:
		play_sound(stream, volume)

func _optional_loop(path: String, volume: float) -> AudioStreamPlayer:
	var stream: AudioStream = load_audio(path)
	return add_loop(stream, volume) if stream != null else null
