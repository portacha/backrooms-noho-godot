extends Node
## Capturas de depuración (herramienta de desarrollo, no forma parte del juego).
## Uso: SHOT_SCENE=res://... SHOT_VIEWS="nombre:x,z,yaw,pitch;..." godot --path . res://tools/debug/shot.tscn
## Opcionales: SHOT_REALITY=0..1 (doble realidad), SHOT_FLASH=1 (linterna), SHOT_LIVE=1 (deja correr el guion del nivel), SHOT_Y=altura.

func _ready() -> void:
	var scene: Node = (load(OS.get_environment("SHOT_SCENE")) as PackedScene).instantiate()
	add_child(scene)
	# Deja terminar el fundido de entrada antes de capturar.
	await get_tree().create_timer(2.2).timeout
	var player: Player = scene.get_node("Player")
	var fx: Node = scene.get_node_or_null("ScreenFx")
	scene.set_process(OS.get_environment("SHOT_LIVE") == "1")
	player.set_physics_process(false)
	if OS.get_environment("SHOT_FLASH") == "1":
		player.flashlight.available = true
		player.flashlight.turn(true)
	if not OS.get_environment("SHOT_REALITY").is_empty() and scene.has_method("set_reality"):
		scene.call("set_reality", OS.get_environment("SHOT_REALITY").to_float())
	var view_index: int = 0
	for view: String in OS.get_environment("SHOT_VIEWS").split(";", false):
		var parts: PackedStringArray = view.split(":")
		var v: PackedFloat64Array = parts[1].split_floats(",")
		player.global_position = Vector3(v[0], OS.get_environment("SHOT_Y").to_float(), v[1])
		player.set_view(deg_to_rad(v[2]), deg_to_rad(v[3]))
		if scene.has_method("_update_mist"):
			scene.call("_update_mist")
		await _frames(12)
		# SHOT_DOCS="d01,d02": abre un documento distinto en cada vista (para revisar el overlay).
		var docs: PackedStringArray = OS.get_environment("SHOT_DOCS").split(",", false)
		if not docs.is_empty():
			var overlay: DocumentOverlay = scene.get_node("Hud/DocumentOverlay")
			overlay.close()
			overlay.open(load("res://resources/documents/%s.tres" % docs[view_index % docs.size()]) as DocumentData)
			await get_tree().create_timer(1.0).timeout
		view_index += 1
		if fx != null:
			fx.set("fade", 0.0)
		await _frames(2)
		get_viewport().get_texture().get_image().save_png("res://builds/shot_%s.png" % parts[0])
	get_tree().quit()


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame
