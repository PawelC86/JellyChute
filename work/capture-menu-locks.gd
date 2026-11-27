extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.owned_characters.assign([0, 1, 2, 3])
	game.selected_character = 1
	game._assign_characters()
	game.carousel_time = game.CAROUSEL_DURATION
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/menu-locks.png")
	game.owned_characters.append(7)
	game.selected_character = 7
	game._assign_characters()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/menu-locks-unlocked.png")
	print("Captured fresh ownership and unlocked/selected premium character")
	quit()
