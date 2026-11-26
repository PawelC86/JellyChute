extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.totals.assign([30, 21, 12, 6])
	game.finish_order.assign([0, 1, 2, 3])
	for r in game.racers:
		r.done = true
		r.safe = true
		r.squash = 0.0
	game._podium()
	game.animation_time = 5.3
	game.podium_dialogue_time = 0.5
	game.podium_speaker = 2
	game.podium_line = "AT LEAST I AM DESSERT!"
	game.toon_art.sync_ui()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/podium-third-bubble.png")
	fixture.restore()
	game.free()
	quit()