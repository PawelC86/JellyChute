extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var balance = game.career_points
	game.menu_side_buttons[1].pressed.emit()
	assert(game.state == "shop" and not game.action.visible)
	for category in range(2):
		game.shop_tabs[category].pressed.emit()
		assert(game.shop_category == category and game.shop_tabs[category].visible)
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/shop-%d.png" % category)
	game.home_button.pressed.emit()
	assert(game.state == "menu" and game.action.visible and not game.shop_tabs[0].visible)
	assert(game.career_points == balance)
	game._start_round()
	assert(not game.shop_tabs[0].visible and not game.menu_side_buttons[1].visible)
	print("Shop navigation, both tabs, balance preservation and gameplay visibility: OK")
	quit()
