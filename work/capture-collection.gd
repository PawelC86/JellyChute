extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func shot(game: Node2D, filename: String) -> void:
	game.toon_art.sync_ui()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/collection-previews/" + filename + ".png")
func capture() -> void:
	var fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var original_owned: Array = game.owned_characters.duplicate()
	game.owned_characters.assign(range(13))
	assert(game.toon_art.bodies.size() == 13)
	assert(game.toon_art.collection_heads.size() == 9)
	assert(game.toon_art.shop_portrait_clips.size() == 9)
	for index in range(9):
		var origin := Vector2(44 + (index % 3) * 152, 294 + floori(index / 3.0) * 200)
		var clip: Control = game.toon_art.shop_portrait_clips[index]
		var portrait = clip.get_child(0)
		assert(clip.clip_contents and clip.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		assert(clip.position + portrait.FEET == origin + Vector2(72, 125), "All portraits must retain original body alignment")
		assert(portrait.PORTRAIT_SCALE == 1.1)
	for skin in range(4, 13):
		game._return_to_menu()
		game._select_character(skin)
		assert(game.racer_skins.size() == 4 and game.racer_skins[0] == skin)
		assert(game.chute_skin(1) < 4 and game.chute_skin(2) < 4 and game.chute_skin(3) < 4)
		game.carousel_time = game.CAROUSEL_DURATION
		game.animation_time = 1.4
		await shot(game, "character-%02d" % skin)
		for part in [game.toon_art.bodies[skin], game.toon_art.arms[skin], game.toon_art.collection_heads[skin - 4], game.toon_art.collection_extras[skin - 4]]:
			assert(part.get_width() > 2 and part.get_height() > 2)
		game._action()
		game._process(3.01)
		assert(game.state == "race")
		for index in range(4):
			game.racers[index].alt = 35.0
			game.racers[index].speed = game.TERMINAL
		game.camera_alt = 35.0
		await shot(game, "freefall-%02d" % skin)
		game._deploy(0)
		game.racers[0].deploy = 1.0
		await shot(game, "chute-%02d" % skin)
		game.racers[0].alt = 0.0
		game.racers[0].speed = 12.0
		game._land(0)
		game.camera_alt = 0.0
		await shot(game, "splat-%02d" % skin)
		game._load_record()
		assert(game.selected_character == skin, "New character must survive save/reload")
	game._return_to_menu()
	game.owned_characters.assign(original_owned)
	game._open_shop()
	await shot(game, "shop-jellies")
	game._select_shop_tab(1)
	await shot(game, "shop-parachutes")
	game._return_to_menu()
	game._select_character(12)
	game.totals.assign([30, 21, 12, 6])
	game.finish_order.assign([0, 1, 2, 3])
	for racer in game.racers:
		racer.done = true
		racer.safe = true
		racer.finish_age = 1.0
	game._podium()
	await shot(game, "podium")
	fixture.restore()
	print("PASS all nine characters: selection, four-racer roster, texture parts, flight, chute, crash, encrypted persistence, shop tabs and podium rendering")
	quit()
