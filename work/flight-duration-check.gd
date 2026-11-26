extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func flight(game, height: float) -> Vector2:
	game.start_altitude = height
	game._reset_racers()
	game.state = "race"
	var elapsed := 0.0
	var opening := -1.0
	while not game.racers[0].done and elapsed < 30.0:
		if opening < 0.0 and game.racers[0].alt <= game.OPTIMAL_HIGH:
			opening = elapsed
			game._deploy(0)
		elapsed += 1.0 / 120.0
		game._advance_racers(1.0 / 120.0)
	assert(game.racers[0].safe)
	return Vector2(opening, elapsed)

func run_checks() -> void:
	var fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for seconds in [1.2, 2.0, 4.0]:
		print("TIMING target=", seconds, " opening/landing=", flight(game, game.OPTIMAL_HIGH + game.TERMINAL * (seconds - 0.5)))
	game.rng.seed = 31777
	var short_count := 0
	var normal_count := 0
	for trial in range(60):
		game._start_round()
		var height: float = game.start_altitude
		var timing := flight(game, height)
		assert(timing.x >= 1.18 and timing.x <= 4.02)
		if timing.x < 1.99:
			short_count += 1
		else:
			normal_count += 1
	assert(short_count > 0 and normal_count > 0)
	print("PASS 60 safe flights: ", short_count, " shorter and ", normal_count, " standard")
	fixture.restore()
	game.queue_free()
	await process_frame
	quit()