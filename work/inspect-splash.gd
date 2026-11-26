extends SceneTree
func _initialize() -> void:
	for prop in ProjectSettings.get_property_list():
		if str(prop.name).begins_with("application/boot_splash/"):
			print(prop.name, " = ", ProjectSettings.get_setting(prop.name), " | ", prop.hint_string)
	quit()
