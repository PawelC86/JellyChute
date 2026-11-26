extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func outcome(game, safe: bool, place: int, margin := 1.0) -> void:
	game.racers[0].safe = safe
	game.racers[0].deploy_speed = game.TERMINAL
	game.racers[0].deploy_altitude = game.braking_distance(game.TERMINAL) + margin
	game._learn_player_round(place)

func run_checks() -> void:
	var fixture = preload("res://work/save_fixture.gd").new()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.save_path = "user://adaptive-v2-check.dat"
	game.legacy_save_path = "user://adaptive-v2-check.cfg"
	game.player_skill = 0.5
	game.long_term_skill = 0.5
	game.learned_rounds = 0
	game.failure_streak = 0
	game.recent_performance.clear()
	for trial in range(24):
		var before: float = game.player_skill
		outcome(game, true, 0)
		assert(game.player_skill >= before and game.player_skill - before <= 0.050001)
	assert(game.player_skill > 0.85)
	var peak: float = game.player_skill
	outcome(game, false, 3)
	assert(peak - game.player_skill <= 0.035001)
	for trial in range(8):
		var before: float = game.player_skill
		outcome(game, false, 3)
		assert(before - game.player_skill <= 0.080001)
	assert(game.player_skill < peak - 0.4)
	var low: float = game.player_skill
	for trial in range(24):
		outcome(game, true, 0)
	assert(game.player_skill > low + 0.4)
	assert(game.recent_performance.size() == 12 and game.failure_streak == 0)
	print("PASS bounded difficulty changes, single-loss tolerance, loss streak relief, recovery and 12-result history")

	game.credits = 1234
	game.career_points = 5678
	game.wins = 42
	game.best_time = 7.25
	game.character_confirmed = true
	game.owned_characters.assign([0, 1, 2, 3, 4])
	game.owned_chutes.assign([0, 1, 2, 3, 5])
	game.selected_character = 4
	game.selected_chute = 5
	assert(game._save_record() == OK)
	var history = game.recent_performance.duplicate()
	var skill: float = game.player_skill
	var long_term: float = game.long_term_skill
	var count: int = game.learned_rounds
	var raw := FileAccess.get_file_as_bytes(game.save_path)
	assert(raw.slice(0, 4).get_string_from_ascii() == "GDEC")
	assert(not raw.get_string_from_ascii().contains("recent_performance"))

	game.player_skill = 0.0
	game.recent_performance.clear()
	game.credits = 0
	game._load_record()
	assert(game.recent_performance.size() == history.size() and is_equal_approx(game.player_skill, skill))
	for index in range(history.size()):
		assert(is_equal_approx(game.recent_performance[index], history[index]))
	assert(is_equal_approx(game.long_term_skill, long_term) and game.learned_rounds == count)
	assert(game.credits == 1234 and game.career_points == 5678 and game.wins == 42)
	assert(game.best_time == 7.25 and game.selected_character == 4 and game.selected_chute == 5)
	assert(game.owns_character(4) and game.owns_chute(5))
	print("PASS encrypted roundtrip of adaptive history, records, wallet, ownership and selections")

	# Also remove stale plaintext when an authoritative encrypted save exists.
	var legacy := ConfigFile.new()
	legacy.set_value("records", "wins", 1)
	assert(legacy.save(game.legacy_save_path) == OK)
	game._load_record()
	assert(game.wins == 42 and not FileAccess.file_exists(game.legacy_save_path))
	# Older encrypted profiles retain learned skill and gain empty v2 history.
	legacy.set_value("adaptive", "skill", 0.72)
	legacy.set_value("adaptive", "rounds", 19)
	assert(legacy.save_encrypted_pass(game.save_path, game.SAVE_PASSWORD) == OK)
	game._load_record()
	assert(is_equal_approx(game.player_skill, 0.72) and is_equal_approx(game.long_term_skill, 0.72))
	assert(game.learned_rounds == 19 and game.recent_performance.is_empty())
	print("PASS old encrypted profile migration and stale plaintext cleanup")

	# Learning is durable as soon as landing happens, before results or rewards.
	game._reset_racers()
	game.state = "race"
	game.racers[0].open = true
	game.racers[0].deploy_altitude = 18.0
	game.racers[0].deploy_speed = game.TERMINAL
	game.racers[0].speed = 2.0
	game.race_time = 8.0
	game._land(0)
	var after_landing: int = game.learned_rounds
	assert(after_landing == 20 and game.round_learned)
	var decoded := ConfigFile.new()
	assert(decoded.load_encrypted_pass(game.save_path, game.SAVE_PASSWORD) == OK)
	assert(decoded.get_value("adaptive", "rounds") == after_landing)
	game._record_player_round(0)
	assert(game.learned_rounds == after_landing)
	game._return_to_menu()
	game._load_record()
	assert(game.learned_rounds == after_landing)
	print("PASS immediate landing autosave, no duplicate learning and retention after abandoning tournament")

	# A failed replacement must leave only an encrypted temporary save.
	var original_path: String = game.save_path
	game.save_path = "user://adaptive-v2-blocked"
	assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(game.save_path)) == OK)
	assert(game._save_record() != OK)
	assert(FileAccess.get_file_as_bytes(game.save_path + ".tmp").slice(0, 4).get_string_from_ascii() == "GDEC")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path + ".tmp"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.save_path = original_path
	print("PASS temporary save stays encrypted even when replacement fails")
	for path in [game.save_path, game.save_path + ".tmp", game.legacy_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	fixture.restore()
	game.queue_free()
	await process_frame
	quit()
