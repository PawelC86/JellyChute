extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func shot(game: Node2D, name: String) -> void:
	game.toon_art.sync_ui()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/collection-previews/" + name + ".png")
func run_checks() -> void:
	var fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var prefix := "res://work/source-art/chute-check-%d" % Time.get_ticks_usec()
	game.save_path = prefix + ".dat"
	game.legacy_save_path = prefix + ".cfg"
	game.credits = 3000
	game.owned_characters.assign([0, 1, 2, 3])
	game.owned_chutes.assign([0, 1, 2, 3])
	game.selected_character = 0
	game.selected_chute = 0
	game.character_confirmed = true
	game._save_record()
	assert(game.toon_art.canopies.size() == game.CHUTE_NAMES.size())
	assert(game.CHUTE_PRICES == [0, 0, 0, 0, 150, 150, 200, 150, 200, 200, 500, 200, 200])
	assert(game.CHUTE_SHOP_ORDER[7] == 10)
	assert(game.toon_art.shop_chute_buttons[6].position == Vector2(208, 851), "Bling Bling must be in the bottom-centre shop card")
	game._return_to_menu()
	game._cycle_chute(-1)
	assert(game.selected_chute == 3, "Locked parachutes must be skipped")
	game._open_shop()
	game._select_shop_tab(1)
	game.credits = 149
	game._shop_chute_action(4)
	assert(not game.owns_chute(4) and game.credits == 149)
	game.credits = 3000
	game.save_blocked = true
	game._shop_chute_action(4)
	assert(not game.owns_chute(4) and game.credits == 3000)
	game.save_blocked = false
	for chute in range(4, game.CHUTE_NAMES.size()):
		var before: int = game.credits
		var button: Button = game.toon_art.shop_chute_buttons[chute - 4]
		game.toon_art.sync_ui()
		assert(button.visible and not button.disabled)
		button.pressed.emit()
		assert(game.owns_chute(chute) and game.credits == before - game.CHUTE_PRICES[chute])
		assert(button.text == "EQUIP")
		button.pressed.emit()
		assert(game.selected_chute == chute and button.text == "EQUIPPED")
		assert(game.credits == before - game.CHUTE_PRICES[chute])
		assert(game.toon_art.canopies[chute].get_width() <= 384)
		assert(game.toon_art.canopies[chute].get_height() <= 256)
	game._select_shop_tab(0)
	game.toon_art.shop_buy_buttons[0].pressed.emit()
	assert(game.owns_character(4))
	game.toon_art.shop_buy_buttons[0].pressed.emit()
	assert(game.selected_character == 4)
	game.hide()
	game.ui.hide()
	var fresh = load("res://main.tscn").instantiate()
	root.add_child(fresh)
	fresh.set_process(false)
	fresh.save_path = game.save_path
	fresh.legacy_save_path = game.legacy_save_path
	fresh._load_record()
	fresh._assign_characters()
	fresh._reset_racers()
	fresh._menu()
	assert(fresh.selected_character == 4 and fresh.owns_character(4))
	assert(fresh.selected_chute == game.CHUTE_NAMES.size() - 1 and fresh.credits == game.credits)
	for chute in range(game.CHUTE_NAMES.size()):
		assert(fresh.owns_chute(chute), "All purchased parachutes must survive restart")
	fresh._select_character(3)
	fresh._cycle_character(1)
	assert(fresh.selected_character == 4, "Purchased jelly must be selectable on main menu")
	fresh.selected_chute = 3
	for chute in range(4, game.CHUTE_NAMES.size()):
		fresh.chute_buttons[1].pressed.emit()
		assert(fresh.selected_chute == chute, "Purchased parachute must be selectable using main-menu arrows")
		fresh.carousel_time = fresh.CAROUSEL_DURATION
		fresh.animation_time = 1.4
		await shot(fresh, "chute-menu-%d" % chute)
	fresh.chute_buttons[1].pressed.emit()
	assert(fresh.selected_chute == 0)
	for chute in range(4, game.CHUTE_NAMES.size()):
		fresh._return_to_menu()
		fresh.selected_chute = chute
		fresh._action()
		fresh._process(3.01)
		fresh.race_time = 5.0
		fresh.jump_flash = 0
		fresh._deploy(0)
		fresh.racers[0].deploy = 1.0
		fresh.camera_alt = 35
		for index in range(4):
			fresh.racers[index].alt = 35
			fresh.racers[index].speed = 2 if index == 0 else 12
		await shot(fresh, "chute-flight-%d" % chute)
	fresh._return_to_menu()
	fresh._open_shop()
	fresh._select_shop_tab(1)
	fresh.owned_chutes.assign([0, 1, 2, 3, 4, 9])
	fresh.selected_chute = 9
	fresh.credits = 175
	await shot(fresh, "shop-chutes")
	fresh._select_shop_tab(0)
	assert(not fresh.toon_art.shop_chute_buttons[0].visible)
	fresh._return_to_menu()
	assert(not fresh.toon_art.shop_chute_buttons[0].visible)
	fixture.restore()
	game.queue_free()
	fresh.queue_free()
	await process_frame
	print("PASS nine parachutes: prices, funds, save rollback, purchase/equip, restart persistence, purchased jelly and chute main-menu arrow selection, all flight sprites and shop visibility")
	quit()
