extends Node
## Prueba del final: lienzo gris, gafete enmarcado tras el cabeceo, resolución y
## borrado del guardado. Uso:
##   tools/run_godot.sh --headless --path . res://tools/debug/ending_test.tscn
## Con ventana guarda capturas en builds/ending_*.png.

const ENDING_SCENE: PackedScene = preload("res://scenes/levels/ending.tscn")
const GREY_TEXTURE: Texture2D = preload("res://assets/textures/painting_grey.png")
const PAINTING_SHADER: Shader = preload("res://shaders/painting.gdshader")

var _fails: int = 0
var _badge_done: bool = false
var _resolution_done: bool = false
var _logic_time: float = 0.0


func _process(delta: float) -> void:
	_logic_time += delta


func _stamp(label: String) -> void:
	var level: Node = get_tree().current_scene
	var extra: String = ""
	if level != null and level.has_method("badge_center"):
		var pl: Player = level.get_node("Player")
		extra = " pitch=%.3f fade=%.2f nod_done=%s finished=%s" % [pl.head.rotation.x,
			float(level.get("screen_fx").get("fade")), str(level.get("_nod_done")), str(level.get("_finished"))]
	print("STAMP %s wall=%.1f logic=%.1f%s" % [label, Time.get_ticks_msec() / 1000.0, _logic_time, extra])


func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	get_tree().create_timer(240.0).timeout.connect(func() -> void:
		print("ENDING TEST FAIL: tiempo agotado")
		get_tree().quit(1))
	await _run()
	if _fails == 0:
		print("ENDING TEST OK")
	else:
		print("ENDING TEST FAIL (%d fallos)" % _fails)
	get_tree().quit(_fails)


func _check(condition: bool, label: String) -> void:
	print(("OK   " if condition else "FAIL ") + label)
	if not condition:
		_fails += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Captura con ventana; en headless no hay nada que guardar. La pose es estática,
## así que basta con dar segundos de reloj al render (nunca esperas por conteo de
## fotogramas: con el render lento cada una se comería segundos del guion).
func _snap(label: String, settle: float = 0.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var level: Node = get_tree().current_scene
	if level != null and level.has_method("badge_center"):
		var player: Player = level.get_node("Player")
		var active: Camera3D = get_viewport().get_camera_3d()
		print("CAM %s eye=%s fov=%.1f head_pitch=%.3f cam_pitch=%.3f badge=%s painting=%s active=%s active_eye=%s" % [label,
			str(player.camera.global_position), player.camera.fov, player.head.rotation.x,
			player.camera.global_transform.basis.get_euler().x, str(level.call("badge_center")),
			str((level.get("painting") as MeshInstance3D).global_position),
			str(active.get_path()) if active != null else "none",
			str(active.global_position) if active != null else "none"])
	if settle > 0.0:
		await _wait(settle)
	get_viewport().get_texture().get_image().save_png("res://builds/ending_%s.png" % label)


func _run() -> void:
	var level: Node = ENDING_SCENE.instantiate()
	get_tree().root.add_child(level)
	get_tree().current_scene = level
	level.connect("badge_framed", func() -> void: _badge_done = true)
	level.connect("resolution_opened", func() -> void: _resolution_done = true)
	await _wait(3.5)
	_check(level.scene_file_path.ends_with("ending.tscn"), "escena del final carga")
	for key: String in ["painting", "mirror_frame", "boardroom_door"]:
		_check(level.call("has_marker", key), "marcador " + key)
	var player: Player = level.get_node("Player")
	_check(not player.controls_enabled, "sin control del jugador")
	_check(not player.sprint_enabled and not player.flashlight.available, "sin linterna ni sprint")
	_check(not player.flashlight.is_on, "linterna apagada")
	_check(level.get_node("PauseMenu").get("can_pause") == false, "sin pausa durante la secuencia")
	var lights: int = 0
	for node: Node in level.find_children("*", "Light3D", true, false):
		lights += 1
	_check(lights == 1, "única luz dinámica = linterna")
	# El cuadro ya no muestra color: mismo shader del prólogo con la textura gris.
	var canvas: MeshInstance3D = level.get("painting") as MeshInstance3D
	var canvas_ok: bool = canvas != null and canvas.material_override is ShaderMaterial
	_check(canvas_ok, "lienzo instanciado")
	if canvas_ok:
		var material: ShaderMaterial = canvas.material_override as ShaderMaterial
		_check(material.shader == PAINTING_SHADER, "lienzo con el shader del cuadro")
		_check(material.get_shader_parameter(&"painting_tex") == GREY_TEXTURE, "lienzo gris")
		_check(canvas.global_position.distance_to(level.call("marker", "painting")) < 0.01, "lienzo en su marco")
	_check(level.get("badge") != null, "gafete instanciado")
	_check(level.get("screen_fx").get("fade") < 0.5, "la oficina se revela tras el negro")
	await _snap("painting", 2.5)
	_stamp("tras_painting")
	# Composición del gafete: se fuerza la pose final del cabeceo y se captura una
	# ráfaga dando segundos de reloj al render (sin cámara lenta: con `time_scale`
	# bajo no se presenta ningún fotograma nuevo). El cabeceo natural la releva a
	# los 12 s, así que el guion sigue intacto.
	var windowed: bool = DisplayServer.get_name() != "headless"
	if windowed:
		# El render de ventana es llvmpipe (software): a 960×540 cada fotograma
		# cuesta ~4 veces menos y la ráfaga se asienta. Solo afecta al test.
		DisplayServer.window_set_size(Vector2i(960, 540))
		# El bloom a pantalla completa es lo más caro del software: fuera durante
		# la ráfaga (las etiquetas del gafete no usan sombreado de todos modos).
		(level.get_node("WorldEnvironment") as WorldEnvironment).environment.glow_enabled = false
	var eye: Vector3 = player.camera.global_position
	var target: Vector3 = level.call("badge_center")
	var flat: Vector2 = Vector2(target.x - eye.x, target.z - eye.z)
	player.set_view(0.0, atan2(target.y - eye.y, flat.length()))
	for i: int in 3:
		if windowed:
			await _wait(2.5)
			get_viewport().get_texture().get_image().save_png("res://builds/ending_badge_%d.png" % i)
			_stamp("badge_%d" % i)
	if windowed:
		DisplayServer.window_set_size(Vector2i(1280, 720))
		(level.get_node("WorldEnvironment") as WorldEnvironment).environment.glow_enabled = true
	player.steer_look(level.call("marker", "painting"), 1.0)
	_stamp("tras_restaurar")
	# El cabeceo deja el gafete a la vista: se espera al ritmo del guion.
	var budget: float = 25.0
	while not _badge_done and budget > 0.0:
		await _wait(0.2)
		budget -= 0.2
	_check(_badge_done, "el cabeceo termina")
	_stamp("tras_cabeceo")
	if _badge_done:
		_check(player.camera.is_position_in_frustum(level.call("badge_center")), "gafete visible al final del cabeceo")
	# Acelera al paso 4 como haría una tecla tras los 3 s.
	level.call("skip_to_resolution")
	budget = 10.0
	while not _resolution_done and budget > 0.0:
		await _wait(0.2)
		budget -= 0.2
	_check(_resolution_done, "se abre la pantalla de resolución")
	var found: Node = null
	for node: Node in level.find_children("*", "", true, false):
		if node is ResolutionScreen:
			found = node
	_check(found != null, "ResolutionScreen instanciada")
	_check(not Game.has_save(), "Game.has_save() == false después")
	_stamp("tras_resolucion")
	await _snap("resolution", 3.0)
