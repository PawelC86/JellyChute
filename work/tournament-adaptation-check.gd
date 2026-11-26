extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")

func average_target(game) -> float:
	return (game.racers[1].target + game.racers[2].target + game.racers[3].target) / 3.0

func reset_profile(game) -> void:
	game.player_skill = 0.5
	game.long_term_skill = 0.5
	game.learned_rounds = 0
	game.failure_streak = 0
	game.struggle_streak = 0
	game.recent_performance.clear()
	game.tournament_form.clear()

func record(game, kind: String) -> void:
	game.racers[0].safe = kind != "crash"
	game.racers[0].deploy_speed = game.TERMINAL
	game.racers[0].deploy_altitude = 14.0 if kind == "strong" else 22.0
	game._record_player_round(0 if kind == "strong" else 3)

func run_checks() -> void:
	var fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.save_path = "user://tournament-adaptation-check.dat"
	game.legacy_save_path = "user://tournament-adaptation-check.cfg"
	var permutations := [[0,1,2], [0,2,1], [1,0,2], [1,2,0], [2,0,1], [2,1,0]]
	for order in permutations:
		for kind in ["crash", "fourth", "strong"]:
			reset_profile(game)
			game.difficulty_order.assign(order)
			game.round_number = 1
			game._start_round()
			record(game, kind)
			var rounds: int = game.learned_rounds
			game._record_player_round(0)
			assert(game.learned_rounds == rounds and game.tournament_form.size() == 1)
			game.round_number = 2
			game._start_round()
			assert(game.round_player_skill == game.player_skill)
			assert(game.round_rival_adjustment == (-0.2 if kind == "strong" else 1.0))
			var second_height := average_target(game)
			record(game, kind)
			assert(game.tournament_form.size() == 2)
			game.round_number = 3
			game.rng.seed = 945
			game._start_round()
			assert(game.round_rival_adjustment == (-0.65 if kind == "strong" else 2.5))
			assert(game.round_rival_variation == 0.18)
			var adjusted := average_target(game)
			var targets = [game.racers[1].target, game.racers[2].target, game.racers[3].target]
			# Compare the same shuffled tier and random draw with neutral form.
			game.round_rival_adjustment = 0.0
			game.tournament_form.clear()
			game.player_skill = 0.5
			game.rng.seed = 945
			game._start_round()
			var neutral := average_target(game)
			if kind == "strong":
				assert(adjusted < second_height and second_height - adjusted <= 0.700001)
			else:
				assert(adjusted > second_height + 0.6)
			for fps in [30, 60, 120]:
				game._reset_racers()
				game.state = "race"
				game.racers[0].done = true
				for slot in range(1,4):
					game.racers[slot].target = targets[slot-1]
				for step in range(3000):
					game._advance_racers(1.0 / fps)
					if game.racers[1].done and game.racers[2].done and game.racers[3].done:
						break
				for slot in range(1,4):
					assert(game.racers[slot].done and game.racers[slot].safe)
	print("PASS all 6 tier orders: crash/fourth-place relief, mild expert challenge, immediate round-2 adaptation, no duplicate learning; rivals safe at 30/60/120 FPS")
	reset_profile(game)
	for trial in range(5):
		game._reset_racers()
		record(game, "fourth")
	assert(game.struggle_streak == 5 and game.player_skill < 0.5)
	var skill: float = game.player_skill
	game.struggle_streak = 0
	game._load_record()
	assert(game.struggle_streak == 5 and is_equal_approx(game.player_skill, skill))
	var config := ConfigFile.new()
	assert(config.load_encrypted_pass(game.save_path, game.SAVE_PASSWORD) == OK)
	assert(config.get_value("adaptive", "version") == 3)
	assert(config.get_value("adaptive", "struggle_streak") == 5)
	game._return_to_menu()
	assert(game.tournament_form.is_empty() and game.round_rival_adjustment == 0.0)
	assert(game.struggle_streak == 5)
	print("PASS repeated safe losses soften persistent profile, encrypted v3 reload, fresh tournament form without losing learned progress")
	for path in [game.save_path, game.save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	fixture.restore()
	game.queue_free()
	await process_frame
	quit()