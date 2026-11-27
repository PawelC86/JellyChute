extends SceneTree
var game: Node2D
var fixture: RefCounted
func _initialize() -> void:
	call_deferred("run")
func shot(label: String) -> void:
	if game.state == "menu":
		game.carousel_time = game.CAROUSEL_DURATION
	game.responsive.update()
	game.toon_art.sync_ui()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.save_png("res://work/responsive-" + label + ".png") == OK)
	for point in [Vector2i(2, 2), Vector2i(image.get_width() - 3, 2), Vector2i(2, image.get_height() - 3), Vector2i(image.get_width() - 3, image.get_height() - 3)]:
		assert(image.get_pixelv(point).v > 0.1, "Unpainted screen corner: " + label)
	var action_bounds: Rect2 = game.action.get_global_rect()
	var layer := game.ui.get_parent() as CanvasLayer
	var transformed: Rect2 = layer.transform * action_bounds
	assert(game.responsive.safe_rect.encloses(transformed), "Action outside safe area: " + label)
func run() -> void:
	fixture = preload("res://work/save_fixture.gd").new()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.selected_character = 0
	game.selected_chute = 0
	game._assign_characters()
	for profile in [["16-9", Vector2i(540, 960)], ["pixel-20-9", Vector2i(432, 960)], ["19-5-9", Vector2i(432, 936)], ["21-9", Vector2i(411, 960)], ["tablet-3-4", Vector2i(600, 800)]]:
		DisplayServer.window_set_size(profile[1])
		await process_frame
		await process_frame
		game._return_to_menu()
		await shot(profile[0] + "-menu")
		var previous: int = game.selected_character
		var arrow: Button = game.character_buttons[1]
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = arrow.get_global_transform_with_canvas() * (arrow.size * 0.5)
		root.push_input(click, true)
		click = click.duplicate()
		click.pressed = false
		root.push_input(click, true)
		assert(game.selected_character != previous, "Arrow hit target mismatch: " + profile[0])
		game.selected_character = 0
		game._assign_characters()
		game._open_shop()
		await shot(profile[0] + "-shop")
		game._select_shop_tab(1)
		await shot(profile[0] + "-chutes")
		game._return_to_menu()
		game._start_round()
		await shot(profile[0] + "-race")
		for i in range(4):
			game.racers[i].done = true
			game.racers[i].safe = true
			game.racers[i].alt = 0.0
			game.racers[i].time = 5.0 + i
		game.finish_order.assign([0, 1, 2, 3])
		game.state = "settle"
		game.camera_alt = game.CAMERA_LEAD_METRES
		await shot(profile[0] + "-landing")
		game._results()
		await shot(profile[0] + "-results")
		game.state = "podium"
		game.toon_art.sync_ui()
		await shot(profile[0] + "-podium")
		game._return_to_menu()
		var updates = game.get_child(game.get_child_count() - 1)
		updates.show_restart_dialog()
		await shot(profile[0] + "-update")
		updates.restart_panel.get_child(updates.restart_panel.get_child_count() - 1).pressed.emit()
		await process_frame
		print("PASS fullscreen scenery and action bounds: ", profile[0])
	# Synthetic notch/navigation insets: artwork stays uniform, controls stay safe.
	game.responsive.apply_bounds(Rect2(0, 42, 540, 1098))
	game.toon_art.sync_ui()
	assert(is_equal_approx(game.scale.x, game.scale.y))
	var layer := game.ui.get_parent() as CanvasLayer
	assert(game.responsive.safe_rect.encloses(layer.transform * game.action.get_global_rect()))
	print("PASS synthetic cutout/navigation safe area")
	fixture.restore()
	quit()

