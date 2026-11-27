extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var portrait = load("res://shop_portrait.gd").new()
	root.add_child(portrait)
	game.toon_art.portrait_target = portrait
	for skin in range(13):
		for frame in range(120):
			portrait.animation_time = frame / 30.0
			for side in [-1, 1]:
				game.toon_art.eyes_are_closed("excited", skin, side)
	game.toon_art.portrait_target = null
	game._open_shop()
	await process_frame
	await process_frame
	print("PASS shop portrait eye animation for all 13 characters and shop rendering")
	portrait.queue_free()
	game.queue_free()
	await process_frame
	quit()
