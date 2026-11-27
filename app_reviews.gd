extends Node
## Native Play review card. Counters describe attempts, never submitted ratings.
const DAY := 86400
const REQUIRED_WIN_STREAK := 3
const SECOND_ATTEMPT_DAYS := 30
const LATER_ATTEMPT_DAYS := 60
var game: Node
var bridge: Object
var foreground := true
var session_seconds := 0.0
var podium_seconds := 0.0
var preparing := false
var prepare_seconds := 0.0
var attempted_session := false
var own_pause := false
var clock_override := -1

func now() -> int:
	return clock_override if clock_override >= 0 else int(Time.get_unix_time_from_system())

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = get_parent()
	if Engine.has_singleton("JellyChuteAppReview"):
		bridge = Engine.get_singleton("JellyChuteAppReview")


func eligible(at: int) -> bool:
	var data: Dictionary = game.review_data
	if at < int(data.get("retry_after", 0)): return false
	if int(data.get("win_streak", 0)) < REQUIRED_WIN_STREAK: return false
	var attempts := int(data.get("attempts", 0))
	if attempts > 0:
		var days := SECOND_ATTEMPT_DAYS if attempts == 1 else LATER_ATTEMPT_DAYS
		if at - int(data.get("last_attempt_at", at)) < days * DAY: return false
	return true

func busy() -> bool:
	return preparing or own_pause or (bridge != null and bridge.isFlowActive())

func safe_to_prompt() -> bool:
	if not foreground or game.state != "podium" or not game.tournament_paid: return false
	if get_tree().paused or session_seconds < 60.0 or podium_seconds < 4.0: return false
	var updates: Node = game.updates
	if updates != null:
		if is_instance_valid(updates.dialog) or updates.installing: return false
		if updates.bridge != null and (updates.bridge.isFlowActive() or updates.bridge.getUpdateState() > 0): return false
	return true

func _process(delta: float) -> void:
	if bridge == null: return
	if own_pause:
		if not bridge.isFlowActive():
			own_pause = false
			get_tree().paused = false
		return
	if foreground and not get_tree().paused:
		# Count foreground use, never elapsed background/wall time.
		var active := minf(delta, 1.0)
		session_seconds += active
		podium_seconds = podium_seconds + active if game.state == "podium" and game.tournament_paid else 0.0
	if preparing:
		prepare_seconds += delta
		if not safe_to_prompt():
			cancel_preparation()
			return
		var state: int = bridge.getReviewState()
		if state == 2:
			preparing = false
			if not eligible(now()):
				bridge.cancelRequest()
				return
			var previous: Dictionary = game.review_data.duplicate(true)
			game.review_data["attempts"] = int(previous.get("attempts", 0)) + 1
			game.review_data["last_attempt_at"] = now()
			game.review_data["win_streak"] = 0
			if game._save_record() != OK:
				game.review_data = previous
				bridge.cancelRequest()
				return
			own_pause = true
			get_tree().paused = true
			bridge.launchReview()
		elif state < 0 or prepare_seconds >= 10.0:
			cancel_preparation()
			game.review_data["retry_after"] = now() + DAY
			game._save_record()
	elif not attempted_session and safe_to_prompt() and eligible(now()):
		attempted_session = true
		preparing = true
		prepare_seconds = 0.0
		bridge.prepareReview()

func cancel_preparation() -> void:
	if preparing:
		preparing = false
		bridge.cancelRequest()

func _notification(what: int) -> void:
	if bridge == null or not is_instance_valid(game): return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		foreground = false
		podium_seconds = 0.0
		cancel_preparation()
		game._save_record()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		foreground = true
		podium_seconds = 0.0
