extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func shot(game: Node2D, label: String) -> void:
	game.toon_art.sync_ui()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://work/bling-" + label + ".png") == OK)
func run() -> void:
	var fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://bling-check.dat"
	game.legacy_save_path = "user://bling-check-legacy.cfg"
	root.add_child(game)
	game.set_process(false)
	game.owned_characters.assign([0, 1, 2, 3])
	game.selected_character = 0
	game.credits = 499
	game._open_shop()
	var buy: Button = game.toon_art.shop_buy_buttons[3]
	assert(buy.position == Vector2(208, 846))
	assert(buy.disabled and buy.text == "BUY  500")
	game.credits = 500
	await shot(game, "shop")
	assert(not buy.disabled)
	buy.pressed.emit()
	assert(game.owns_character(7) and game.credits == 0)
	buy.pressed.emit()
	assert(game.credits == 0 and game.selected_character == 7)
	game._return_to_menu()
	game.carousel_time = game.CAROUSEL_DURATION
	await shot(game, "menu")
	game._action()
	await shot(game, "countdown")
	game.state = "race"
	game.racers[0].speed = game.TERMINAL
	await shot(game, "freefall")
	game._deploy(0)
	game.racers[0].deploy = 1.0
	await shot(game, "parachute")
	game.camera_alt = game.CAMERA_LEAD_METRES
	game.state = "settle"
	game.finish_order.assign([0, 1, 2, 3])
	for slot in range(4):
		game.racers[slot].done = true
		game.racers[slot].safe = true
		game.racers[slot].alt = 0.0
		game.racers[slot].time = 5.0 + slot
	await shot(game, "landing")
	game.round_number = 3
	game.rounds_completed = 3
	game.totals.assign([30, 20, 10, 0])
	game._podium()
	await shot(game, "podium")
	game._return_to_menu()
	game.selected_character = 7
	game.character_confirmed = true
	game._save_record()
	var reload_game = load("res://main.tscn").instantiate()
	reload_game.save_path = game.save_path
	reload_game.legacy_save_path = game.legacy_save_path
	root.add_child(reload_game)
	reload_game.set_process(false)
	assert(reload_game.owns_character(7) and reload_game.selected_character == 7)
	assert(reload_game.CHARACTER_NAMES[7] == "2 CHAINZ, NO BONES")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	fixture.restore()
	game.queue_free()
	reload_game.queue_free()
	await process_frame
	print("PASS 500-credit purchase and insufficient funds; bottom-center shop card; owned skin reload; menu/flight/landing/podium captures")
	quit()
