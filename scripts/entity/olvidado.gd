class_name Olvidado
extends CharacterBody3D
## Entidad original; navegación de rejilla y presión desacoplada por señales.
const SURFACE: Shader = preload("res://scripts/entity/olvidado_surface.gdshader")

signal state_changed(state: StringName)
signal screeched
signal relocated(to: Vector3)
signal caught_player
@export var profile: EntityProfile
@export var report_capture: bool = true
var stimulus: float = 0.0:
	set(value):
		stimulus = clampf(value, 0.0, 100.0)
var pressure_frozen: bool = false
var safe_zones: Array[AABB] = []
var hide_zones: Array[AABB] = []
var relocation_points: Array[Vector3] = []
var player: Player
var screen_fx: ScreenFx
var region: NavigationRegion3D
var last_known: Vector3
var has_sight: bool = false
var active: bool = false
var manifested: bool = false
var enraged: bool = false
var ambush_target_distance: float = 16.0
var ambush_min_distance: float = 14.0
var ambush_max_distance: float = 20.0
var ambush_from_light: bool = false
var _gaze: float = 0.0
var _light_contact: bool = false
var _shriek_used: bool = false
var _last_player_position: Vector3
var _anchor: Vector3
var _stagnation: float = 0.0
var _soft_used: bool = false
var _hard_used: bool = false
var _listen_left: float = -1.0
var _phase: float = 0.0
var _step_distance: float = 0.0
var _parts: Dictionary[String, Node3D] = {}
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _clips: Dictionary[StringName, StringName] = {}
var _clip: StringName = &""
var _attack_visual_time: float = 0.0
var _scream_left: float = 0.0
var _clip_speeds: Dictionary = {}
@onready var _petals: CPUParticles3D = $Petals
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sight: RayCast3D = $Sight
@onready var machine: EntityStateMachine = $StateMachine
@onready var model: Node3D = $Model
@onready var steps: AudioStreamPlayer3D = $Steps
@onready var breath: AudioStreamPlayer3D = $Breath
@onready var voice: AudioStreamPlayer3D = $Voice

func setup(player: Player, geo: Node3D, screen_fx: ScreenFx = null) -> void:
	self.player = player
	self.screen_fx = screen_fx
	if profile == null:
		profile = EntityProfile.new()
	if region != null:
		region.queue_free()
	var blocked: Array[AABB] = safe_zones.duplicate()
	for zone: AABB in hide_zones:
		blocked.append(zone.grow(2.0))
	region = EntityNav.build(geo, blocked)
	if not player.footstep.is_connected(_on_footstep):
		player.footstep.connect(_on_footstep)
	sight.add_exception(player)
	if not machine.changed.is_connected(_state_changed):
		machine.changed.connect(_state_changed)
	machine.setup(self)
	_anchor = player.global_position
	_last_player_position = _anchor
	active = true
	if model.get_child_count() == 0 and ResourceLoader.exists("res://assets/models/olvidado.glb"):
		var packed: PackedScene = load("res://assets/models/olvidado.glb") as PackedScene
		model.add_child(packed.instantiate())
		_prepare_model()
	for part: Node in model.find_children("*", "Node3D", true, false):
		_parts[String(part.name)] = part as Node3D
	if not screeched.is_connected(_visual_scream):
		screeched.connect(_visual_scream)
	if profile.starts_hidden:
		vanish()
	else:
		visible = true
	play_audio(breath, "breath_loop.ogg")

