extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var save_fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._menu()
	game._select_character(0)
	game.animation_time = 1.4
	for shot in ["menu", "countdown", "freefall", "flight", "landing", "splat", "reference-landing", "dust-impact", "finish-reactions", "results", "podium", "countdown-three", "countdown-one", "jump-go"]:
		if shot in ["countdown-three", "countdown-one", "jump-go"]:
			game._start_round()
			game._process({"countdown-three": 0.18, "countdown-one": 2.18, "jump-go": 3.01}[shot])
			if shot == "jump-go":
				game._process(0.16)
		elif shot == "countdown":
			game._start_round()
			game._process(1.2)
		elif shot != "menu":
			game.state = "race"
			game.action.disabled = false
			game.race_time = 5.3
			game.heading.text = ""
			game.detail.text = ""
			game.badge.text = "ROUND 1 / 3"
			game.stats.text = "63.0 m   •   12.0 m/s   •   5.3 s\nWait for it..."
			game.action.text = "OPEN PARACHUTE" if shot == "freefall" else "CHUTE OPEN!"
			game.camera_alt = 63 if shot == "freefall" else (10 if shot == "flight" else 0)
			game.animation_time = 5.3
			for i in range(4):
				game.racers[i].alt = game.camera_alt + i * 0.5 if shot in ["freefall", "flight"] else 0
				game.racers[i].speed = 12.0 if shot == "freefall" else 2.0
				game.racers[i].open = shot != "freefall"
				game.racers[i].deploy = 1.0
				game.racers[i].done = shot in ["landing", "splat"]
				game.racers[i].safe = shot != "splat"
				game.racers[i].squash = 0.0
		if shot == "reference-landing":
			game.camera_alt = 0
			game.stats.text = "0.5 m   •   2.0 m/s\nSOFT LANDINGS, BIG SMILES"
			for i in range(4):
				game.racers[i].alt = [0.0, 0.65, 0.9, 0.5][i]
				game.racers[i].done = false
				game.racers[i].open = true
		if shot == "dust-impact":
			game._reset_racers()
			game.state = "race"
			game.camera_alt = 0.0
			for i in range(4):
				game.racers[i].alt = 0.0
				game.racers[i].speed = game.TERMINAL if i == 0 else 2.0
				game._land(i)
			game._process(0.2)
		if shot == "finish-reactions":
			game.dust.clear()
			game.particles.clear()
			game.state = "settle"
			game.race_time = 14.5
			game.camera_alt = 0.0
			game.finish_order.assign([0, 1, 2, 3])
			for i in range(4):
				game.racers[i].done = true
				game.racers[i].safe = true
				game.racers[i].alt = 0.0
				game.racers[i].speed = 0.0
				game.racers[i].time = 12.0 + i
				game.racers[i].squash = 0.0
				game.racers[i].finish_age = 1.2
		if shot in ["results", "podium"]:
			game.finish_order.assign([0, 1, 2, 3])
			game._results()
			if shot == "podium":
				game._podium()
		game.toon_art.sync_ui()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/" + shot + ".png")
	for character in range(4):
		game._menu()
		game._select_character(character)
		game._process(0.6)
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/menu-character-%d.png" % character)
		game._start_round()
		game._process(0.3)
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/start-character-%d.png" % character)
	game.state = "podium"
	game.finish_order.assign([0, 1, 2, 3])
	game.totals.assign([30, 21, 12, 6])
	for r in game.racers:
		r.done = true
		r.safe = true
		r.squash = 0.0
	for phase in [4.3, 7.1, 9.2]:
		game.podium_dialogue_time = phase
		game.toon_art.sync_ui()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/podium-conflict-%.1f.png" % phase)
	game._return_to_menu()
	game._cycle_character(1)
	game._process(0.12)
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/carousel-transition.png")
	save_fixture.restore()
	game.free()
	quit()








