extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var save_fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	assert(game.toon_art.logo.get_width() > 0)
	assert(game.toon_art.menu_decor.size() == 2)
	assert(not game.heading.visible and not game.stats.visible)
	assert(game.action.position == Vector2(48, 822))
	assert(game.toon_art.bodies.size() == game.CHARACTER_NAMES.size())
	assert(game.toon_art.canopies.size() == game.CHUTE_NAMES.size())
	assert(game.toon_art.props.size() == 9)
	for texture in game.toon_art.bodies + game.toon_art.canopies + game.toon_art.props:
		assert(texture.get_width() > 0 and texture.get_height() > 0)
	_check_encrypted_save(game)
	_check_adaptation_and_gauge(game)
	_check_career_points(game)
	_check_character_selection(game)
	_check_chute_selection(game)
	_check_menu_return(game)
	_check_difficulties(game)
	_check_canopy_regions(game)
	_check_podium_dialogue(game)
	_check_keyboard_deploy(game)
	_check_comedy_signs(game)
	_check_hair_flutter(game)
	_check_expressions(game)
	_check_landing_effects(game)
	_check_finish_reactions(game)
	_check_hud(game)
	_check_short_drop(game)
	_check_first_landing_deadline(game)
	_check_normal_finish_delay(game)
	_check_race_clock_finish(game)
	_check_cloud_continuity(game)
	game._action()
	assert(game.heading.text == "3")
	assert(not game.heading.visible and not game.stats.visible)
	assert(game.action.position == Vector2(30, 852))
	for digit in [3, 2, 1]:
		game._process(0.9)
		assert(game.countdown_number == digit)
		assert(game.racers[0].alt == game.start_altitude)
		assert(game.racers[0].speed == 0.0)
		game._process(0.101)
	assert(game.state == "race")
	assert(game.race_time == 0.0)
	assert(game.heading.text == "GO!")
	game.camera_alt = 63.0
	game.racers[0].alt = 63.0
	var initial_y = game._world_y(60.0)
	game.camera_alt -= 1.0
	assert(is_equal_approx(initial_y - game._world_y(60.0), game.PIXELS_PER_METRE))
	game.racers[0].alt = 0.0
	assert(is_equal_approx(game._racer_feet(0).y, game._ground_y()))
	game._start_round()
	for step in range(210):
		game._process(1.0 / 60.0)
	assert(game.state == "race")
	for round_index in range(3):
		for step in range(3600):
			if game.state == "race" and game.racers[0].alt < 18.0:
				game._deploy(0)
			game._process(1.0 / 60.0)
			if game.state == "results":
				break
		assert(game.state == "results", "Round must end")
		assert(game.racers[0].safe, "18m opening must land safely")
		assert(game.finish_order.size() == 4)
		for racer_index in range(4):
			assert(is_equal_approx(game._racer_feet(racer_index).y, game._ground_y()), "Landed feet must touch pad, including during camera movement")
		print("PASS round ", round_index + 1, " safe player time=", game.racers[0].time)
		game._action()
		if round_index < 2:
			for step in range(210):
				game._process(1.0 / 60.0)
	assert(game.state == "podium")
	game._action()
	for step in range(3600):
		game._process(1.0 / 60.0)
		if game.state == "results":
			break
	assert(not game.racers[0].safe, "No chute must splat")
	assert(game.totals[0] == 0)
	assert(game.racers[0].squash == 0.0, "Crash must recover before results")
	assert(game._landing_stretch(0.0, false).is_equal_approx(Vector2.ONE))
	assert(game._landing_stretch(1.0, false).y < 0.3)
	print("PASS 3-2-1 countdown, 63px/metre scale, upward world motion, crash recovery")
	print("PASS podium/restart/no-chute zero points")
	save_fixture.restore()
	game.queue_free()
	await process_frame
	quit()







