extends RefCounted
# Preserve all actual save files while tests/captures exercise persistence.
var originals := {}
const PATHS := ["user://records.cfg", "user://records.dat", "user://records.dat.tmp"]
func _init() -> void:
	for path in PATHS:
		originals[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
func restore() -> void:
	for path in PATHS:
		if originals[path] == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(originals[path])
			file.close()