func _prepare_model() -> void:
	# La paleta del GLB se conserva en vértices; no suma cinco materiales al nivel.
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SURFACE
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		var textured: BaseMaterial3D = instance.get_active_material(0) as BaseMaterial3D
		if textured != null and textured.albedo_texture != null:
			material.set_shader_parameter("use_texture", true)
			material.set_shader_parameter("albedo_texture", textured.albedo_texture)
			instance.material_override = material
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			continue
		var merged: ArrayMesh = ArrayMesh.new()
		for index: int in instance.mesh.get_surface_count():
			var arrays: Array = instance.mesh.surface_get_arrays(index)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var source: BaseMaterial3D = instance.get_active_material(index) as BaseMaterial3D
			var colors: PackedColorArray = PackedColorArray()
			colors.resize(positions.size())
			colors.fill(source.albedo_color if source != null else Color(0.04, 0.04, 0.04))
			arrays[Mesh.ARRAY_COLOR] = colors
			merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		instance.mesh = merged
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_prepare_animation()

func _prepare_animation() -> void:
	model.rotation.y = PI
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	_animation_player = players[0] as AnimationPlayer
	for name: StringName in _animation_player.get_animation_list():
		var short_name: StringName = StringName(String(name).get_file())
		if short_name in [&"idle", &"walk", &"search", &"run", &"attack", &"scream"]:
			_clips[short_name] = name
			var animation: Animation = _animation_player.get_animation(name)
			animation.loop_mode = Animation.LOOP_LINEAR if short_name in [&"idle", &"walk", &"search", &"run"] else Animation.LOOP_NONE
	# El GLB adaptado ya mira a -Z; el respaldo conserva su giro original.
	if _clips.size() != 6:
		_animation_player = null
		return
	model.rotation = Vector3.ZERO
	if FileAccess.file_exists("res://scripts/entity/olvidado_motion.json"):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/entity/olvidado_motion.json"))
		if data is Dictionary:
			_clip_speeds = data
	var skeletons: Array[Node] = model.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		_skeleton = skeletons[0] as Skeleton3D
		for index: int in _skeleton.get_bone_count():
			if String(_skeleton.get_bone_name(index)).to_lower().ends_with("head"):
				var attachment: BoneAttachment3D = BoneAttachment3D.new()
				attachment.name = "PetalHead"
				_skeleton.add_child(attachment)
				attachment.bone_name = _skeleton.get_bone_name(index)
				_petals.reparent(attachment, false)
				var head_frame: Transform3D = _skeleton.global_transform * _skeleton.get_bone_global_pose(index)
				_petals.position = head_frame.basis.inverse() * global_basis * Vector3(0, 0.12, -0.08)
				_petals.scale = Vector3.ONE / head_frame.basis.get_scale()
				break
	_play_clip(&"idle")

func _play_clip(name: StringName, rate: float = 1.0) -> void:
	if _animation_player == null or not _clips.has(name):
		return
	if _clip != name:
		_clip = name
		_animation_player.play(_clips[name], 0.25)
	_animation_player.speed_scale = rate

func _visual_scream() -> void:
	_scream_left = 0.7
	_play_clip(&"scream")

func _exit_tree() -> void:
	for channel: AudioStreamPlayer3D in [steps, breath, voice]:
		if is_instance_valid(channel):
			channel.stop()
			channel.stream = null
	if is_instance_valid(region):
		region.queue_free()
	if is_instance_valid(player) and player.footstep.is_connected(_on_footstep):
		player.footstep.disconnect(_on_footstep)

func current_state() -> StringName:
	return machine.state

func force_state(state: StringName) -> void:
	if enabled_state(state) and (not pressure_frozen or state == &"Wander"):
		machine.transition(state)

func enabled_state(state: StringName) -> bool:
	match state:
		&"Wander": return true
		&"Investigate": return profile.investigate_enabled
		&"Chase": return profile.chase_enabled
		&"Ambush": return profile.ambush_enabled
		&"Attack": return profile.attack_enabled and not sheltered()
	return false

func manifest_at(at: Vector3, look_at_player: bool = true) -> void:
	teleport_to(at)
	manifested = true
	stimulus = 0.0
	_gaze = 0.0
	_light_contact = false
	force_state(&"Wander")
	if look_at_player and is_instance_valid(player):
		face(player.global_position)

