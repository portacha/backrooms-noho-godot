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
var _shared: ShaderMaterial
var _reveals: PackedFloat32Array = PackedFloat32Array()

func _ready() -> void:
	super()
	if geo == null or not geo.has_node("Markers"):
		set_process(false)
		push_error("Nivel 4 requiere reconstruir su geometría.")
		return
	_shared = ShaderMaterial.new()
	_shared.shader = load("res://shaders/petal_path.gdshader") as Shader
	if ResourceLoader.exists("res://assets/textures/petals_path.png"):
		_shared.set_shader_parameter("petals", load("res://assets/textures/petals_path.png"))
	_reveals.resize(128)
	_shared.set_shader_parameter("path_reveals", _reveals)
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
	# El neón ya es emisivo; prescindir del halo evita un séptimo material.
	for child: Node in altar.get_children():
		if child is MeshInstance3D:
			child.queue_free()
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
	_model("neon_noho_sign", marker("neon"), 0.15, 2.5, PI, true)
	_fix_neon_order()
	for at: Vector3 in [Vector3(58.8, 0, 70), Vector3(63.2, 0, 70), Vector3(61.7, 0, 85), Vector3(60.3, 0, 113), Vector3(63, 0, 143)]:
		var beacon: Node3D = _model("emergency_beacon", at, 0.08, 0.0)
		if beacon != null:
			_beacons.append(beacon)
	for i: int in 10:
		var candle: Node3D = _model("candle_tall", marker("altar") + Vector3(-1.8 + (i % 2) * 3.6, 0, (i / 2) * 0.3), 0.1, 0.0)
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
	for point: Node in geo.get_node("Markers").get_children():
		if not String(point.name).begins_with("path_"):
			continue
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(0.85, 1.95)
		var arrays: Array = quad.surface_get_arrays(0)
		var codes: PackedVector2Array = PackedVector2Array()
		for i: int in 4:
			codes.append(Vector2(0, _paths.size()))
		arrays[Mesh.ARRAY_TEX_UV2] = codes
		var mesh: ArrayMesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var path: MeshInstance3D = MeshInstance3D.new()
		path.mesh = mesh
		path.material_override = _shared
		path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(path)
		path.global_position = (point as Node3D).global_position + Vector3.UP * 0.025
		path.rotation.x = -PI * 0.5
		_paths.append(path)

func _update_paths(delta: float) -> void:
	for index: int in _paths.size():
		var path: MeshInstance3D = _paths[index]
		var old: float = _reveals[index]
		var lit: bool = player.flashlight.is_lighting(path.global_position)
		_reveals[index] = move_toward(old, 1.0 if lit else 0.0, delta * (3.0 if lit else 0.12))
		if lit and old < 0.1 and _reveal_cooldown <= 0.0:
			_reveal_cooldown = 2.5
			if _reveal_sound != null:
				play_sound_at(_reveal_sound, path.global_position, -17.0, 10.0)
			Game.caption("[los pétalos resplandecen]", 2.0)
	_shared.set_shader_parameter("path_reveals", _reveals)

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
		create_tween().tween_callback(_ignite.bind(_candles[i], Color(1, 0.5, 0.12), 2.5)).set_delay(i * 0.09)

func _break_world() -> void:
	entity.vanish()
	_shared.set_shader_parameter("emergency", 1.0)
	var environment: Environment = ($WorldEnvironment as WorldEnvironment).environment
	environment.fog_light_color = Color(0.09, 0.008, 0.015)
	screen_fx.distortion = 0.35
	create_tween().tween_property(screen_fx, "distortion", 0.0, 1.6)
	create_tween().tween_method(shake, 1.0, 0.0, 1.2)
	for beacon: Node3D in _beacons:
		_ignite(beacon, Color(1, 0.005, 0.015), 3.0)
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

func _model(model: String, at: Vector3, glow: float, special_glow: float = 2.5, yaw: float = PI, mirror_x: bool = false) -> Node3D:
	if not ResourceLoader.exists("res://assets/models/%s.glb" % model):
		return null
	var result: Node3D = spawn_model(model, self, glow, special_glow)
	result.global_position = at
	result.rotation.y = yaw
	# El tubo del neón solo tiene frontal por una cara: al verlo por detrás
	# (lado de llegada) hay que espejarlo para que NOHO se lea al derecho.
	if mirror_x:
		result.scale.x = -result.scale.x
	return result

func _ignite(model_node: Node3D, _color: Color, _energy: float) -> void:
	if model_node.has_meta("candle_index"):
		_shared.set_shader_parameter("candles", float(model_node.get_meta("candle_index")) + 1.0)

## El tubo del neón llega con el orden al revés visto desde la llegada
## (OHON): reubica cada tubo al otro lado del centro, sin deformarlos,
## para que desde el puente se lea NOHO con las letras intactas.
func _fix_neon_order() -> void:
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		var mesh: ArrayMesh = instance.mesh as ArrayMesh
		if mesh == null or mesh.get_surface_count() < 1:
			continue
		var raw_codes: Variant = mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]
		if not (raw_codes is PackedVector2Array):
			continue
		var codes: PackedVector2Array = raw_codes
		if codes.is_empty() or absf(codes[0].x - 4.0) > 0.1:
			continue
		var total: int = 0
		var center: Vector3 = Vector3.ZERO
		for surface: int in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			for v: Vector3 in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				center += v
				total += 1
		if total == 0:
			continue
		center /= float(total)
		var in_level: Vector3 = to_local(instance.to_global(center))
		instance.global_position += global_transform.basis * Vector3(-2.0 * in_level.x, 0.0, 0.0)
func spawn_model(model: String, parent: Node3D, glow: float = 0.35, special_glow: float = 2.5) -> Node3D:
	var resource: String = "res://assets/models/%s.glb" % model
	if not ResourceLoader.exists(resource):
		return null
	var root: Node3D = (load(resource) as PackedScene).instantiate() as Node3D
	parent.add_child(root)
	if model.begins_with("candle_"):
		root.set_meta("candle_index", _candles.size())
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		var merged: ArrayMesh = ArrayMesh.new()
		for surface: int in instance.mesh.get_surface_count():
			var source: BaseMaterial3D = instance.get_active_material(surface) as BaseMaterial3D
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var colors: PackedColorArray = PackedColorArray()
			var codes: PackedVector2Array = PackedVector2Array()
			var color: Color = source.albedo_color if source != null else Color.WHITE
			var kind: float = 1.0
			var energy: float = glow
			if source != null and source.resource_name in ["Flame", "Glow"]:
				kind = 2.0 if source.resource_name == "Flame" else 3.0
				energy = float(_candles.size()) if kind == 2.0 else special_glow
				if model == "neon_noho_sign":
					kind = 4.0
					color = Color(1, 0.02, 0.45)
					energy = 5.0
			if model == "letter_o":
				kind = 5.0
				color = Color(1, 0.65, 0.8)
				energy = 2.6
			for i: int in vertices.size():
				colors.append(color)
				codes.append(Vector2(kind, energy))
			arrays[Mesh.ARRAY_COLOR] = colors
			arrays[Mesh.ARRAY_TEX_UV2] = codes
			merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		instance.mesh = merged
		instance.material_override = _shared
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

func _sound(file: String, volume: float) -> void:
	var stream: AudioStream = load_audio("res://assets/audio/sfx/" + file)
	if stream != null:
		play_sound(stream, volume)

func _optional_loop(path: String, volume: float) -> AudioStreamPlayer:
	var stream: AudioStream = load_audio(path)
	return add_loop(stream, volume) if stream != null else null
