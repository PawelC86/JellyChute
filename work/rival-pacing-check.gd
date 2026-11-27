extends SceneTree

var game
var fixture
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func reset_profile() -> void:
	game.player_skill = 0.5
	game.long_term_skill = 0.5
	game.learned_rounds = 0
	game.failure_streak = 0
	game.struggle_streak = 0
	game.recent_performance.clear()
	game.tournament_form.clear()

func run_checks() -> void:
	fixture = preload("res://work/save_fixture.gd").new()
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.save_path = "user://rival-pacing-check.dat"
	game.legacy_save_path = "user://rival-pacing-check.cfg"
	game.rng.seed = 123456
	game.dialogue_rng.seed = 654321
	reset_profile()
	game.owned_characters.assign(range(13))
	game.owned_chutes.assign(range(13))
	var seen_characters := {}
	var seen_chutes := {}
	for tournament in range(250):
		game.selected_character = tournament % 13
		game.selected_chute = (tournament + 5) % 13
		game.state = "menu"
		game._action()
		var skins = game.racer_skins.duplicate()
		var chutes = game.racer_chutes.duplicate()
		for slot in range(1, 4):
			check(game.owns_character(skins[slot]) and skins[slot] != game.selected_character, "Invalid rival jelly")
			check(game.owns_chute(chutes[slot]) and chutes[slot] != game.selected_chute, "Invalid rival chute")
			check(skins.count(skins[slot]) == 1 and chutes.count(chutes[slot]) == 1, "Duplicate rival appearance")
			seen_characters[skins[slot]] = true
			seen_chutes[chutes[slot]] = true
		game.round_number = 2
		game._start_round()
		check(skins == game.racer_skins and chutes == game.racer_chutes, "Appearance changed mid-tournament")
	check(seen_characters.size() == 13 and seen_chutes.size() == 13, "Unlocked collection not fully sampled")
	game.owned_characters.assign([0, 1, 2, 3, 7])
	game.owned_chutes.assign([0, 1, 2, 3, 12])
	game.selected_character = 7
	game.selected_chute = 12
	for trial in range(50):
		game._assign_characters()
		for slot in range(1, 4):
			check(game.racer_skins[slot] in [0, 1, 2, 3] and game.chute_skin(slot) in [0, 1, 2, 3], "Locked or player appearance sampled")
	print("PASS tournament appearances: full and partial collections, exclusions, uniqueness, stable roster")

	var clusters := 0
	for trial in range(500):
		game.round_number = trial % 3 + 1
		game._start_round()
		var targets: Array[float] = []
		for slot in range(1, 4):
			targets.append(game.racers[slot].target)
			check(game.racers[slot].target >= game.red_altitude + 1.2, "Unsafe rival plan")
		targets.sort()
		if targets[2] - targets[0] < game.TERMINAL * 0.25:
			clusters += 1
	check(clusters > 10 and clusters < 65, "Close packs should be rare: %d/500" % clusters)
	print("PASS close packs: %d/500 rounds" % clusters)

	# Predicted baseline must agree with real non-reactive physics, not just stay immutable.
	for fps in [30, 60, 120]:
		for height in [29.4, 42.0, 63.0]:
			game.start_altitude = height
			game._reset_racers()
			game._plan_rival_openings()
			game.state = "race"
			game.racers[0].done = true
			for tick in range(fps * 35):
				game.race_time += 1.0 / fps
				game._advance_racers(1.0 / fps)
				if game.finish_order.size() == 3:
					break
			for slot in range(1, 4):
				check(game.racers[slot].safe, "Original plan was unsafe")
				check(absf(game.racers[slot].time - game.racers[slot].planned_time) <= 1.0 / fps + 0.0001, "Predicted baseline differs from real physics")
	print("PASS original predicted times match real physics within one frame")

	var orders := {}
	for fps in [30, 60, 120]:
		for trial in range(24):
			game.tournament_form.clear()
			game._start_round()
			game.start_altitude = 54.0
			game._reset_racers()
			game._plan_rival_openings()
			game.state = "race"
			game.round_learned = true
			var baseline := []
			for slot in range(1, 4):
				baseline.append([game.racers[slot].planned_target, game.racers[slot].planned_time])
			var deployment_times := {}
			var order: Array[int] = []
			for tick in range(fps * 35):
				if not game.racers[0].open and game.racers[0].alt <= 42.0:
					game._deploy(0)
				game.race_time += 1.0 / fps
				game._advance_racers(1.0 / fps)
				for slot in range(1, 4):
					if game.racers[slot].open and not deployment_times.has(slot):
						deployment_times[slot] = game.race_time
						order.append(slot)
				if game.finish_order.size() == 4:
					break
			check(game.reactive_round and order.size() == 3, "Missing early reaction")
			orders[str(order)] = true
			if order.size() == 3:
				for rank in range(1, 3):
					var gap: float = deployment_times[order[rank]] - deployment_times[order[rank - 1]]
					check(gap >= 0.14 and gap <= 0.8, "Reaction gap outside bounds")
			for slot in range(1, 4):
				check(game.racers[slot].safe and game.racers[slot].done, "Reactive rival crashed")
				check(game.racers[slot].planned_target == baseline[slot - 1][0] and game.racers[slot].planned_time == baseline[slot - 1][1], "Reaction changed learning baseline")
				check(game.racers[slot].deploy_altitude > game.racers[slot].planned_target, "Early reaction did not advance opening")
			# Force a different visible place to prove both adaptive layers use the original plan.
			reset_profile()
			game.round_learned = false
			game._record_player_round(0)
			var expected := 0
			for slot in range(1, 4):
				if baseline[slot - 1][1] < game.racers[0].time:
					expected += 1
			check(game.tournament_form.back().place == expected, "Adaptive placement used reactive result")
			var learned: float = game.player_skill
			reset_profile()
			game._learn_player_round(expected)
			check(is_equal_approx(learned, game.player_skill), "Reactive result contaminated skill")
	check(orders.size() == 6, "Reaction order not varied")
	print("PASS 72 reactive races at 30/60/120 FPS: random order, safe staggered openings, unchanged learning baseline")

	reset_profile()
	game._start_round()
	game.state = "race"
	game.racers[0].alt = 21.0
	var targets := [game.racers[1].target, game.racers[2].target, game.racers[3].target]
	game._deploy(0)
	check(not game.reactive_round, "Normal opening triggered chase")
	check(targets == [game.racers[1].target, game.racers[2].target, game.racers[3].target], "Normal opening changed opponents")
	for strong in [true, false]:
		reset_profile()
		var checkpoints := []
		for trial in range(9):
			game.racers[0].safe = strong
			game.racers[0].deploy_speed = game.TERMINAL
			game.racers[0].deploy_altitude = game.red_altitude + 1.0
			game._learn_player_round(0 if strong else 3)
			if trial % 3 == 2:
				checkpoints.append(game.player_skill)
		check(checkpoints[0] > 0.8 if strong else checkpoints[0] < 0.15, "First tournament adaptation too slow")
		print("Calibration strong=%s after tournaments 1/2/3: %s" % [strong, checkpoints])

	var masks := {}
	for frame in range(1200):
		game.animation_time = frame / 60.0
		for character in range(13):
			var left: bool = game.toon_art.eyes_are_closed("confident", character, -1)
			var right: bool = game.toon_art.eyes_are_closed("confident", character, 1)
			masks[int(left) + 2 * int(right)] = true
	check(masks.size() == 4, "Eye animation lacks left/right/both/open variants")
	for path in [game.save_path, game.save_path + ".tmp", game.legacy_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	fixture.restore()
	game.queue_free()
	await process_frame
	print("Rival pacing failures: %d" % failures)
	quit(1 if failures else 0)
