extends Node
## Prueba de físicas: camina de verdad (InputMap + move_and_slide) por una lista de puntos.
## Uso: WALK_SCENE=res://... WALK_POINTS="x,z;x,z;..." godot --headless --path . res://tools/debug/walk.tscn
## WALK_EXPECT_BLOCKED=1 invierte el resultado (el último punto debe ser inalcanzable).

const ARRIVE: float = 0.45


func _ready() -> void:
	var scene: Node = (load(OS.get_environment("WALK_SCENE")) as PackedScene).instantiate()
	add_child(scene)
	await get_tree().create_timer(2.0).timeout
	var player: Player = scene.get_node("Player")
	player.controls_enabled = true
	var reached: int = 0
	var points: PackedStringArray = OS.get_environment("WALK_POINTS").split(";", false)
	var start: float = Time.get_ticks_msec() / 1000.0
	for point: String in points:
		var v: PackedFloat64Array = point.split_floats(",")
		var target: Vector3 = Vector3(v[0], 0.0, v[1])
		var budget: float = player.global_position.distance_to(target) / player.walk_speed * 1.6 * maxf(OS.get_environment("WALK_SLACK").to_float(), 1.0) + 2.0
		var arrived: bool = false
		while budget > 0.0:
			var offset: Vector3 = target - player.global_position
			offset.y = 0.0
			if offset.length() < ARRIVE:
				arrived = true
				break
			player.set_view(atan2(-offset.x, -offset.z), 0.0)
			Input.action_press("move_forward")
			await get_tree().physics_frame
			budget -= get_physics_process_delta_time()
		Input.action_release("move_forward")
		if not arrived:
			print("ATASCADO camino de (%s) en %s" % [point, player.global_position])
			break
		reached += 1
	var ok: bool = reached == points.size()
	if OS.get_environment("WALK_EXPECT_BLOCKED") == "1":
		ok = not ok
	print("WALK %s: %d/%d puntos, %.0f s de juego, fin en %s" % ["OK" if ok else "FALLÓ", reached, points.size(), Time.get_ticks_msec() / 1000.0 - start, player.global_position])
	get_tree().quit(0 if ok else 1)