func _check_expressions(game) -> void:
	game.state = "race"
	game.race_time = 1.0
	var r = game.racers[0]
	r.alt = 110.0
	assert(game.toon_art.expression_for(0, true) == "excited")
	game.race_time = 4.0
	assert(game.toon_art.expression_for(0, true) == "confident")
	r.alt = 40.0
	assert(game.toon_art.expression_for(0, true) == "concerned")
	r.alt = 14.0
	assert(game.toon_art.expression_for(0, true) == "panic")
	r.open = true
	r.deploy = 0.2
	assert(game.toon_art.expression_for(0, true) == "surprised")
	r.deploy = 1.0
	assert(game.toon_art.expression_for(0, true) == "relief")
	r.alt = 0.5
	assert(game.toon_art.expression_for(0, true) == "victory")
	r.done = true
	r.safe = false
	assert(game.toon_art.expression_for(0, true) == "dizzy")
	r.safe = true
	assert(game.toon_art.expression_for(0, true) == "champion")
	game._reset_racers()
	game.state = "menu"
	print("PASS animated expression transitions: excited/confident/concerned/panic/surprised/relief/victory/dizzy")

func _check_landing_effects(game) -> void:
	for clock in [0.0, 0.1, 3.7, 7.4]:
		game.animation_time = clock
		for i in range(4):
			for side in [-1, 1]:
				assert(not game.toon_art.eyes_are_closed("landed", i, side))
	game._reset_racers()
	game.state = "race"
	game.racers[0].alt = 0.0
	game.racers[0].speed = game.TERMINAL
	game._land(0)
	assert(game.dust.size() == 10)
	assert(not game.racers[0].safe)
	var initial_radius = game.dust[0].radius
	game._process(0.2)
	assert(game.dust[0].age > 0.0 and game.dust[0].radius > initial_radius)
	game._reset_racers()
	game.racers[0].alt = 0.0
	game.racers[0].speed = 2.0
	game._land(0)
	assert(game.dust.is_empty())
	assert(game.toon_art.expression_for(0, true) == "champion")
	game._reset_racers()
	game.state = "menu"
	print("PASS open landed eyes, dust only on hard landing, animated dust expansion")



func _check_finish_reactions(game) -> void:
	game._reset_racers()
	game.state = "race"
	var expected = ["champion", "runner_up", "relieved", "disappointed"]
	var finishers = [2, 0, 3, 1]
	for place in range(4):
		var i = finishers[place]
		game.racers[i].done = true
		game.racers[i].safe = true
		game.racers[i].alt = 0.0
		game.racers[i].time = 10.0 + place
		game.finish_order.append(i)
		for known_place in range(place + 1):
			assert(game.toon_art.reaction_for(finishers[known_place]) == expected[known_place])
	for i in range(4):
		var mood = game.toon_art.expression_for(i, true)
		for side in [-1, 1]:
			assert(not game.toon_art.eyes_are_closed(mood, i, side))
	game.racers[2].safe = false
	assert(game.toon_art.reaction_for(2) == "dizzy")
	assert(game.toon_art.reaction_for(0) == "champion")
	game.state = "podium"
	game.totals.assign([7, 2, 15, 10])
	assert(game.toon_art.reaction_for(2) == "champion")
	assert(game.toon_art.reaction_for(0) == "relieved")
	game.totals.assign([0, 0, 0, 0])
	game._reset_racers()
	game.state = "menu"
	print("PASS finish reactions: actual order, stable placement, crash override, tournament podium, open eyes")

func _check_hud(game) -> void:
	game._reset_racers()
	game.state = "race"
	game.racers[0].alt = 14.0
	assert(game.toon_art.hud_status().text == "TRUST THE ALTITUDE BAR")
	game.racers[1].alt = 10.0
	assert(game.live_order().find(0) == 1)
	game.toon_art.sync_ui()
	assert(not game.action.disabled)
	game.racers[0].open = true
	game.racers[0].deploy = 0.5
	game.toon_art.sync_ui()
	assert(game.action.disabled)
	assert(game.toon_art.hud_status().text == "CHUTE INFLATING...")
	game._reset_racers()
	game.state = "menu"
	game.toon_art.sync_ui()
	print("PASS race HUD: live ranking, low-altitude warning, deployment status and button state")


func _check_short_drop(game) -> void:
	for trial in range(24):
		game._start_round()
		game.state = "race"
		while game.racers[0].alt > game.OPTIMAL_HIGH:
			game._process(1.0 / 120.0)
		assert(game.race_time >= 1.9 and game.race_time <= 4.1, "Deployment zone must arrive within 2–4 seconds")
		game._deploy(0)
		while game.state == "race":
			game._process(1.0 / 120.0)
		assert(game.racers[0].safe, "Green zone must allow safe landing")
	game.totals.assign([0, 0, 0, 0])
	game._reset_racers()
	game.state = "menu"
	print("PASS 24 randomized 2–4 second drops and safe green-zone deployments")


