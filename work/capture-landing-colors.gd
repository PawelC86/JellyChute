extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for character in range(game.CHARACTER_NAMES.size()):
		game.selected_character = character
		game._assign_characters()
		game._reset_racers()
		game.state = "settle"
		game.camera_alt = game.CAMERA_LEAD_METRES
		game.finish_order.assign([0, 1, 2, 3])
		for slot in range(4):
			game.racers[slot].alt = 0.0
			game.racers[slot].done = true
			game.racers[slot].safe = true
		game.toon_art.sync_ui()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/landing-colors-%d.png" % character)
	print("Captured all 13 character lineups / 52 landing pads")
	quit()