func vanish() -> void:
	active = false
	visible = false
	velocity = Vector3.ZERO
	steps.stop()
	breath.stop()
	voice.stop()
	$CollisionShape3D.set_deferred("disabled", true)
	_petals.emitting = false

func teleport_to(at: Vector3) -> void:
	if forbidden(at):
		return
	global_position = at
	_listen_left = -1.0
	velocity = Vector3.ZERO
	visible = true
	active = true
	manifested = false
	$CollisionShape3D.set_deferred("disabled", false)
	_petals.emitting = true
	agent.target_position = at
	play_audio(breath, "breath_loop.ogg")
	relocated.emit(at)

func set_enraged(on: bool) -> void:
	enraged = on

func speed(state: StringName) -> float:
	var value: float = Game.difficulty.entity_wander_speed
	if state == &"Investigate":
		value = Game.difficulty.entity_investigate_speed
	elif state == &"Chase":
		value = Game.difficulty.entity_chase_speed
	return value * (maxf(profile.speed_scale, 1.15) if enraged else profile.speed_scale)

func radius_scale() -> float:
	return maxf(profile.radius_scale, 1.3) if enraged else profile.radius_scale

func add_stimulus(amount: float, source: Vector3) -> void:
	if not active or pressure_frozen or current_state() == &"Attack":
		return
	stimulus = clampf(stimulus + amount, 0.0, 100.0)
	last_known = source
	manifested = false

func _on_footstep(noise_radius: float) -> void:
	var distance: float = global_position.distance_to(player.global_position)
	var radius: float = noise_radius * radius_scale()
	if radius > 0.0 and distance < radius and not sheltered():
		add_stimulus(lerpf(Game.difficulty.stimulus_noise_max, Game.difficulty.stimulus_noise_min, distance / radius), player.global_position)

func sheltered() -> bool:
	if not is_instance_valid(player):
		return false
	for zone: AABB in safe_zones + hide_zones:
		if zone.has_point(player.global_position + Vector3.UP * 0.5):
			return true
	return false

func forbidden(at: Vector3) -> bool:
	for zone: AABB in safe_zones:
		if zone.grow(0.4).has_point(at + Vector3.UP * 0.5):
			return true
	for zone: AABB in hide_zones:
		if zone.grow(2.0).has_point(at + Vector3.UP * 0.5):
			return true
	return false

func clear_ray(to: Vector3) -> bool:
	sight.target_position = sight.to_local(to)
	sight.force_raycast_update()
	return not sight.is_colliding()

func face(at: Vector3) -> void:
	var offset: Vector3 = at - global_position
	if Vector2(offset.x, offset.z).length_squared() > 0.001:
		rotation.y = atan2(-offset.x, -offset.z)

func move_to(at: Vector3, pace: float, delta: float) -> void:
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	agent.target_position = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), at)
	var next: Vector3 = agent.get_next_path_position()
	var direction: Vector3 = next - global_position
	direction.y = 0.0
	var horizontal: Vector3 = direction.normalized() * pace if not agent.is_navigation_finished() else Vector3.ZERO
	if forbidden(global_position + horizontal * delta):
		horizontal = Vector3.ZERO
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	if horizontal.length_squared() > 0.01:
		face(global_position + horizontal)
		_step_distance += horizontal.length() * delta
		if _step_distance > 0.9:
			_step_distance = 0.0
			play_audio(steps, "bones_step_%02d.wav" % randi_range(1, 4))

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var distance: float = global_position.distance_to(player.global_position) if active else INF
	if player.flashlight.has_method("set_threat"):
		player.flashlight.call("set_threat", distance, active and current_state() == &"Chase")
	else:
		player.flashlight.interference = clampf(1.0 - distance / Game.difficulty.light_flicker_distance, 0.0, 1.0)
	# Ambush sigue su temporizador mientras la entidad está oculta.
	if current_state() == &"Ambush":
		if not pressure_frozen:
			machine.active.physics_update(delta)
		return
	if not active:
		return
	if current_state() == &"Attack":
		machine.active.physics_update(delta)
		animate(delta)
		return
	if pressure_frozen:
		return
	if sheltered():
		_listen(delta)
		return
	_listen_left = -1.0
	var offset: Vector3 = player.camera.global_position - sight.global_position
	has_sight = distance <= 25.0 * radius_scale() and (-global_basis.z).dot(offset.normalized()) >= 0.5 and clear_ray(player.camera.global_position)
	stimulus = maxf(0.0, stimulus - Game.difficulty.stimulus_decay * delta)
	if has_sight and not manifested:
		add_stimulus(Game.difficulty.stimulus_sight_per_second * delta, player.global_position)
	_update_light(delta, distance)
	if current_state() == &"Ambush":
		return
	_update_stagnation(delta)
	if current_state() == &"Ambush":
		return
	if distance < 1.5:
		force_state(&"Attack")
	elif has_sight and stimulus >= Game.difficulty.threshold_chase * Game.chase_threshold_factor():
		force_state(&"Chase")
	elif stimulus >= Game.difficulty.threshold_investigate and current_state() != &"Chase":
		force_state(&"Investigate")
	machine.active.physics_update(delta)
	animate(delta)