func _check_canopy_regions(game) -> void:
	var expected := [Rect2(23, 417, 300, 241), Rect2(325, 417, 296, 239), Rect2(624, 417, 299, 239), Rect2(926, 417, 304, 240)]
	for i in range(4):
		var texture: AtlasTexture = game.toon_art.canopies[i]
		assert(texture.region == expected[i], "Canopy must include its complete silhouette across old column seams")
		assert(texture.filter_clip)
		if i > 0:
			assert(expected[i - 1].end.x < texture.region.position.x, "Canopy regions must exclude neighbouring canopies")
	print("PASS full canopy silhouettes, separate atlas regions and filtered edges")

func _check_character_selection(game) -> void:
	var previous_owned: Array = game.owned_characters.duplicate()
	game.owned_characters.assign(range(game.CHARACTER_NAMES.size()))
	game.character_confirmed = false
	game._menu()
	assert(not game.action.disabled)
	assert(game.character_buttons.size() == 2)
	game._select_character(0)
	game.character_buttons[0].pressed.emit()
	assert(game.selected_character == game.CHARACTER_NAMES.size() - 1 and game.carousel_direction == -1.0)
	game.character_buttons[1].pressed.emit()
	assert(game.selected_character == 0 and game.carousel_direction == 1.0)
	for character in range(game.CHARACTER_NAMES.size()):
		game._menu()
		game._select_character(character)
		assert(game.racer_skins[0] == character)
		assert(game.COLORS[0] == game.CHARACTER_COLORS[character])
		assert(game.NAMES[0] == "YOU")
		game.carousel_time = 0.0
		game._process(0.2)
		assert(game.carousel_time > 0 and game.carousel_time < game.CAROUSEL_DURATION)
		var unique := {}
		for slot in range(4):
			unique[game.racer_skins[slot]] = true
		assert(unique.size() == 4)
		game.action.pressed.emit()
		assert(game.state == "countdown" and game.character_confirmed)
		for button in game.character_buttons:
			assert(not button.visible)
		game.selected_character = 0
		game._load_record()
		assert(game.selected_character == character, "Confirmation must save the chosen jelly")
		game.state = "race"
		game._deploy(0)
		assert(game.racers[0].open and not game.racers[1].open)
	var restarted = load("res://main.tscn").instantiate()
	root.add_child(restarted)
	restarted.set_process(false)
	assert(restarted.selected_character == game.CHARACTER_NAMES.size() - 1 and restarted.racer_skins[0] == game.CHARACTER_NAMES.size() - 1)
	restarted.free()
	game._menu()
	game._select_character(0)
	game._action()
	game._return_to_menu()
	game.character_buttons[1].pressed.emit()
	assert(game.selected_character == 1)
	game._load_record()
	assert(game.selected_character == 0, "Browsing must not persist until confirmation")
	game._assign_characters()
	game._reset_racers()
	game._menu()
	game.owned_characters.assign(previous_owned)
	print("PASS arrow wraparound, animated preview, explicit confirmation, persistence and left player lane")

func _check_menu_return(game) -> void:
	var selected = game.selected_character
	var records = [game.wins, game.best_time]
	for screen in ["countdown", "race", "settle", "results", "podium"]:
		game._start_round()
		game.state = screen
		game.totals.assign([10, 7, 4, 2])
		game.toon_art.sync_ui()
		assert(game.home_button.visible and not game.home_button.disabled)
		game.home_button.pressed.emit()
		assert(game.state == "menu" and not game.home_button.visible)
		assert(game.selected_character == selected and game.racer_skins[0] == selected)
		assert([game.wins, game.best_time] == records)
		assert(game.totals == [0, 0, 0, 0] and game.finish_order.is_empty())
		assert(not game.racers[0].open and not game.racers[0].done)
		game._process(4.0)
		assert(game.state == "menu", "Abandoned countdown/results must not resume")
		game._action()
		assert(game.state == "countdown" and game.round_number == 1)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_input(escape)
	assert(game.state == "menu")
	print("PASS menu return from all five screens, clean restart, retained character/records and Escape")

