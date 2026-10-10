extends LevelBase
## El Pasaje de las Calaveras: agua, refugios y cazador con presupuesto por tramo.

var altar: LetterAltar = null
var drained: bool = false
var hunter_started: bool = false
var chase_count: int = 0
var loop_count: int = 0
var _segment: int = 0
var _last_state: StringName = &"Wander"
var _last_position: Vector3 = Vector3.ZERO
var _loop_armed: bool = false
var _finishing: bool = false
var _water: Node3D = null
var _wall: Node3D = null
var _broken: Node3D = null
var _wall_collision: CollisionShape3D = null
var _architecture: ShaderMaterial = null
var _documents: Array[DocumentPickup] = []
var _hint: Array[MeshInstance3D] = []
var _budget_spent: bool = false
var _budget_relocated: bool = false


func _ready() -> void:
	super()
	player.flashlight.available = true
	player.flashlight.turn(true)
	player.sprint_enabled = true
	set_touch_button(&"flashlight_visible", true)
	set_touch_button(&"sprint_visible", true)
	_build_surfaces()
	_build_wall()
	for id: String in ["d10", "d11", "d12"]:
		var path: String = "res://resources/documents/%s.tres" % id
		if ResourceLoader.exists(path):
			var document: DocumentPickup = add_document(marker(id), path, 2.4)
			if id == "d10":
				document.document = document.document.duplicate() as DocumentData
				document.document.body += "\nEn el conducto los pasos se quedan afuera. Aquí la luz no falla."
			_documents.append(document)
			if id != "d11":
				_add_document_surface(id, document)
	if ResourceLoader.exists("res://assets/models/letter_h.glb"):
		altar = add_letter("letter_h", "letter")
	else:
		altar = LetterAltar.new()
		add_child(altar)
		push_warning("Modelo pendiente: letter_h")
	altar.taken.connect(_take_letter)
	_share_dynamic_material(altar)
	spawn_entity("res://resources/entity/profile_level3.tres")
	entity.state_changed.connect(_on_state_changed)
	_share_dynamic_material(entity.model, true)
	player.noise_made.connect(_on_noise)
	var saved: String = spawn_at_checkpoint("start", PI)
	_last_position = player.global_position
	if saved == "r1" or saved == "r2":
		hunter_started = true
		_segment = 1 if saved == "r1" else 2
		_relocate_hunter()
	else:
		Game.set_checkpoint("start")
	if saved != "r1" and saved != "r2":
		add_checkpoint("r1", "cp_r1", 2.0)
	if saved != "r2":
		add_checkpoint("r2", "cp_r2", 2.0)
	checkpoint_reached.connect(_on_checkpoint)
	var ambience: AudioStream = load_audio("res://assets/audio/ambient/level3_tunnel_loop.ogg")
	if ambience != null:
		add_loop(ambience, -12.0)
	if Game.wants_petal_hint():
		_show_refuge_hint()


func _process(delta: float) -> void:
	super(delta)
	update_letter_fx(altar)
	if not hunter_started and player.global_position.z >= marker("hunter_gate").z:
		hunter_started = true
		_relocate_hunter()
	if not drained:
		_update_loop()
	if drained and not _finishing and player.global_position.distance_to(marker("exit")) < 1.5:
		_finishing = true
		cut_all_audio()
		finish_level()


