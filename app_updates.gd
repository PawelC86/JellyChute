extends Node
## Google Play flexible updates; gameplay is never interrupted by a restart.
var bridge: Object
var game: Node
var consent_offered := false
var restart_offered := false
var elapsed := 0.0
var dialog: Control
var message: Label
var install_button: Button
var installing := false
var restart_panel: Panel

func _ready() -> void:
	game = get_parent()
	if Engine.has_singleton("JellyChuteAppUpdates"):
		bridge = Engine.get_singleton("JellyChuteAppUpdates")
		bridge.checkForUpdate()

func _process(delta: float) -> void:
	if is_instance_valid(restart_panel):
		layout_dialog()
	elapsed += delta
	if elapsed >= 0.5:
		elapsed = 0.0
		poll()

func poll() -> void:
	if bridge == null: return
	if installing and bridge.didInstallFail():
		installing = false
		install_button.disabled = false
		message.text = "Couldn't restart. Please try again."
	if game.reviews != null and game.reviews.busy(): return
	if is_instance_valid(dialog) or game.state != "menu": return
	if bridge.getUpdateState() == 2 and not restart_offered:
		restart_offered = true
		show_restart_dialog()
	elif bridge.getUpdateState() == 1 and not consent_offered:
		consent_offered = true
		bridge.startFlexibleUpdate()

func show_restart_dialog() -> void:
	if is_instance_valid(dialog): return
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	dialog = Control.new()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dialog)
	var shade := ColorRect.new()
	shade.color = Color(0.12, 0.07, 0.18, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(shade)
	var panel := Panel.new()
	restart_panel = panel
	panel.position = Vector2(40, 175)
	panel.size = Vector2(460, 626)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff4dc")
	style.border_color = Color("51243e")
	style.set_border_width_all(4)
	style.set_corner_radius_all(36)
	style.shadow_color = Color("210f3270")
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 12)
	panel.add_theme_stylebox_override("panel", style)
	dialog.add_child(panel)
	layout_dialog()
	game.set_process_unhandled_input(false)
	add_texture(panel, preload("res://assets/toon/update-mango.png"), Rect2(50, 40, 360, 201))
	var title := add_label(panel, "Fresh drop.\nMore wobble!", 24, 286, 412, 94, 37)
	title.add_theme_font_override("font", game.toon_art.bold)
	title.add_theme_constant_override("line_spacing", -3)
	message = add_label(panel, "Your update is packed and ready.\nRestart JellyChute to jump back in!", 35, 388, 390, 62, 19)
	message.add_theme_color_override("font_color", Color("8a6476"))
	var reassurance := add_label(panel, "PROGRESS SAVED BEFORE RESTART", 30, 459, 400, 20, 11)
	reassurance.add_theme_color_override("font_color", Color("947a7f"))
	install_button = add_button(panel, "RESTART & LET'S FLY!", 494, Color("ffce57"))
	install_button.pressed.connect(install)
	install_button.grab_focus()
	var later := add_button(panel, "Maybe later", 565, Color("fff4dc"))
	later.size.y = 38
	later.add_theme_font_size_override("font_size", 17)
	var quiet := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed"]:
		later.add_theme_stylebox_override(state, quiet)
	later.pressed.connect(func():
		if not installing:
			layer.queue_free()
			dialog = null
			game.set_process_unhandled_input(true))

func layout_dialog() -> void:
	var bounds: Rect2 = game.responsive.safe_rect
	var factor := minf(bounds.size.x / 540.0, bounds.size.y / 960.0)
	restart_panel.scale = Vector2.ONE * factor
	restart_panel.position = bounds.get_center() - restart_panel.size * factor * 0.5

func add_texture(parent: Control, texture: Texture2D, bounds: Rect2) -> void:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.position = bounds.position
	image.size = bounds.size
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)

func add_label(parent: Control, text: String, x: float, y: float, w: float, h: float, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(x, y)
	label.size = Vector2(w, h)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("593850"))
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label

func add_button(parent: Control, text: String, y: float, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.position = Vector2(30, y)
	button.size = Vector2(400, 60)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(20)
	style.border_color = Color("9e653d")
	style.set_border_width_all(2)
	style.border_width_bottom = 5
	style.shadow_color = Color("b8813b26")
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 4)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.06)
	pressed.border_width_bottom = 2
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("593850"))
	button.add_theme_color_override("font_focus_color", Color("593850"))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = Color("72465f")
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(18)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_font_override("font", game.toon_art.bold)
	parent.add_child(button)
	return button

func install() -> void:
	if installing or bridge == null: return
	if game._save_record() != OK:
		message.text = "Couldn't save your progress.\nPlease try again before restarting."
		return
	installing = true
	install_button.disabled = true
	message.text = "Restarting with the new update..."
	bridge.completeUpdate()