func _check_difficulties(game) -> void:
	game.rng.seed = 417
	var permutations := {}
	var hard_positions := {}
	for tournament in range(90):
		game._menu()
		game._action()
		var order = game.difficulty_order.duplicate()
		var sorted = order.duplicate()
		sorted.sort()
		assert(sorted == [0, 1, 2], "Each difficulty must appear exactly once")
		permutations[str(order)] = true
		hard_positions[order.find(2)] = true
		game.round_number = 2
		game._start_round()
		assert(game.difficulty_order == order, "Round changes must preserve the tournament shuffle")
	assert(permutations.size() == 6 and hard_positions.size() == 3)
	game.difficulty_order.assign([0, 1, 2])
	game.player_skill = 0.5
	var sampled_means := []
	var sampled_bounds := []
	for difficulty in range(3):
		game.round_number = difficulty + 1
		var total := 0.0
		var low := 100.0
		var high := 0.0
		for sample in range(300):
			game._start_round()
			for slot in range(1, 4):
				var target: float = game.racers[slot].target
				total += target
				low = minf(low, target)
				high = maxf(high, target)
				assert(target >= game.red_altitude + 1.2 and target <= 24.0)
			assert(game.racers[1].target != game.racers[2].target)
			var stable: float = game.racers[1].target
			game._process(0.02)
			assert(game.racers[1].target == stable)
		sampled_means.append(total / 900)
		sampled_bounds.append(Vector2(low, high))
	assert(sampled_means[0] < 20 and sampled_means[0] > sampled_means[1] and sampled_means[1] > sampled_means[2])
	assert(sampled_bounds[0].x < sampled_bounds[1].y and sampled_bounds[1].x < sampled_bounds[2].y)
	for fps in [30, 60, 120]:
		var averages := []
		for difficulty in range(3):
			game.round_number = difficulty + 1
			game.start_altitude = 48.0
			game.round_player_skill = 0.5
			game.rival_round_form = 0.0
			game.rng.seed = 42
			game._reset_racers()
			game.state = "race"
			for step in range(2000):
				game._process(1.0 / fps)
				if game.finish_order.size() == 4:
					break
			assert(game.finish_order.size() == 4)
			var total := 0.0
			for slot in range(1, 4):
				assert(game.racers[slot].safe, "Rivals must land safely at every difficulty")
				total += game.racers[slot].time
			averages.append(total / 3)
		assert(averages[0] > averages[1] and averages[1] > averages[2], "Harder rivals must actually finish faster")
	game.rng.randomize()
	game.round_number = 1
	game.totals.assign([0, 0, 0, 0])
	game._reset_racers()
	game._menu()
	print("PASS all six difficulty permutations, hard round in all positions, stable order and faster safe rivals at 30/60/120 FPS")

func _check_hair_flutter(game) -> void:
	var points := PackedVector2Array([Vector2(-19, -56), Vector2(5, -88)])
	var calm = game.toon_art.flutter_hair(points, 0.1, 0.0)
	var first = game.toon_art.flutter_hair(points, 0.1, 1.0)
	var second = game.toon_art.flutter_hair(points, 0.2, 1.0)
	assert(calm == points)
	assert(first[0] == points[0] and second[0] == points[0])
	assert(first[1].distance_to(second[1]) > 0.5)
	print("PASS Star hair airflow deformation: anchored roots, animated tips, calm without wind")

func _check_keyboard_deploy(game) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	game._start_round()
	game._unhandled_input(key)
	assert(not game.racers[0].open)
	game.state = "race"
	game._unhandled_input(key)
	assert(game.racers[0].open)
	for slot in range(1, 4):
		assert(not game.racers[slot].open)
	game.racers[0].deploy = 0.5
	game._unhandled_input(key)
	assert(game.racers[0].deploy == 0.5)
	game._return_to_menu()
	game._unhandled_input(key)
	assert(game.state == "menu" and not game.racers[0].open)
	print("PASS keyboard deployment in flight only, player-only control and repeated press safety")