func _physics_process(_delta: float) -> void:
	var at: Vector3 = player.global_position
	# Anticipa el dintel con el borde de la cápsula, también al entrar de lado.
	var low: bool = in_zone(at, "duct")
	for offset: Vector3 in [Vector3(0.4, 0, 0), Vector3(-0.4, 0, 0), Vector3(0, 0, 0.4), Vector3(0, 0, -0.4)]:
		low = low or in_zone(at + offset, "duct")
	if low:
		player.set_crouched(true)
	elif player.is_crouched:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.9, at + Vector3.UP * 1.9, 1, [player.get_rid()])
		if player.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			player.set_crouched(false)
	player.in_water = not drained and in_zone(at, "water")
	if entity != null and in_zone(at, "duct"):
		player.flashlight.set_threat.call_deferred(INF, false)
		if entity.current_state() == &"Chase":
			entity.force_state(&"Wander")
	if _budget_spent and entity != null and entity.active:
		# No se recorta una persecución permitida; se enfría después de perder el rastro.
		if entity.current_state() not in [&"Chase", &"Attack"]:
			entity.profile.chase_enabled = false
			entity.profile.attack_enabled = false
			entity.profile.stagnation_ambush = false
			entity.stimulus = 0.0
			if not entity.pressure_frozen and not in_zone(at, "duct"):
				entity.force_state(&"Wander")
				if not _budget_relocated and not player.camera.is_position_in_frustum(entity.global_position + Vector3.UP):
					_relocate_hunter()
					_budget_relocated = true


func _build_surfaces() -> void:
	var shader: Shader = load("res://shaders/water_surface.gdshader") as Shader
	# Concreto y limo comparten material: la normal distingue suelo de paredes/techo.
	var architecture: ShaderMaterial = ShaderMaterial.new()
	architecture.shader = shader
	architecture.set_shader_parameter("architecture", true)
	_architecture = architecture
	for pair: Array in [["albedo_tex", "tunnel_concrete_wet"], ["floor_tex", "tunnel_floor_silt"], ["metal_tex", "duct_metal"], ["clay_tex", "clay_black"]]:
		var path: String = "res://assets/textures/%s.png" % pair[1]
		if ResourceLoader.exists(path):
			architecture.set_shader_parameter(pair[0], load(path))
	# Una sola instancia de material para todas las superficies horneadas.
	for node: Node in geo.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		var merged: ArrayMesh = ArrayMesh.new()
		for i: int in instance.mesh.get_surface_count():
			var material: ShaderMaterial = instance.mesh.surface_get_material(i) as ShaderMaterial
			if material == null:
				continue
			var kind: float = 0.0
			var texture: Texture2D = material.get_shader_parameter("albedo_tex") as Texture2D
			if texture != null:
				if texture.resource_path.ends_with("duct_metal.png"):
					kind = 1.0
				elif texture.resource_path.ends_with("clay_black.png"):
					kind = 2.0
				elif not texture.resource_path.ends_with("tunnel_concrete_wet.png"):
					kind = 3.0
					architecture.set_shader_parameter("palette_tex", texture)
			var energy: Variant = material.get_shader_parameter("unlit_energy")
			if energy is float and energy >= 0.0:
				kind = 4.0
			var arrays: Array = instance.mesh.surface_get_arrays(i)
			_encode_surface(arrays, kind)
			merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		instance.mesh = merged
		instance.material_override = architecture
	var water_material: ShaderMaterial = ShaderMaterial.new()
	water_material.shader = shader
	if ResourceLoader.exists("res://assets/textures/water_marigold.png"):
		water_material.set_shader_parameter("albedo_tex", load("res://assets/textures/water_marigold.png"))
	_water = Node3D.new()
	_water.name = "Agua"
	add_child(_water)
	_water.position.y = 0.14
	# Rectángulos por fila: no hay planos atravesando los refugios secos.
	var cells: Array[Vector2i] = zone_cells("water")
	var remaining: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in cells:
		remaining[cell] = true
	for cell: Vector2i in cells:
		if not remaining.has(cell):
			continue
		var width: int = 1
		while remaining.has(cell + Vector2i(width, 0)):
			width += 1
		var depth: int = 1
		var extend: bool = true
		while extend:
			for x: int in width:
				if not remaining.has(cell + Vector2i(x, depth)):
					extend = false
					break
			if extend:
				depth += 1
		for y: int in depth:
			for x: int in width:
				remaining.erase(cell + Vector2i(x, y))
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(width * 2.0, depth * 2.0)
		var surface: MeshInstance3D = MeshInstance3D.new()
		surface.mesh = quad
		surface.material_override = water_material
		surface.rotation.x = -PI * 0.5
		surface.position = cell_center(cell) + Vector3(width - 1, 0, depth - 1)
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		surface.visibility_range_end = 100.0
		_water.add_child(surface)


