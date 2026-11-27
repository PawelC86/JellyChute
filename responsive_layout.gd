extends RefCounted
## Uniform art scale, expandable scenery and safe-area anchors.
var game: Node2D
var safe_rect := Rect2(0, 0, 540, 960)
var extra_height := 0.0
var extra_width := 0.0

func _init(owner_game: Node2D) -> void:
	game = owner_game

func update() -> void:
	var viewport := game.get_viewport()
	var bounds := viewport.get_visible_rect()
	safe_rect = bounds
	if OS.get_name() == "Android":
		var physical := DisplayServer.get_display_safe_area()
		if physical.size.x > 0 and physical.size.y > 0:
			var inverse := viewport.get_screen_transform().affine_inverse()
			var usable := Rect2(inverse * Vector2(physical.position), Vector2(physical.size) / viewport.get_screen_transform().get_scale())
			var clipped := bounds.intersection(usable)
			if clipped.size.x > 0 and clipped.size.y > 0:
				safe_rect = clipped
	apply_bounds(safe_rect)

func apply_bounds(bounds: Rect2) -> void:
	safe_rect = bounds
	var factor := minf(bounds.size.x / 540.0, bounds.size.y / 960.0)
	extra_height = maxf(0, bounds.size.y / factor - 960.0)
	extra_width = maxf(0, bounds.size.x / factor - 540.0)
	game.scale = Vector2.ONE * factor
	game.position = bounds.get_center() - Vector2(270, 480) * factor
	if is_instance_valid(game.ui):
		var layer := game.ui.get_parent() as CanvasLayer
		layer.offset = game.position
		layer.scale = game.scale

func apply_ui() -> void:
	var lower := extra_height * 0.5
	var menu: bool = game.state == "menu"
	for button in game.menu_side_buttons:
		button.position.y = 746 + lower
	for tab in game.shop_tabs:
		tab.position.y = 190 - lower
	for button in game.character_buttons:
		button.position.y = 479
	for button in game.chute_buttons:
		button.position.y = 346
	if menu:
		game.action.position.y = 822 + lower
	elif game.state in ["results", "podium"]:
		game.action.position.y = 866 + lower
		game.home_button.position.y += lower
	else:
		game.action.position.y = 852 + lower
		game.home_button.position.y -= lower

func background_rect() -> Rect2:
	var bounds := game.get_viewport_rect()
	return Rect2(-game.position / game.scale, bounds.size / game.scale)
