extends LevelBase
## Nivel 2 — Las Ofrendas Infinitas. La luz guía y también obliga a apartar la mirada.

const PROFILE: String = "res://resources/entity/profile_level2.tres"
const HALL_AUDIO: String = "res://assets/audio/ambient/level2_hall_loop.ogg"
const COPAL_AUDIO: String = "res://assets/audio/ambient/copal_crackle_loop.ogg"
const COLLAPSE_AUDIO: String = "res://assets/audio/sfx/ofrenda_collapse.ogg"

var _altar: LetterAltar
var _entity: Olvidado
var _active_manifestation: bool = false
var _manifestation_time: float = 0.0
var _manifestation_origin: Vector3 = Vector3.ZERO
var _manifestations: int = 0
var _budget: int = 3
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _mutation_timer: float = 0.0
var _mutations: int = 0
var _mutation_models: Array[Node3D] = []
var _mutation_slots: Array[Vector3] = []
var _ritual: bool = false
var _mutation_busy: bool = false
var _d07_done: bool = false
var _d08_done: bool = false
var _d09_done: bool = false
var _hall: AudioStreamPlayer
var _copal: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	super()
	_rng.randomize()
	_budget = Game.difficulty.level2_manifestations
	var checkpoint: String = spawn_at_checkpoint("start", PI)
	player.flashlight.available = true
	player.sprint_enabled = true
	_build_concrete_steps()
	set_touch_button(&"flashlight_visible", true)
	set_touch_button(&"sprint_visible", true)
	var hall_stream: AudioStream = load_audio(HALL_AUDIO)
	if hall_stream != null:
		_hall = add_loop(hall_stream, -7.0)
	_build_documents()
	_build_offerings_audio()
	_build_mutations()
	_altar = add_letter("letter_o", "letter", PI, 4.5)
	_altar.taken.connect(_on_letter_taken)
	add_checkpoint("start", "cp_start", 2.0)
	add_checkpoint("r1", "cp_r1", 2.2)
	add_checkpoint("r2", "cp_r2", 2.2)
	_entity = spawn_entity(PROFILE)
	_entity.profile.attack_enabled = false
	_entity.screeched.connect(_on_screeched)
	_entity.relocated.connect(_on_relocated)
	if checkpoint == "r1":
		_d07_done = true
	elif checkpoint == "r2":
		_d07_done = true
		_d08_done = true
		_d09_done = true
		_altar.is_taken = false
		_altar.spot.enabled = true

func _process(delta: float) -> void:
	super(delta)
	if _altar != null:
		update_letter_fx(_altar)
	if _ritual:
		return
	_update_reading_state()
	_update_manifestation(delta)
	_update_mutations(delta)
	_update_events()

func _build_concrete_steps() -> void:
	var steps: Array[AudioStream] = []
	for index: int in 6:
		var path: String = "res://assets/audio/sfx/footstep_concrete_%02d.wav" % (index + 1)
		if ResourceLoader.exists(path):
			steps.append(load(path) as AudioStream)
	if not steps.is_empty():
		player.footstep_sounds = steps

func _build_documents() -> void:
	add_document(marker("d07"), "res://resources/documents/d07.tres", 2.1)
	add_document(marker("d08"), "res://resources/documents/d08.tres", 2.2)
	add_document(marker("d09"), "res://resources/documents/d09.tres", 2.1)

func _build_offerings_audio() -> void:
	var stream: AudioStream = load_audio(COPAL_AUDIO)
	if stream == null:
		return
	for name: String in ["d07", "d08", "letter"]:
		var audio: AudioStreamPlayer3D = play_sound_at(stream, marker(name), -8.0, 16.0)
		audio.finished.connect(func() -> void: audio.play())
		_copal.append(audio)

func _build_mutations() -> void:
	for index: int in 3:
		_mutation_slots.append(marker("mutation_%d" % index))
		var model: Node3D = spawn_model("ofrenda_arch", self, 0.24, 0.48)
		model.global_position = _mutation_slots[index]
		model.visible = false
		_mutation_models.append(model)

func _update_reading_state() -> void:
	if hud.is_reading:
		if _active_manifestation:
			_entity.vanish()
			_active_manifestation = false
		return
	if _active_manifestation and _entity.visible:
		return
	var player_pos: Vector3 = player.global_position
	for document_id: String in ["d07", "d08", "d09"]:
		if player_pos.distance_to(marker(document_id)) < 3.5:
			return
	if not _d07_done and player_pos.distance_to(marker("d07")) < 5.5:
		_d07_done = true
		return
	if not _d08_done and player_pos.distance_to(marker("d08")) < 5.0:
		_d08_done = true
		return
	if _manifestations == 0 and player_pos.z < marker("manifest_0").z + 8.0 and player_pos.distance_to(marker("manifest_0")) < 12.0:
		_manifest_at(marker("manifest_0"), false)
	elif _manifestations == 1 and player_pos.distance_to(marker("manifest_1")) < 6.0:
		_manifest_random()
	elif _manifestations >= 2 and _manifestations < _budget - 1 and player_pos.distance_to(marker("manifest_2")) < 7.0:
		_manifest_random()