## Carga opcional de modelos ajenos, sin preload ni sustitutos primitivos.
func _optional_model(model: String, parent: Node3D) -> Node3D:
	if not ResourceLoader.exists("res://assets/models/%s.glb" % model):
		push_warning("Modelo pendiente: " + model)
		return Node3D.new()
	var instance: Node3D = spawn_model(model, parent, 0.12, 0.65)
	_share_dynamic_material(instance)
	return instance


func _build_wall() -> void:
	_wall = Node3D.new()
	add_child(_wall)
	_wall.position = marker("wall")
	_wall.rotation.y = PI
	_optional_model("clay_wall_panel", _wall)
	_broken = Node3D.new()
	add_child(_broken)
	_broken.position = marker("wall")
	_broken.rotation.y = PI
	_optional_model("clay_wall_broken", _broken)
	_broken.hide()
	var body: StaticBody3D = StaticBody3D.new()
	_wall.add_child(body)
	_wall_collision = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(2, 2.7, 0.3)
	_wall_collision.shape = shape
	_wall_collision.position.y = 1.35
	body.add_child(_wall_collision)


func _on_checkpoint(id: String) -> void:
	if id == "r1" or id == "r2":
		_segment = 1 if id == "r1" else 2
		chase_count = 0
		_budget_spent = false
		_budget_relocated = false
		entity.profile.chase_enabled = true
		entity.profile.attack_enabled = true
		entity.profile.stagnation_ambush = true


func _on_state_changed(state: StringName) -> void:
	if state == &"Chase" and _last_state != &"Chase":
		if chase_count >= Game.difficulty.level3_chases_per_segment:
			entity.force_state.call_deferred(&"Wander")
		else:
			chase_count += 1
			_budget_spent = chase_count >= Game.difficulty.level3_chases_per_segment
	if _last_state == &"Chase" and state == &"Wander" and in_zone(player.global_position, "duct"):
		Game.caption("[respiración — en la boca del conducto]")
	_last_state = state


func _on_noise(radius: float, at: Vector3) -> void:
	if not hunter_started or drained or not player.in_water or not player.is_sprinting:
		return
	Game.caption("[salpicadura — fuerte]")
	if not _budget_spent and entity.global_position.distance_to(at) <= radius:
		entity.add_stimulus(Game.difficulty.threshold_chase * Game.chase_threshold_factor(), at)
		entity.force_state(&"Chase")


func _relocate_hunter() -> void:
	var candidate: Vector3 = marker("ambush_0")
	for i: int in 3:
		var at: Vector3 = marker("ambush_%d" % i)
		if at.distance_to(player.global_position) >= Game.difficulty.respawn_distance and not player.camera.is_position_in_frustum(at + Vector3.UP):
			candidate = at
			break
	entity.teleport_to(candidate)


func _update_loop() -> void:
	var at: Vector3 = player.global_position
	if at.distance_to(marker("loop_a")) < 2.0:
		_loop_armed = true
	var crossed: bool = _last_position.z < marker("loop_b").z and at.z >= marker("loop_b").z and at.distance_to(_last_position) < 1.0
	if _loop_armed and crossed and absf(at.x - marker("loop_b").x) < 1.6 and loop_count < 2:
		loop_count += 1
		player.global_position += marker("loop_a") - marker("loop_b")
	_last_position = player.global_position


func _take_letter() -> void:
	entity.vanish()
	play_letter_ritual(altar, _open_wall, _ritual_done)


