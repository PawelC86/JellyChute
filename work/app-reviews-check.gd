extends SceneTree
class FakeReview extends RefCounted:
	var state := 0
	var active := false
	var prepares := 0
	var launches := 0
	var cancels := 0
	func getReviewState() -> int: return state
	func isFlowActive() -> bool: return active
	func prepareReview() -> void:
		prepares += 1
		state = 1
	func cancelRequest() -> void:
		cancels += 1
		state = 0
	func launchReview() -> void:
		launches += 1
		active = true
class FakeUpdates extends Node:
	var dialog: Control
	var installing := false
	var bridge: Object
class FakeGame extends Node:
	var review_data: Dictionary = {"win_streak": 3}
	var state := "podium"
	var tournament_paid := true
	var updates: Node
	var save_result := OK
	var saves := 0
	func _save_record() -> int:
		saves += 1
		return save_result
func _initialize() -> void:
	call_deferred("run")
func reset_review(controller: Node, game: Node, play: RefCounted) -> void:
	game.review_data = {"win_streak": 3}
	game.state = "podium"
	game.tournament_paid = true
	game.save_result = OK
	controller.attempted_session = false
	controller.preparing = false
	controller.session_seconds = 60.0
	controller.podium_seconds = 4.0
	play.state = 0
	play.active = false
func run() -> void:
	var game := FakeGame.new()
	root.add_child(game)
	var controller = load("res://app_reviews.gd").new()
	game.add_child(controller)
	controller.set_process(false)
	var play := FakeReview.new()
	controller.bridge = play
	controller.clock_override = 100 * 86400
	reset_review(controller, game, play)
	game.review_data.win_streak = 2
	assert(not controller.eligible(controller.now()))
	game.review_data.win_streak = 3
	assert(controller.eligible(controller.now()))
	for attempts in [1, 2, 3, 10]:
		var days := 30 if attempts == 1 else 60
		game.review_data = {"win_streak": 3, "attempts": attempts, "last_attempt_at": 100 * 86400}
		assert(not controller.eligible((100 + days) * 86400 - 1))
		assert(controller.eligible((100 + days) * 86400))
		assert(not controller.eligible(99 * 86400))
	print("PASS first request after 3 wins; 30/60-day boundaries; no lifetime cap; clock rollback")
	reset_review(controller, game, play)
	game.state = "race"
	controller._process(0)
	assert(play.prepares == 0)
	game.state = "podium"
	controller.podium_seconds = 3.9
	controller._process(0)
	assert(play.prepares == 0)
	controller.podium_seconds = 4.0
	controller._process(0)
	assert(play.prepares == 1)
	play.state = 2
	controller._process(0)
	assert(play.launches == 1 and paused)
	assert(game.review_data.attempts == 1 and game.review_data.win_streak == 0)
	play.active = false
	controller._process(0)
	assert(not paused)
	game.review_data.win_streak = 3
	controller._process(0)
	assert(play.prepares == 1)
	print("PASS podium-only/dwell; persist before launch; pause/resume; once per process")
	reset_review(controller, game, play)
	controller._process(0)
	play.state = 2
	game.save_result = ERR_CANT_CREATE
	controller._process(0)
	assert(play.launches == 1 and not paused)
	assert(game.review_data == {"win_streak": 3})
	reset_review(controller, game, play)
	controller._process(0)
	game.state = "race"
	controller._process(0)
	assert(not controller.preparing and play.state == 0)
	reset_review(controller, game, play)
	controller._process(0)
	controller.prepare_seconds = 10
	controller._process(0)
	assert(not controller.preparing and game.review_data.retry_after == controller.now() + 86400)
	print("PASS save failure rollback; stale preparation cancelled; timeout/day backoff")
	reset_review(controller, game, play)
	var updates := FakeUpdates.new()
	game.add_child(updates)
	game.updates = updates
	updates.dialog = Control.new()
	game.add_child(updates.dialog)
	assert(not controller.safe_to_prompt())
	updates.dialog.queue_free()
	await process_frame
	controller._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert(not controller.foreground and not controller.safe_to_prompt())
	controller._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert(controller.foreground and controller.podium_seconds == 0)
	print("PASS update dialog priority and background/resume guard")
	game.queue_free()
	await process_frame
	var fixture = preload("res://work/save_fixture.gd").new()
	var actual = load("res://main.tscn").instantiate()
	actual.hide()
	actual.save_path = "user://review-check.dat"
	actual.legacy_save_path = "user://review-check-legacy.cfg"
	root.add_child(actual)
	actual.set_process(false)
	actual.review_data = {}
	for expected in range(1, 4):
		actual.state = "podium"
		actual.rounds_completed = 3
		actual.round_number = 3
		actual.tournament_paid = false
		actual.totals.assign([30, 20, 10, 0])
		actual._settle_tournament()
		assert(actual.review_data.win_streak == expected)
		actual._settle_tournament()
		assert(actual.review_data.completed_tournaments == expected)
	actual.review_data.attempts = 2
	actual.review_data.last_attempt_at = 12345678
	assert(actual._save_record() == OK)
	var reloaded = load("res://main.tscn").instantiate()
	reloaded.hide()
	reloaded.save_path = actual.save_path
	reloaded.legacy_save_path = actual.legacy_save_path
	root.add_child(reloaded)
	reloaded.set_process(false)
	assert(reloaded.review_data.win_streak == 3 and reloaded.review_data.attempts == 2 and reloaded.review_data.last_attempt_at == 12345678)
	actual.tournament_paid = false
	actual.totals.assign([0, 30, 20, 10])
	actual._settle_tournament()
	assert(actual.review_data.win_streak == 0)
	actual.tournament_paid = false
	actual.totals.assign([30, 20, 10, 0])
	actual.save_blocked = true
	var previous: Dictionary = actual.review_data.duplicate()
	actual._settle_tournament()
	assert(actual.review_data == previous and not actual.tournament_paid)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(actual.save_path))
	fixture.restore()
	actual.queue_free()
	reloaded.queue_free()
	await process_frame
	print("PASS win/loss streak; exactly-once tournament count; encrypted reload; transaction rollback")
	quit()
