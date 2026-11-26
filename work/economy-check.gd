extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func finish_round(game: Node2D, place: int, number: int, safe: bool = true) -> void:
	game.round_number = number
	game._reset_racers()
	var order: Array[int] = [1, 2, 3]
	order.insert(place, 0)
	game.finish_order.assign(order)
	for slot in range(4):
		game.racers[slot].done = true
		game.racers[slot].safe = safe if slot == 0 else true
		game.racers[slot].time = 7.0 + order.find(slot)
	game._results()
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
	var prefix := "res://work/source-art/economy-%d" % Time.get_ticks_usec()
	game.save_path = prefix + ".dat"
	game.legacy_save_path = prefix + ".cfg"
	var legacy := ConfigFile.new()
	legacy.set_value("records", "career_points", 345)
	legacy.set_value("settings", "character", 7)
	legacy.save(game.legacy_save_path)
	game._load_record()
	assert(game.credits == 345 and game.career_points == 345)
	assert(game.owns_character(7), "Migration must preserve a previously confirmed premium skin")
	assert(not FileAccess.file_exists(game.legacy_save_path))
	assert(game.CHARACTER_PRICES == [0, 0, 0, 0, 500, 500, 300, 300, 200, 500, 300, 200, 200])
	game.owned_characters.assign([0, 1, 2, 3])
	game.selected_character = 0
	game._assign_characters()
	game._return_to_menu()
	game._select_character(4)
	assert(game.selected_character == 0)
	game._cycle_character(-1)
	assert(game.selected_character == 3, "Carousel must skip locked characters")
	game._open_shop()
	game.credits = 199
	game._shop_character_action(8)
	assert(game.credits == 199 and not game.owns_character(8))
	game.credits = 200
	game._shop_character_action(8)
	assert(game.credits == 0 and game.owns_character(8) and game.career_points == 345)
	game._shop_character_action(8)
	assert(game.credits == 0 and game.selected_character == 8)
	game._load_record()
	assert(game.credits == 0 and game.owns_character(8) and game.selected_character == 8)
	game.credits = 500
	game.save_blocked = true
	game._shop_character_action(4)
	assert(game.credits == 500 and not game.owns_character(4), "Failed save must roll back purchase")
	game.save_blocked = false
	game._return_to_menu()
	game.credits = 100
	game.career_points = 1000
	game.wins = 5
	for number in range(1, 4):
		finish_round(game, number - 1, number)
		assert(game.credits == (121 if number == 3 else 100))
		assert(game.career_points == (1021 if number == 3 else 1000))
	game._podium()
	game._podium()
	assert(game.credits == 121 and game.career_points == 1021 and game.wins == 5)
	await shot(game, "tournament-reward")
	game._load_record()
	assert(game.credits == 121 and game.career_points == 1021)
	game._return_to_menu()
	finish_round(game, 0, 1)
	finish_round(game, 0, 2)
	game._return_to_menu()
	assert(game.credits == 121, "Abandoned tournament must not pay")
	for number in range(1, 4):
		finish_round(game, 3, number, false)
	assert(game.credits == 121 and game.tournament_reward == 0)
	game._return_to_menu()
	for number in range(1, 3):
		finish_round(game, 0, number)
	game.save_blocked = true
	finish_round(game, 0, 3)
	assert(game.credits == 121 and not game.tournament_paid)
	game.save_blocked = false
	game._podium()
	assert(game.credits == 151 and game.tournament_paid)
	game._podium()
	assert(game.credits == 151)
	game._return_to_menu()
	game.owned_characters.assign([0, 1, 2, 3, 7, 8])
	game.selected_character = 7
	game.credits = 335
	game._open_shop()
	assert(game.toon_art.shop_buy_buttons.size() == 9)
	await shot(game, "shop-purchases")
	assert(game.toon_art.shop_buy_buttons[0].disabled)
	assert(game.toon_art.shop_buy_buttons[3].text == "EQUIPPED")
	assert(game.toon_art.shop_buy_buttons[4].text == "EQUIP")
	game._select_shop_tab(1)
	assert(not game.toon_art.shop_buy_buttons[0].visible)
	fixture.restore()
	game.queue_free()
	await process_frame
	print("PASS migration, ownership, prices, insufficient funds, buy/equip, persistence, save rollback, tournament-only payouts, duplicate protection, abandonment and shop UI")
	quit()
