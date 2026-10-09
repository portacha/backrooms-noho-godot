extends SceneTree

## En un checkout nuevo, ejecutar --import primero para registrar class_name.
## Uso: godot --headless --path . --script res://tools/build_levels.gd -- nombre
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 1:
		_fail("Uso: build_levels.gd [-- nombre]")
		return
	var selected: String = args[0] if not args.is_empty() else ""
	var directory: DirAccess = DirAccess.open("res://tools/levels")
	if directory == null:
		_fail("No se pudo abrir tools/levels.")
		return
	var paths: PackedStringArray = PackedStringArray()
	for file: String in directory.get_files():
		if file.ends_with("_def.gd"):
			paths.append(file)
	paths.sort()
	if DirAccess.make_dir_recursive_absolute("res://scenes/levels/generated") != OK:
		_fail("No se pudo crear el directorio de salida.")
		return
	var names: Dictionary[String, bool] = {}
	var built: int = 0
	for file: String in paths:
		var script: GDScript = load("res://tools/levels/" + file) as GDScript
		if script == null or not script.can_instantiate():
			_fail("Definición inválida: " + file)
			return
		var instance: RefCounted = script.new() as RefCounted
		var def: LevelDef = instance as LevelDef
		if def == null:
			_fail("La definición debe extender LevelDef: " + file)
			return
		if not selected.is_empty() and def.name != selected:
			continue
		if names.has(def.name):
			_fail("Nombre de nivel duplicado: " + def.name)
			return
		names[def.name] = true
		var start: int = Time.get_ticks_usec()
		var level: Node3D = LevelBuilder.build(def)
		if level == null:
			_fail("Falló la construcción: " + file)
			return
		var packed: PackedScene = PackedScene.new()
		var error: Error = packed.pack(level)
		if error == OK:
			error = ResourceSaver.save(packed, "res://scenes/levels/generated/" + def.name + ".scn", ResourceSaver.FLAG_COMPRESS)
		var stats: Dictionary = level.get_meta("build_stats")
		level.free()
		if error != OK:
			_fail("Error al guardar " + def.name + ": " + error_string(error))
			return
		print("%s: cells=%d vertices=%d lights=%d seconds=%.3f" % [def.name, stats["cells"], stats["vertices"], stats["lights"], (Time.get_ticks_usec() - start) / 1000000.0])
		built += 1
	if built == 0:
		_fail("No se encontraron definiciones" + (": " + selected if not selected.is_empty() else "."))
		return
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