func _update_events() -> void:
	if hud.is_reading or _active_manifestation:
		return
	if _manifestations >= 2 and not _d08_done and player.global_position.distance_to(marker("d08")) < 4.0:
		_d08_done = true
	if _manifestations >= 2 and not _d09_done and player.global_position.distance_to(marker("d09")) < 3.2:
		_d09_done = true
		add_checkpoint("r2", "cp_r2", 0.1)

func _manifest_random() -> void:
	if _manifestations >= _budget - 1:
		return
	var camera: Camera3D = player.camera
	var candidates: Array[Vector3] = []
	for index: int in 6:
		var at: Vector3 = marker("manifest_%d" % index)
		var screen: Vector2 = camera.unproject_position(at + Vector3.UP)
		var rect: Rect2 = get_viewport().get_visible_rect()
		if camera.is_position_behind(at) or not rect.grow(100.0).has_point(screen):
			candidates.append(at)
	if candidates.is_empty():
		return
	_manifest_at(candidates[_rng.randi_range(0, candidates.size() - 1)], false)

func _manifest_at(at: Vector3, look_at_player: bool) -> void:
	if hud.is_reading or _active_manifestation or _manifestations >= _budget:
		return
	_entity.manifest_at(at, look_at_player)
	_active_manifestation = true
	_manifestation_time = 0.0
	_manifestation_origin = at
	_manifestations += 1
	Game.caption("[pasos sobre concreto, muy lejos]")

func _update_manifestation(delta: float) -> void:
	if not _active_manifestation:
		return
	_manifestation_time += delta
	if not _entity.visible:
		_active_manifestation = false
		return
	var distance: float = player.global_position.distance_to(_manifestation_origin)
	if _manifestation_time >= 25.0 or distance > 23.0:
		_entity.vanish()
		_active_manifestation = false
		return
	if _manifestations == 1 and distance > 22.0:
		_entity.vanish()
		_active_manifestation = false

func _on_screeched() -> void:
	Game.caption("[un chillido de estática rasga el silencio]")

func _on_relocated(_to: Vector3) -> void:
	Game.caption("[el eco se apaga detrás de una columna]")

func _update_mutations(delta: float) -> void:
	if _mutations >= 5 or _active_manifestation or hud.is_reading or _mutation_busy:
		return
	_mutation_timer += delta
	if _mutation_timer < 32.0:
		return
	_mutation_timer = 0.0
	var camera: Camera3D = player.camera
	var candidate: int = _mutations % _mutation_models.size()
	var at: Vector3 = _mutation_slots[candidate]
	var screen: Vector2 = camera.unproject_position(at)
	var bounds: Rect2 = get_viewport().get_visible_rect().grow(100.0)
	if player.global_position.distance_to(at) < 14.0 or (not camera.is_position_behind(at) and bounds.has_point(screen)):
		return
	var model: Node3D = _mutation_models[candidate]
	_mutation_busy = true
	model.visible = false
	await get_tree().process_frame
	model.global_position = marker("mutation_%d" % ((candidate + 1) % _mutation_slots.size()))
	model.visible = true
	_mutations += 1
	_mutation_busy = false

func _on_letter_taken() -> void:
	if _ritual:
		return
	_ritual = true
	var collapse: AudioStream = load_audio(COLLAPSE_AUDIO)
	if collapse != null:
		play_sound(collapse, -1.0)
	Game.caption("[los archiveros ceden; la ofrenda se desploma]")
	play_letter_ritual(_altar, _collapse_offering, _finish_ritual, true)

func _collapse_offering() -> void:
	for model: Node3D in _mutation_models:
		model.visible = true
		model.scale = Vector3(1.0, 4.5, 1.0)
	for i: int in 18:
		var angle: float = TAU * float(i) / 18.0
		add_petals(marker("altar") + Vector3(cos(angle) * 5.0, 0.0, sin(angle) * 4.0), 2.2)
	if _entity != null and _manifestations < _budget:
		var at: Vector3 = marker("manifest_4")
		_entity.manifest_at(at, false)
		_manifestations += 1
		get_tree().create_timer(4.0).timeout.connect(func() -> void:
			if is_instance_valid(_entity):
				_entity.vanish()
		)

func _finish_ritual() -> void:
	if _hall != null:
		_hall.stop()
	for audio: AudioStreamPlayer3D in _copal:
		audio.stop()
	player.controls_enabled = true
	await get_tree().create_timer(2.5).timeout
	finish_level(Color(0.03, 0.01, 0.006), 1.7)
