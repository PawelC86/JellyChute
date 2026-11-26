extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var cases := 0
	for fps in [30, 60, 120, 144]:
		for speed in [0.0, 2.0, 5.0, 10.0, game.TERMINAL]:
			for height in [0.01, game.red_altitude * 0.5, game.red_altitude - 0.001, game.red_altitude]:
				game._reset_racers()
				game.state = "race"
				game.racers[0].alt = height
				game.racers[0].speed = speed
				assert(game.deployment_color(height) == Color("ef5269"))
				game._deploy(0)
				for step in range(2400):
					game._advance_racers(1.0 / fps)
					if game.racers[0].done:
						break
				if not game.racers[0].done or game.racers[0].safe:
					push_error("Red deployment must fail: fps=%s speed=%s height=%s" % [fps, speed, height])
					fixture.restore()
					quit(1)
					return
				cases += 1
		for margin in [0.08, 2.0, 5.0]:
			game._reset_racers()
			game.state = "race"
			game.racers[0].alt = game.red_altitude + margin
			game.racers[0].speed = game.TERMINAL
			game._deploy(0)
			for step in range(2400):
				game._advance_racers(1.0 / fps)
				if game.racers[0].done:
					break
			if not game.racers[0].done or not game.racers[0].safe:
				push_error("Deployment above red boundary must remain safe")
				fixture.restore()
				quit(1)
				return
	fixture.restore()
	print("PASS %d red deployments fail at all speeds, including exact boundary, at 30/60/120/144 FPS; 12 openings above boundary remain safe" % cases)
	game.queue_free()
	await process_frame
	quit()