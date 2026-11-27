extends SceneTree
class FakePlay extends RefCounted:
	var state := 0
	var starts := 0
	var installs := 0
	var failed := false
	func getUpdateState() -> int: return state
	func didInstallFail() -> bool: return failed
	func startFlexibleUpdate() -> void: starts += 1
	func completeUpdate() -> void: installs += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.save_path = "user://update-test.dat"
	var updates = game.get_child(game.get_child_count() - 1)
	updates.set_process(false)
	var play := FakePlay.new()
	updates.bridge = play
	play.state = 1
	game.state = "race"
	updates.poll()
	assert(play.starts == 0)
	game.state = "menu"
	updates.poll()
	updates.poll()
	assert(play.starts == 1)
	play.state = 2
	game.state = "race"
	updates.poll()
	assert(updates.dialog == null)
	game.state = "menu"
	updates.poll()
	assert(is_instance_valid(updates.dialog))
	assert(not game.is_processing_unhandled_input())
	game.save_blocked = true
	updates.install()
	assert(play.installs == 0)
	game.save_blocked = false
	updates.install()
	assert(play.installs == 1)
	updates.install()
	assert(play.installs == 1)
	play.failed = true
	updates.poll()
	assert(not updates.install_button.disabled)
	play.failed = false
	updates.message.text = "Your update is packed and ready.\nRestart JellyChute to jump back in!"
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://work/update-ready.png") == OK)
	var panel = updates.dialog.get_child(1)
	panel.get_child(panel.get_child_count() - 1).pressed.emit()
	assert(updates.dialog == null and game.is_processing_unhandled_input())
	updates.poll()
	assert(updates.dialog == null)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("PASS: consent once; race deferral; save guard; install retry; later; screenshot")
	quit()