func _process(delta: float) -> void:
	if active and machine.active != null and not pressure_frozen:
		machine.active.update(delta)

func _update_light(delta: float, distance: float) -> void:
	var point: Vector3 = global_position + Vector3.UP * 2.25
	var lit: bool = false
	if player.flashlight.has_method("is_lighting"):
		lit = bool(player.flashlight.call("is_lighting", point))
	else:
		var offset: Vector3 = point - player.camera.global_position
		lit = player.flashlight.is_on and offset.length() <= 30.0 and (-player.camera.global_basis.z).dot(offset.normalized()) >= cos(deg_to_rad(14.0))
	lit = lit and clear_ray(player.camera.global_position)
	if lit:
		_gaze += delta
		if profile.light_reaction == EntityProfile.LightReaction.INVESTIGATE and not _light_contact:
			add_stimulus(Game.difficulty.stimulus_light, player.global_position)
		elif profile.light_reaction == EntityProfile.LightReaction.AMBUSH and _gaze >= Game.difficulty.gaze_grace:
			ambush_target_distance = maxf(4.0, distance * (1.0 - Game.difficulty.gaze_approach))
			ambush_from_light = true
			force_state(&"Ambush")
	else:
		_gaze = 0.0
	_light_contact = lit

func _update_stagnation(delta: float) -> void:
	if not profile.stagnation_ambush:
		return
	var moved: bool = player.global_position.distance_to(_last_player_position) > 0.02
	_last_player_position = player.global_position
	if moved or player.velocity.length() > 0.1 or player.global_position.distance_to(_anchor) > 3.0:
		_anchor = player.global_position
		_stagnation = 0.0
		_soft_used = false
		_hard_used = false
		return
	_stagnation += delta
	if _stagnation >= Game.difficulty.ambush_hard_seconds and not _hard_used:
		_hard_used = true
		ambush_min_distance = 8.0
		ambush_max_distance = 12.0
		ambush_target_distance = randf_range(ambush_min_distance, ambush_max_distance)
	elif _stagnation >= Game.difficulty.ambush_soft_seconds and not _soft_used:
		_soft_used = true
		ambush_min_distance = 14.0
		ambush_max_distance = 20.0
		ambush_target_distance = randf_range(ambush_min_distance, ambush_max_distance)
	else:
		return
	ambush_from_light = false
	force_state(&"Ambush")

func _listen(delta: float) -> void:
	has_sight = false
	if current_state() != &"Wander":
		machine.transition(&"Wander")
	if _listen_left < 0.0:
		_listen_left = randf_range(6.0, 10.0)
		machine.transition(&"Wander")
		play_audio(breath, "listen_breath_loop.ogg")
	_listen_left = maxf(0.0, _listen_left - delta)
	if _listen_left > 0.0:
		move_to(player.global_position, speed(&"Wander"), delta)
	else:
		stimulus = 0.0
		velocity = Vector3.ZERO
		machine.active.physics_update(delta)

