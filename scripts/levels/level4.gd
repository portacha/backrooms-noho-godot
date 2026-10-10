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
var _paths: Array[MeshInstance3D] = []
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
var _motes: CPUParticles3D

const MAGENTA: Color = Color(1.0, 0.16, 0.62)
const CANDLE: Color = Color(1.0, 0.55, 0.16)
const ALARM: Color = Color(1.0, 0.03, 0.04)

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
	_door_closed = _model("oak_door_monumental", marker("door"), 0.15)
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
		var candle: Node3D = _model("candle_tall", marker("altar") + Vector3(-1.8 + (i % 2) * 3.6, 0, (i / 2) * 0.3), 0.1, 0.02)
		if candle != null:
			_candles.append(candle)

func _process(delta: float) -> void:
	super(delta)
	if crossing or Game.is_dead or entity == null or altar == null:
		return
	if not chase_started:
		entity.pressure_frozen = true
	update_letter_fx(altar)
	_motes.global_position = player.global_position
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
	for point: Node in geo.get_node("Markers").get_children():
		if not String(point.name).begins_with("path_"):
			continue
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(0.85, 1.95)
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = _path_shader
		material.set_shader_parameter("petals", texture)
		var path: MeshInstance3D = MeshInstance3D.new()
		path.mesh = quad
		path.material_override = material
		path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(path)
		path.global_position = (point as Node3D).global_position + Vector3.UP * 0.03
		path.rotation.x = -PI * 0.5
		_paths.append(path)
	_reveals.resize(_paths.size())


func _update_paths(delta: float) -> void:
	for index: int in _paths.size():
		var path: MeshInstance3D = _paths[index]
		var old: float = _reveals[index]
		var lit: bool = player.flashlight.is_lighting(path.global_position)
		_reveals[index] = move_toward(old, 1.0 if lit else 0.0, delta * (3.0 if lit else 0.12))
		if _reveals[index] != old:
			(path.material_override as ShaderMaterial).set_shader_parameter("reveal", _reveals[index])
		if lit and old < 0.1 and _reveal_cooldown <= 0.0:
			_reveal_cooldown = 2.5
			if _reveal_sound != null:
				play_sound_at(_reveal_sound, path.global_position, -17.0, 10.0)
			Game.caption("[los pétalos resplandecen]", 2.0)


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
	material.albedo_color = Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.42)
	material.albedo_texture = texture
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.disable_fog = true
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(11.0, 7.0)
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.mesh = quad
	halo.material_override = material
	add_child(halo)
	halo.global_position = marker("neon") + Vector3(0.0, -0.3, -0.4)


## Pétalos que suben despacio desde el abismo, alrededor del jugador: dan escala al vacío.
func _build_motes() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.12, 0.09)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.5, 0.12)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = material
	_motes = CPUParticles3D.new()
	_motes.mesh = quad
	_motes.amount = 260
	_motes.lifetime = 14.0
	_motes.preprocess = 14.0
	_motes.local_coords = false
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_motes.emission_box_extents = Vector3(26.0, 9.0, 26.0)
	_motes.direction = Vector3.UP
	_motes.spread = 25.0
	_motes.gravity = Vector3.ZERO
	_motes.initial_velocity_min = 0.15
	_motes.initial_velocity_max = 0.5
	_motes.angular_velocity_min = -60.0
	_motes.angular_velocity_max = 60.0
	_motes.scale_amount_min = 0.6
	_motes.scale_amount_max = 1.8
	add_child(_motes)


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
	environment.fog_light_color = Color(0.11, 0.008, 0.016)
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


func _sound(file: String, volume: float) -> void:
	var stream: AudioStream = load_audio("res://assets/audio/sfx/" + file)
	if stream != null:
		play_sound(stream, volume)

func _optional_loop(path: String, volume: float) -> AudioStreamPlayer:
	var stream: AudioStream = load_audio(path)
	return add_loop(stream, volume) if stream != null else null