func _check_podium_dialogue(game) -> void:
	game._reset_racers()
	game.finish_order.assign([0, 1, 2, 3])
	for r in game.racers:
		r.done = true
		r.safe = true
	game.state = "results"
	var physics_rng = game.rng.state
	game.dialogue_rng.seed = 318
	game._begin_podium_dialogue()
	var line = game.podium_line
	var speaker = game.podium_speaker
	game._advance_podium_dialogue(0.1)
	assert(game.podium_line == line and game.podium_speaker == speaker)
	var seen := [{}, {}, {}]
	var previous := ["", "", ""]
	for beat in range(180):
		var rank: int = game.podium_speaker
		assert(previous[rank] != game.podium_line, "Consecutive lines for a place must differ")
		previous[rank] = game.podium_line
		seen[rank][game.podium_line] = true
		game._advance_podium_dialogue(2.8)
	for lines in seen:
		assert(lines.size() >= 9, "Each place must have a varied joke pool")
	assert(game.rng.state == physics_rng, "Dialogue must not affect race randomness")
	game._reset_racers()
	game._menu()
	print("PASS varied podium jokes, stable reading time, speaker rotation, no immediate repeats and independent randomness")

func _check_career_points(game) -> void:
	var original: int = game.career_points
	var original_credits: int = game.credits
	var original_wins: int = game.wins
	for place in range(4):
		game._return_to_menu()
		var before: int = game.career_points
		var wallet: int = game.credits
		for round_index in range(1, 4):
			game.round_number = round_index
			game._reset_racers()
			var order: Array[int] = [1, 2, 3]
			order.insert(place, 0)
			game.finish_order.assign(order)
			for slot in range(4):
				game.racers[slot].done = true
				game.racers[slot].safe = true
				game.racers[slot].time = 7.0 + order.find(slot)
			var learned_before: int = game.learned_rounds
			game._results()
			var reward: int = game.POINTS[place] * 3 if round_index == 3 else 0
			assert(game.career_points == before + reward)
			assert(game.credits == wallet + reward)
			game._results()
			assert(game.career_points == before + reward)
			assert(game.learned_rounds == learned_before + 1)
		game._podium()
		game._podium()
		assert(game.career_points == before + game.POINTS[place] * 3)
		game._load_record()
		assert(game.credits == wallet + game.POINTS[place] * 3)
	game._return_to_menu()
	var balance: int = game.credits
	game.round_number = 1
	game._reset_racers()
	game.finish_order.assign([0, 1, 2, 3])
	for racer in game.racers:
		racer.done = true
		racer.safe = true
	game._results()
	game._return_to_menu()
	assert(game.credits == balance, "An abandoned tournament must not pay credits")
	game.career_points = original
	game.credits = original_credits
	game.wins = original_wins
	game.displayed_career_points = original_credits
	game._save_record()
	print("PASS tournament-only credits/career rewards, all placements, repeated result/podium protection, persistence and abandonment")