func relocation_candidate() -> Vector3:
	var candidates: Array[Vector3] = relocation_points.duplicate()
	var centres: PackedVector3Array = region.get_meta("centres", PackedVector3Array())
	if candidates.is_empty():
		for point: Vector3 in centres:
			candidates.append(region.to_global(point))
	var best: Vector3 = Vector3.INF
	var score: float = INF
	for point: Vector3 in candidates:
		var distance: float = point.distance_to(player.global_position)
		if distance < 4.0 or forbidden(point) or player.camera.is_position_in_frustum(point + Vector3.UP * 1.3):
			continue
		if not ambush_from_light and (distance < ambush_min_distance or distance > ambush_max_distance):
			continue
		if ambush_from_light and distance >= global_position.distance_to(player.global_position):
			continue
		var projected: Vector3 = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), point)
		if projected.distance_to(point) > 0.5:
			continue
		var error: float = absf(distance - ambush_target_distance)
		if error < score:
			score = error
			best = projected
	if best == Vector3.INF and not relocation_points.is_empty():
		var saved: Array[Vector3] = relocation_points
		relocation_points = []
		best = relocation_candidate()
		relocation_points = saved
	return best

func play_audio(channel: AudioStreamPlayer3D, file: String) -> void:
	var path: String = "res://assets/audio/entity/" + file
	if ResourceLoader.exists(path):
		channel.stream = load(path) as AudioStream
		channel.play()

func _state_changed(state: StringName) -> void:
	_attack_visual_time = 0.0
	state_changed.emit(state)
	match state:
		&"Wander": Game.caption("[huesos secos — lejos]")
		&"Investigate": Game.caption("[huesos secos — cerca]")
		&"Chase":
			Game.caption("[pasos acelerados — detrás]")
			play_audio(voice, "chase_loop.ogg")
		&"Ambush": Game.caption("[papel que roza el suelo]")
	if state not in [&"Chase", &"Attack", &"Ambush"]:
		voice.stop()

func animate(delta: float) -> void:
	if _animation_player != null:
		var pace: float = Vector2(velocity.x, velocity.z).length()
		var name: StringName = &"idle"
		var rate: float = 1.0
		if current_state() == &"Attack":
			_attack_visual_time += delta
			name = &"attack" if _attack_visual_time < 0.75 else &"scream"
			rate = _animation_player.get_animation(_clips[name]).length / 0.75
		elif _scream_left > 0.0:
			_scream_left -= delta
			name = &"scream"
		elif current_state() == &"Investigate":
			name = &"search"
		elif pace > 0.05 and not manifested:
			name = &"run" if current_state() == &"Chase" else &"walk"
		if name in [&"walk", &"run", &"search"]:
			# Metros por segundo del clip, medidos en la adaptación, no dificultad.
			var native_pace: float = float(_clip_speeds.get(String(name), 1.0))
			rate = pace / maxf(native_pace, 0.01)
			if name == &"search" and pace < 0.05:
				rate = 0.35
		_play_clip(name, rate)
		return
	_phase += delta * maxf(velocity.length(), 0.3) * 2.0
	for key: String in ["ArmUpper_L", "ArmUpper_R", "LegUpper_L", "LegUpper_R"]:
		if _parts.has(key):
			var sign_value: float = -1.0 if key.ends_with("_R") else 1.0
			_parts[key].rotation.x = sin(_phase) * 0.18 * sign_value
	if _parts.has("Head"):
		_parts["Head"].rotation.z = sin(_phase * 7.3) * (0.07 if current_state() == &"Investigate" else 0.01)
	if current_state() == &"Attack":
		model.rotation.x = -0.24