func _open_wall() -> void:
	_sound("clay_crack")
	_wall.hide()
	_broken.show()
	_wall_collision.set_deferred("disabled", true)
	_sound("water_drain")
	Game.caption("[el agua se vacía]")
	player.in_water = false
	drained = true
	var tween: Tween = create_tween()
	tween.tween_property(_water, "position:y", -0.22, 2.0)
	tween.tween_callback(_water.hide)


func _ritual_done() -> void:
	player.in_water = false


func _sound(id: String) -> void:
	var stream: AudioStream = load_audio("res://assets/audio/sfx/%s.ogg" % id)
	if stream != null:
		play_sound(stream, -4.0)


func _show_refuge_hint() -> void:
	# Busca por celdas transitables: los pétalos nunca atraviesan una pared.
	var start: Vector2i = cell_of(player.global_position)
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary[Vector2i, Vector2i] = {start: start}
	var rows: PackedStringArray = geo.get_meta("rows")
	var target: Vector2i = start
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		if cell in zone_cells("duct"):
			target = cell
			break
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if previous.has(next) or next.y < 0 or next.y >= rows.size() or next.x < 0 or next.x >= rows[next.y].length():
				continue
			if rows[next.y][next.x] in ["#", "b"]:
				continue
			previous[next] = cell
			queue.append(next)
	var route: Array[Vector2i] = [target]
	while target != start:
		target = previous[target]
		route.push_front(target)
	for i: int in range(1, route.size()):
		var from: Vector3 = cell_center(route[i - 1])
		var to: Vector3 = cell_center(route[i])
		for step: int in 3:
			_hint.append(add_petals(from.lerp(to, (step + 1) / 3.0), 0.35))
	if not _hint.is_empty():
		var material: Material = _hint[0].material_override
		for petals: MeshInstance3D in _hint:
			petals.material_override = material
	get_tree().create_timer(10.0).timeout.connect(func() -> void:
		for petals: MeshInstance3D in _hint:
			petals.hide())


## Hoja mojada y etiqueta: superficies planas, sin utilería primitiva.
func _add_document_surface(id: String, document: DocumentPickup) -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.22, 0.3)
	var paper: MeshInstance3D = MeshInstance3D.new()
	paper.mesh = quad
	var arrays: Array = quad.get_mesh_arrays()
	var colors: PackedColorArray = PackedColorArray()
	colors.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	colors.fill(Color(0.52, 0.49, 0.35))
	arrays[Mesh.ARRAY_COLOR] = colors
	_encode_surface(arrays, 5.0)
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	paper.mesh = mesh
	paper.material_override = _architecture
	document.add_child(paper)
	if id == "d10":
		paper.rotation.x = -PI * 0.5
	else:
		paper.rotation.y = PI * 0.5


## Selector en UV2; mantiene colores horneados, pesos de skin y todas las colisiones.
func _encode_surface(arrays: Array, kind: float) -> void:
	var uv2: PackedVector2Array = PackedVector2Array()
	uv2.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	uv2.fill(Vector2(kind, 0))
	arrays[Mesh.ARRAY_TEX_UV2] = uv2


func _share_dynamic_material(root: Node3D, entity_body: bool = false) -> void:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		# El halo aditivo de la letra conserva su material de efecto.
		if instance.mesh is QuadMesh:
			continue
		var merged: ArrayMesh = ArrayMesh.new()
		for i: int in instance.mesh.get_surface_count():
			var arrays: Array = instance.mesh.surface_get_arrays(i)
			var kind: float = 7.0 if entity_body else 5.0
			if not entity_body:
				var source: StandardMaterial3D = instance.get_active_material(i) as StandardMaterial3D
				var color: Color = Color(0.2, 0.2, 0.2)
				if source != null:
					color = source.emission
					if source.emission_energy_multiplier > 0.4:
						kind = 6.0
				var colors: PackedColorArray = PackedColorArray()
				colors.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
				colors.fill(color)
				arrays[Mesh.ARRAY_COLOR] = colors
			_encode_surface(arrays, kind)
			merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		instance.mesh = merged
		instance.material_override = _architecture