func _check_encrypted_save(game) -> void:
	var isolated = load("res://main.gd").new()
	isolated.save_path = "user://encryption-check.dat"
	isolated.legacy_save_path = "user://encryption-check.cfg"
	for path in [isolated.save_path, isolated.save_path + ".tmp", isolated.legacy_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var legacy := ConfigFile.new()
	legacy.set_value("records", "career_points", 12345)
	legacy.set_value("records", "best_time", 6.75)
	legacy.set_value("records", "wins", 19)
	legacy.set_value("settings", "character", 2)
	assert(legacy.save(isolated.legacy_save_path) == OK)
	isolated._load_record()
	assert(isolated.career_points == 12345 and isolated.wins == 19)
	assert(isolated.best_time == 6.75 and isolated.selected_character == 2)
	assert(isolated.character_confirmed)
	assert(not FileAccess.file_exists(isolated.legacy_save_path))
	assert(FileAccess.file_exists(isolated.save_path))
	var bytes := FileAccess.get_file_as_bytes(isolated.save_path)
	assert(bytes.slice(0, 4).get_string_from_ascii() == "GDEC")
	var decoded := ConfigFile.new()
	assert(decoded.load_encrypted_pass(isolated.save_path, isolated.SAVE_PASSWORD) == OK)
	assert(decoded.get_value("records", "career_points") == 12345)
	isolated.career_points = 12355
	assert(isolated._save_record() == OK)
	isolated.career_points = 0
	isolated._load_record()
	assert(isolated.career_points == 12355)
	assert(not FileAccess.file_exists(isolated.save_path + ".tmp"))
	for path in [isolated.save_path, isolated.save_path + ".tmp", isolated.legacy_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	isolated.free()
	print("PASS encrypted roundtrip, atomic replacement and legacy migration preserving all progress")

func _check_comedy_signs(game) -> void:
	var seen := {}
	var previous: String = game.platform_sign
	var physics_rng = game.rng.state
	for sample in range(80):
		game._roll_platform_sign()
		assert(game.platform_sign != previous)
		seen[game.platform_sign] = true
		previous = game.platform_sign
	assert(seen.size() > 8)
	assert(game.rng.state == physics_rng)
	for i in range(4):
		for side in [-1, 1]:
			assert(not game.toon_art.eyes_are_closed("proud", i, side))
	print("PASS varied non-repeating platform signs, independent random source and open proud eyes")

func _check_adaptation_and_gauge(game) -> void:
	var original_skill: float = game.player_skill
	var original_rounds: int = game.learned_rounds
	assert(game.red_altitude > 10 and game.red_altitude < 13)
	for fps in [30, 60, 120]:
		for margin in [-0.08, 0.08, 2.0, 5.0]:
			game._reset_racers()
			game.state = "race"
			game.racers[0].alt = game.red_altitude + margin
			game.racers[0].speed = game.TERMINAL
			game._deploy(0)
			for step in range(1200):
				game._process(1.0 / fps)
				if game.racers[0].done:
					break
			assert(game.racers[0].safe == (margin > 0), "Gauge red boundary must match actual crash/safe outcome")
	game.player_skill = 0.5
	game.learned_rounds = 0
	game.racers[0].safe = true
	game.racers[0].deploy_altitude = game.red_altitude + 1.5
	game.racers[0].deploy_speed = game.TERMINAL
	for i in range(16):
		var before: float = game.player_skill
		game._learn_player_round(0)
		assert(absf(game.player_skill - before) <= 0.080001)
	var skilled: float = game.player_skill
	assert(skilled > 0.8)
	game.racers[0].safe = false
	for i in range(16):
		game._learn_player_round(3)
	assert(game.player_skill < 0.25)
	game.rival_round_form = 0.0
	game.round_player_skill = 0.0
	game.rng.seed = 50
	var novice_target: float = game._rival_deploy_height()
	game.round_player_skill = 1.0
	game.rng.seed = 50
	assert(game._rival_deploy_height() < novice_target)
	assert(game._save_record() == OK)
	var learned: float = game.player_skill
	var rounds: int = game.learned_rounds
	game.player_skill = 0.5
	game.learned_rounds = 0
	game._load_record()
	assert(is_equal_approx(game.player_skill, learned) and game.learned_rounds == rounds)
	game.player_skill = original_skill
	game.learned_rounds = original_rounds
	game._save_record()
	game.rng.randomize()
	game._return_to_menu()
	print("PASS physics-matched red/green boundary at 30/60/120 FPS, gradual learning, recovery after losses and encrypted profile reload")

func _check_first_landing_deadline(game) -> void:
	for fps in [30, 60, 120]:
		game._reset_racers()
		game.state = "race"
		game.racers[0].alt = 40.0
		game.racers[0].open = true
		game.racers[0].speed = 2.0
		game.racers[0].deploy = 1.0
		game.racers[1].alt = 0.0
		game.racers[1].speed = 2.0
		game._land(1)
		var snapshot: Array[Dictionary] = game.racers.duplicate(true)
		while game.race_time + 1.0 / fps < 3.0:
			game._process(1.0 / fps)
			assert(game.state == "race", "Must wait three seconds after the first landing")
		while game.state == "race":
			game._process(1.0 / fps)
		assert(game.state == "settle" and not game.racers[0].done)
		assert(game.racers[0].alt > 0.0)
		var camera_before: float = game.camera_alt
		game._process(0.3)
		assert(game.camera_alt < camera_before)
		game._process(game.CAMERA_SETTLE_DURATION - 0.3)
		assert(game.state == "settle")
		assert(is_equal_approx(game._ground_y(), 690.0))
		game._process(game.GROUND_RESULTS_HOLD + 0.01)
		assert(game.state == "results")
		var resolved_order: Array[int] = game._ranked()
		var resolved_time: float = game.racers[0].time
		assert(game.racers[0].safe and resolved_time > 10.0)
		game.racers = snapshot
		game.finish_order.assign([1])
		game.race_time = 0.0
		game.state = "race"
		while game.finish_order.size() < 4:
			game.race_time += game.PHYSICS_STEP
			game._advance_racers(game.PHYSICS_STEP)
		assert(game._ranked() == resolved_order)
		assert(absf(game.racers[0].time - resolved_time) < 0.05)
		game._reset_racers()
		assert(game.first_landing_time == -1.0)
	game._return_to_menu()
	print("PASS first-landing deadline, early-chute resolution, camera descent, ranking/time preservation and reset at 30/60/120 FPS")

func _check_chute_selection(game) -> void:
	game._return_to_menu()
	game._select_character(1)
	game.selected_chute = 0
	assert(game.chute_buttons.size() == 2)
	assert(game.chute_buttons[0].visible)
	game.chute_buttons[0].pressed.emit()
	assert(game.selected_chute == 3 and game.selected_character == 1)
	game.chute_buttons[1].pressed.emit()
	assert(game.selected_chute == 0)
	game._cycle_chute(1)
	game._select_character(2)
	assert(game.selected_chute == 1 and game.chute_skin(0) == 1)
	for slot in range(1,4):
		assert(game.chute_skin(slot) == game.racer_skins[slot] % 4)
	game._action()
	assert(not game.chute_buttons[0].visible)
	game._cycle_chute(1)
	assert(game.selected_chute == 1, "Flight must lock appearance selection")
	var restarted = load("res://main.tscn").instantiate()
	root.add_child(restarted)
	restarted.set_process(false)
	assert(restarted.selected_character == 2 and restarted.selected_chute == 1)
	restarted.free()
	game._return_to_menu()
	game.selected_chute = 3
	game._load_record()
	assert(game.selected_chute == 1, "Unconfirmed browsing must not overwrite saved configuration")
	game._assign_characters()
	game._reset_racers()
	game._menu()
	print("PASS independent chute arrows, wraparound, player-only skin, flight lock and saved jelly/chute restart")

func _check_normal_finish_delay(game) -> void:
	for fps in [30, 60, 120]:
		game._reset_racers()
		game.state = "race"
		game.camera_alt = 0.0
		for i in range(4):
			game.racers[i].alt = 0.0
			game.racers[i].speed = 2.0
			game._land(i)
		game._process(1.0 / fps)
		assert(game.state == "settle")
		assert(is_equal_approx(game.timer, game.NORMAL_FINISH_HOLD))
		var elapsed := 0.0
		while game.state == "settle":
			game._process(1.0 / fps)
			elapsed += 1.0 / fps
		assert(game.state == "results" and elapsed < 0.85)
	game._return_to_menu()
	print("PASS all landed skips first-landing deadline and shows results after 0.8s at 30/60/120 FPS")

func _check_cloud_continuity(game) -> void:
	game._reset_racers()
	game.state = "race"
	game.camera_alt = 0.0
	var before: Array[float] = []
	for i in range(7):
		before.append(game.toon_art.flight_cloud_y(i))
	for i in range(4):
		game.racers[i].alt = 0.0
		game.racers[i].speed = 2.0
		game._land(i)
	game._process(1.0 / 60.0)
	game._process(1.0 / 60.0)
	assert(game.state == "settle")
	for i in range(7):
		assert(is_equal_approx(before[i], game.toon_art.flight_cloud_y(i)), "Clouds must not jump when the camera switches to settled ground height")
	game._return_to_menu()
	print("PASS cloud positions stay continuous across landing and settled camera height")

func _check_race_clock_finish(game) -> void:
	for mode in ["race", "settle"]:
		game._reset_racers()
		game.state = mode
		game.camera_alt = game.CAMERA_LEAD_METRES
		game.timer = 2.0
		game.race_time = 7.0
		for i in range(3):
			game.racers[i].alt = 0.0
			game.racers[i].speed = 2.0
			game._land(i)
		game.racers[3].alt = 0.01
		game.racers[3].open = true
		game.racers[3].deploy = 1.0
		game.racers[3].speed = 2.0
		game._process(1.0 / 60.0)
		assert(game.finish_order.size() == 4)
		var stopped: float = game.race_time
		assert(stopped > 7.0 and is_equal_approx(stopped, game.racers[3].time))
		game._process(0.2)
		assert(is_equal_approx(game.race_time, stopped), "Race clock must stop after the last racer lands")
	game._reset_racers()
	assert(game.race_time == 0.0)
	game._return_to_menu()
	print("PASS race clock stops at final landing in race/settle and resets next round")
