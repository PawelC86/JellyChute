extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	assert(ProjectSettings.get_setting("application/boot_splash/show_image"))
	assert(ProjectSettings.get_setting("application/boot_splash/stretch_mode") == 1)
	var path: String = ProjectSettings.get_setting("application/boot_splash/image")
	var texture := load(path) as Texture2D
	assert(texture != null)
	var image := texture.get_image()
	assert(image != null and not image.is_empty())
	var color: Color = ProjectSettings.get_setting("application/boot_splash/bg_color")
	for dimensions in [Vector2i(540,960), Vector2i(540,1200), Vector2i(960,720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var background := ColorRect.new()
		background.color = color
		background.size = dimensions
		viewport.add_child(background)
		var art := TextureRect.new()
		art.texture = texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.size = dimensions
		viewport.add_child(art)
		await process_frame
		await RenderingServer.frame_post_draw
		var output := viewport.get_texture().get_image()
		assert(output.get_size() == dimensions)
		assert(output.get_pixel(0,0).is_equal_approx(color), "Uncovered margins must use matching cream")
		output.save_png("res://work/collection-previews/boot-%dx%d.png" % [dimensions.x, dimensions.y])
		viewport.queue_free()
		await process_frame
	print("PASS configured custom boot image, aspect-preserving fit, matching cream underlay and 540x960 / 540x1200 / 960x720 layouts")
	quit()
