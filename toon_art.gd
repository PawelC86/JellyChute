extends RefCounted
## Cartoon renderer matching the user-supplied inked reference.
var game_ref: WeakRef
var portrait_target: Node2D
var shop_portrait_clips: Array[Control] = []
var shop_buy_buttons: Array[Button] = []
var shop_chute_buttons: Array[Button] = []
var g: Node2D:
	get:
		if is_instance_valid(portrait_target):
			return portrait_target
		return game_ref.get_ref() as Node2D
var bodies: Array[Texture2D] = []
var canopies: Array[Texture2D] = []
var arms: Array[Texture2D] = []
var boots: Array[Texture2D] = []
var collection_regions: Dictionary = {}
var collection_heads: Array[Texture2D] = []
var collection_extras: Array[Texture2D] = []
const COLLECTION_IDS := ["cat", "dog", "dragon", "bling", "bee", "unicorn", "robot", "ghost", "chef"]
const HEAD_RECTS := [Rect2(-22, -87, 44, 28), Rect2(-35, -85, 70, 40), Rect2(-26, -94, 52, 34), Rect2(-26, -98, 66, 35), Rect2(-20, -99, 40, 35), Rect2(-24, -101, 48, 39), Rect2(-24, -93, 48, 34), Rect2(-12, -91, 24, 26), Rect2(-29, -109, 58, 46)]
# Seat each painted headpiece into the scalp, rather than above the forehead.
const HEAD_SEAT_Y := [-67.0, -67.0, -62.0, -59.0, -67.0, -62.0, -67.0, -67.0, -61.0]
var props: Array[Texture2D] = []
var landscape: Texture2D
var sky: Texture2D
var logo: Texture2D
var menu_decor: Array[Texture2D] = []

var bold: FontVariation
var ui_mode := ""
var secure_style: StyleBoxFlat
var danger_style: StyleBoxFlat
const INK := Color("401333")
const CREAM := Color("fff1d0")
const CORAL := Color("ffca39")

func _init(game: Node2D) -> void:
	game_ref = weakref(game)
	var actors := _actor_atlas()
	for i in range(4):
		bodies.append(actors[i])
		canopies.append(actors[4 + i])
		arms.append(actors[8 + i])
		boots.append(actors[12 + i])
	collection_regions = preload("res://assets/toon/collection/atlas_regions.gd").REGIONS
	for id in COLLECTION_IDS:
		var pieces := _collection_atlas("res://assets/toon/collection/%s.png" % id)
		bodies.append(pieces[0])
		collection_heads.append(pieces[1])
		arms.append(pieces[2])
		boots.append(actors[12])
		collection_extras.append(pieces[3])
	for id in game.CHUTE_IDS:
		canopies.append(load("res://assets/toon/chutes/%s.png" % id) as Texture2D)
	props = _atlas("res://assets/toon/props.png", 3, 3)
	landscape = load("res://assets/toon/landscape.png") as Texture2D
	sky = load("res://assets/toon/sky.png") as Texture2D
	logo = load("res://assets/toon/logo.png") as Texture2D
	menu_decor = _atlas("res://assets/toon/menu-frame.png", 2, 1)
	bold = FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 1.2
	bold.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.18, 1), Vector2.ZERO)

func _collection_atlas(path: String) -> Array[Texture2D]:
	var texture := load(path) as Texture2D
	var result: Array[Texture2D] = []
	for bounds in collection_regions[path.get_file().get_basename()]:
		var part := AtlasTexture.new()
		part.atlas = texture
		part.region = Rect2(bounds[0], bounds[1], bounds[2], bounds[3])
		part.filter_clip = true
		result.append(part)
	return result

func _actor_atlas() -> Array[Texture2D]:
	# The painted sheet is not a uniform grid: canopies straddle column seams.
	# Independent bounds retain every scallop and exclude neighbouring artwork.
	var regions := [
		Rect2i(44, 57, 261, 296), Rect2i(342, 56, 265, 297),
		Rect2i(643, 56, 264, 298), Rect2i(942, 56, 267, 297),
		Rect2i(24, 418, 298, 239), Rect2i(326, 418, 294, 237),
		Rect2i(625, 418, 297, 237), Rect2i(927, 418, 302, 238),
		Rect2i(108, 727, 130, 252), Rect2i(411, 727, 123, 252),
		Rect2i(718, 727, 122, 253), Rect2i(1023, 726, 120, 257),
		Rect2i(86, 1064, 154, 141), Rect2i(388, 1061, 156, 146),
		Rect2i(690, 1063, 155, 144), Rect2i(991, 1061, 161, 147)
	]
	var texture := load("res://assets/toon/actors.png") as Texture2D
	var result: Array[Texture2D] = []
	for region in regions:
		var part := AtlasTexture.new()
		part.atlas = texture
		part.region = Rect2(region.grow(1))
		part.filter_clip = true
		result.append(part)
	return result

func _atlas(path: String, columns: int, rows: int) -> Array[Texture2D]:
	var texture := load(path) as Texture2D
	var image := texture.get_image()
	var result: Array[Texture2D] = []
	var cell := Vector2i(image.get_width() / columns, image.get_height() / rows)
	for row in range(rows):
		for column in range(columns):
			var row_start := row * cell.y
			var row_end := (row + 1) * cell.y
			if rows == 4:
				var edges := [0.0, 0.30, 0.54, 0.79, 1.0]
				row_start = int(edges[row] * image.get_height())
				row_end = int(edges[row + 1] * image.get_height())
			var origin := Vector2i(column * cell.x, row_start)
			var piece := image.get_region(Rect2i(origin, Vector2i(cell.x, row_end - row_start)))
			var used := _solid_bounds(piece)
			var part := AtlasTexture.new()
			part.atlas = texture
			part.region = Rect2(origin + used.position, used.size)
			part.filter_clip = true
			result.append(part)
	return result

func _solid_bounds(image: Image) -> Rect2i:
	# Select the main continuous band, excluding atlas-edge fragments from neighbours.
	var best := Rect2i()
	var best_area := 0
	var run_area := 0
	var run_left := image.get_width()
	var run_right := 0
	var run_top := 0
	for y in range(image.get_height() + 1):
		var count := 0
		var row_left := image.get_width()
		var row_right := 0
		if y < image.get_height():
			for x in range(image.get_width()):
				if image.get_pixel(x, y).a > 0.55:
					count += 1
					row_left = mini(row_left, x)
					row_right = maxi(row_right, x)
		if count > image.get_width() * 0.06:
			if run_area == 0:
				run_top = y
			run_area += count
			run_left = mini(run_left, row_left)
			run_right = maxi(run_right, row_right)
		else:
			if run_area > best_area:
				best_area = run_area
				best = Rect2i(run_left, run_top, run_right - run_left + 1, y - run_top)
			run_area = 0
			run_left = image.get_width()
			run_right = 0
	return best.grow(2).intersection(Rect2i(Vector2i.ZERO, image.get_size())) if best_area > 0 else image.get_used_rect()

func button_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = props[8]
	style.texture_margin_left = 0
	style.texture_margin_right = 0
	style.texture_margin_top = 0
	style.texture_margin_bottom = 0
	style.modulate_color = tint
	return style

func configure_ui() -> void:
	configure_shop_portraits()
	secure_style = _flight_button_style(Color("8ee1c2"))
	danger_style = _flight_button_style(Color("ff8f96"))
	g.action.add_theme_stylebox_override("normal", button_style())
	g.action.add_theme_stylebox_override("hover", button_style(Color("fff7e9")))
	g.action.add_theme_stylebox_override("pressed", button_style(Color("e8c5b0")))
	g.action.add_theme_stylebox_override("disabled", button_style(Color("d9c7b9")))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		g.action.add_theme_color_override(key, INK)
	g.action_hint.add_theme_font_override("font", bold)
	g.action_hint.add_theme_color_override("font_color", INK)
	g.action.add_theme_font_override("font", bold)
	g.action.add_theme_font_size_override("font_size", 23)
	for arrow in g.character_buttons + g.chute_buttons:
		arrow.add_theme_font_override("font", bold)
		for key in ["font_color", "font_hover_color", "font_pressed_color"]:
			arrow.add_theme_color_override(key, INK)
		arrow.add_theme_stylebox_override("normal", _flight_button_style(CREAM))
		arrow.add_theme_stylebox_override("hover", _flight_button_style(CORAL))
		arrow.add_theme_stylebox_override("pressed", _flight_button_style(Color("ffb86b")))
	for tab in g.shop_tabs:
		tab.add_theme_font_override("font", bold)
		tab.add_theme_font_size_override("font_size", 21)
		for key in ["font_color", "font_hover_color", "font_pressed_color"]:
			tab.add_theme_color_override(key, INK)
		tab.add_theme_stylebox_override("hover", _flight_button_style(Color("ffe49b")))
		tab.add_theme_stylebox_override("pressed", _flight_button_style(Color("ffb86b")))
	for button in g.menu_side_buttons:
		button.add_theme_stylebox_override("normal", _flight_button_style(CREAM))
		button.add_theme_stylebox_override("hover", _flight_button_style(CORAL))
		button.add_theme_stylebox_override("pressed", _flight_button_style(Color("ffb86b")))
	for label in [g.heading, g.detail, g.badge]:
		label.add_theme_color_override("font_color", INK)
	g.heading.add_theme_font_override("font", bold)
	g.badge.add_theme_font_override("font", bold)
	g.stats.add_theme_color_override("font_color", INK)
	g.home_button.add_theme_font_override("font", bold)
	g.home_button.add_theme_font_size_override("font_size", 13)
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		g.home_button.add_theme_color_override(key, INK)
	g.home_button.add_theme_stylebox_override("normal", _flight_button_style(CREAM))
	g.home_button.add_theme_stylebox_override("hover", _flight_button_style(Color("ffe49b")))
	g.home_button.add_theme_stylebox_override("pressed", _flight_button_style(Color("ffd181")))

func render() -> void:
	if g.state == "shop":
		render_shop()
		return
	if g.state == "menu":
		render_menu()
		return
	if g.state in ["results", "podium"]:
		render_celebration()
		return
	var flight: bool = g.state in ["race", "settle", "countdown"]
	g.draw_rect(g.responsive.background_rect(), Color("28bee0"))
	g.draw_texture_rect(sky, g.responsive.background_rect(), false, Color.WHITE)
	# The reference uses an open turquoise sky rather than a paper sun.
	for i in range(7):
		var y: float = flight_cloud_y(i)
		if flight or y > 410:
			cloud(Vector2(float((i * 191 + 45) % 540), y), 0.65 + float(i % 3) * 0.22)
	var ground: float = g._ground_y() if flight else 760.0
	if ground < 1250:
		var screen: Rect2 = g.responsive.background_rect()
		var cover := maxf(1.0, maxf(screen.size.x / 540.0, (screen.end.y - ground) / 280.0))
		_sprite(landscape, Rect2((540.0 - 540.0 * cover) * 0.5, ground - 500.0 * cover, 540.0 * cover, 780.0 * cover))
	if flight:
		g._draw_flight_world()
		if g.state == "countdown" or (g.state == "race" and g.race_time < 2):
			var offset: float = (g.start_altitude - g.camera_alt) * g.PIXELS_PER_METRE
			launch_platform(396 - offset)
		for i in range(4):
			var x: float = g._lane_x(i)
			pad(Vector2(x, ground), i)
			var feet: Vector2 = g._racer_feet(i)
			if feet.y >= 145 and feet.y < 780:
				jelly(feet, i, true, false, g.RACER_SCALE)
				if not g.racers[i].done:
					pill(Vector2(x, feet.y + 20), g.NAMES[i], i == 0)
				else:
					pill(Vector2(x, feet.y + 24), "#%d %s" % [g._ranked().find(i) + 1, g.NAMES[i]], i == 0)
			elif feet.y < 145 and g.state != "settle":
				pill(Vector2(x, 168), g.NAMES[i] + " ↑", i == 0)
			elif not g.racers[i].done:
				pill(Vector2(x, 746), g.NAMES[i] + " ↓", i == 0)

	else:
		if g.state == "menu":
			jelly(Vector2(270, 695), 0, false, true, 1.45)
			for i in range(1, 4):
				jelly(Vector2(150 + (i - 1) * 120, 750), i, false)
		elif g.state == "podium":
			var order: Array[int] = [0, 1, 2, 3]
			order.sort_custom(func(a,b): return g.totals[a] > g.totals[b] if g.totals[a] != g.totals[b] else g.order_tiebreak(a) < g.order_tiebreak(b))
			for rank in range(3):
				var x: float = [270.0, 130.0, 410.0][rank]
				var top: float = [677.0, 715.0, 738.0][rank]
				ink_box(Rect2(x - 47, top, 94, 785 - top), Color("e9c075"), 8)
				text_at(Vector2(x, top + 30), str(rank + 1), 22, INK)
				jelly(Vector2(x, top), order[rank], false)
		else:
			for i in range(4):
				jelly(Vector2(95 + i * 115, 748), i, true)
		if g.state != "menu":
			ink_box(Rect2(27, 215, 486, 355), CREAM, 24)
	if flight:
		draw_race_hud()
	else:
		ink_box(Rect2(20, 20, 188, 48), CREAM, 23)
		ink_box(Rect2(24, 782, 492, 68), CREAM, 21)
	draw_dust()
	for p in g.particles:
		g._star(p.pos + Vector2(0, g._ground_y()), 4, Color("edc270"))

func flight_cloud_y(index: int) -> float:
	# Use the same clamped camera height as the ground and world objects.
	# Once the camera reaches ground, settling must not shift the cloud layer.
	var camera_height: float = maxf(g.camera_alt - g.CAMERA_LEAD_METRES, 0.0)
	var start_height: float = maxf(g.start_altitude - g.CAMERA_LEAD_METRES, 0.0)
	return fposmod(float(index * 183) - (start_height - camera_height) * g.PIXELS_PER_METRE * 0.10, 1150.0) - 80.0

func ink_box(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = INK
	style.set_border_width_all(3 if rect.size.y > 30 else 2)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color("40133390")
	style.shadow_offset = Vector2(1, 3)
	style.shadow_size = 1
	g.draw_style_box(style, rect)
	if rect.size.y > 38:
		g.draw_line(rect.position + Vector2(radius, 5), rect.position + Vector2(rect.size.x - radius, 5), color.lightened(0.3), 2, true)

func pill(center: Vector2, content: String, player: bool) -> void:
	var width := bold.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 22
	ink_box(Rect2(center - Vector2(width / 2, 12), Vector2(width, 24)), Color("f2c1b6") if player else CREAM, 12)
	text_at(center, content, 12, INK)

func text_at(center: Vector2, content: String, size: int, color: Color) -> void:
	var width := bold.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	g.draw_string(bold, center + Vector2(-width / 2, size * 0.32), content, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _sprite(texture: Texture2D, rect: Rect2, tint: Color = Color.WHITE) -> void:
	g.draw_texture_rect(texture, rect, false, tint)

func cloud(pos: Vector2, size: float) -> void:
	var texture: Texture2D = props[0] if int(pos.x) % 2 == 0 else props[1]
	_sprite(texture, Rect2(pos - Vector2(68, 32) * size, Vector2(136, 64) * size))

func pad(feet: Vector2, i: int) -> void:
	# Resolve the actual participant, including every premium character.
	var color: Color = g.CHARACTER_COLORS[g.racer_skins[i]]
	# A dark ink rim and shaded side retain the original low oval silhouette.
	g._ellipse(feet + Vector2(0, 17), Vector2(46, 11), Color("40133330"))
	g._ellipse(feet + Vector2(0, 10), Vector2(44, 15), INK)
	g._ellipse(feet + Vector2(0, 10), Vector2(41, 12), color.darkened(0.28))
	g._ellipse(feet + Vector2(0, 1), Vector2(44, 10), INK)
	g._ellipse(feet + Vector2(0, 1), Vector2(41, 7), color)
	g._ellipse(feet + Vector2(-16, -1), Vector2(12, 1.6), color.lightened(0.4))

func jelly(feet: Vector2, i: int, flight: bool, hero: bool = false, size: float = 1.25) -> void:
	var r: Dictionary = g.racers[i]
	var skin: int = g.racer_skins[i]
	var wind := clampf(float(r.speed) / g.TERMINAL, 0, 1) if flight and g.state == "race" and not r.done else 0.0
	var clock: float = g.animation_time * (5 + wind * 14) + i
	var finished: bool = r.done and g.state in ["race", "settle", "results", "podium"]
	var celebration: bool = not flight and g.state in ["results", "podium"]
	var finale: bool = celebration and g.state == "podium"
	var proud: bool = flight and finished and r.safe and r.finish_age > 0.4 and r.finish_age < 2.8
	var podium_rank: int = g.reaction_order().find(i) if celebration else -1
	var conflict := fposmod(g.podium_dialogue_time, 12.0)
	var reaction := reaction_for(i) if finished or celebration else ""
	var crashed: bool = finished and not r.safe and g.state != "podium"
	var stretch := Vector2(1 + sin(clock) * 0.018, 1.0)
	stretch.y = 1.0 / stretch.x
	if flight and g.state == "race" and not r.open and not r.done:
		stretch = Vector2(1 - wind * 0.1 + sin(clock) * wind * 0.02, 1 + wind * 0.12)
	if finished:
		stretch = g._landing_stretch(r.squash, r.safe)
		if r.safe and r.squash < 0.05:
			match reaction:
				"champion": stretch = Vector2(1.0 + sin(r.finish_age * 8) * 0.035, 1.0 - sin(r.finish_age * 8) * 0.035)
				"runner_up": stretch = Vector2(1.0, 1.0 + sin(r.finish_age * 5) * 0.015)
				"relieved": stretch = Vector2(1.0, 0.98 + sin(r.finish_age * 3) * 0.02)
				"disappointed": stretch = Vector2(1.04, 0.93)
	var lean: float = sin(clock * 0.5) * wind * 0.025
	if g.state == "menu":
		lean = sin(g.animation_time * 1.3 + i) * 0.045 + g.carousel_direction * sin(clampf(g.carousel_time / g.CAROUSEL_DURATION, 0, 1) * TAU) * 0.13
	if finished and r.safe and r.squash < 0.05:
		lean = -0.045 if reaction == "disappointed" else sin(r.finish_age * 4) * 0.02
	if celebration:
		var pose := podium_pose(g.reaction_order().find(i), g.animation_time)
		feet += pose.offset
		lean = pose.lean
		stretch = pose.stretch
		if finale and podium_rank == 1 and conflict > 3.0 and conflict < 5.5:
			var reach := sin((conflict - 3.0) / 2.5 * PI)
			feet += Vector2(reach * 14, -reach * 15)
			stretch = Vector2(1.0 - reach * 0.08, 1.0 + reach * 0.18)
			lean = reach * 0.12
		if finale and podium_rank == 0 and conflict > 4.5 and conflict < 6.0:
			lean = -sin((conflict - 4.5) / 1.5 * PI) * 0.22
	if proud:
		var puff: float = sin(clampf((r.finish_age - 0.4) / 2.4, 0, 1) * PI)
		stretch = Vector2(1 + puff * 0.1, 1 + puff * 0.08)
		lean = sin(r.finish_age * 4) * 0.07
	if skin >= 4 and g.state == "menu":
		match skin:
			4: # A slow feline stretch.
				var purr := sin(g.animation_time * 1.8) * 0.035
				stretch *= Vector2(1.0 - purr, 1.0 + purr)
			5: # Eager little hops.
				feet.y -= maxf(0, sin(g.animation_time * 4.2)) * 3.5
			6: lean += sin(g.animation_time * 2.4) * 0.025
			7: lean += sin(g.animation_time * 3.5) * 0.035
			8: feet.y += sin(g.animation_time * 5.0) * 2
			9: lean += sin(g.animation_time * 1.9) * 0.025
			10: lean = snappedf(lean, 0.025)
			11: feet.y += sin(g.animation_time * 2.3) * 4
			12: lean += sin(g.animation_time * 2.8) * 0.035
	var root := Transform2D(lean, Vector2.ONE * size, 0, feet)
	var body_root := root * Transform2D(0, stretch, 0, Vector2.ZERO)
	var chute: bool = hero or (flight and r.open and not r.done)
	g.draw_set_transform_matrix(root)
	if chute:
		chute_at(g.chute_skin(i), 1.0 if hero else float(r.deploy), clock)
	collection_extra(skin, clock, wind, body_root)
	g.draw_set_transform_matrix(body_root)
	# Cloth and ribbon roots follow the same squash/stretch as the torso.
	var scarf_points := PackedVector2Array()
	for k in range(10):
		var t := k / 9.0
		scarf_points.append(Vector2(20 + t * (25 - wind * 10) + sin(clock - t * 5) * 4 * wind, -25 - t * (8 + wind * 58)))
	for k in range(9, -1, -1):
		var t := k / 9.0
		scarf_points.append(Vector2(13 + t * (25 - wind * 10) + sin(clock - t * 5) * 4 * wind, -25 - t * (8 + wind * 58)))
	var scarf_color: Color = [Color("e64c8d"), Color("43bfbb"), Color("ffca39"), Color("a96ade")][skin] if skin < 4 else g.CHARACTER_COLORS[skin].darkened(0.15)
	g.draw_colored_polygon(scarf_points, scarf_color)
	scarf_points.append(scarf_points[0])
	g.draw_polyline(scarf_points, INK, 1.5, true)
	for side in [-1, 1]:
		var angle: float = side * (-0.28 - (1.95 if chute else wind * 2.1) + sin(clock + side) * wind * 0.15)
		if celebration:
			angle = podium_arm_angle(g.reaction_order().find(i), side, g.animation_time)
		elif proud:
			angle = side * (0.8 + sin(r.finish_age * 4) * 0.12)
		elif finished and r.safe:
			angle = reaction_arm_angle(reaction, side, r.finish_age)
		var holding_cup: bool = celebration and g.state == "podium" and podium_rank == 0 and side == 1
		if holding_cup:
			angle = -1.65 + sin(g.animation_time * 4) * 0.12
		g.draw_set_transform_matrix(body_root * Transform2D(angle, Vector2.ONE, 0, Vector2(side * 23, -31)))
		_sprite(arms[skin], Rect2(-6, -2, 12, 29))
		if holding_cup:
			var grip := Vector2(23, -31) + Vector2(0, 23).rotated(angle)
			g.draw_set_transform_matrix(body_root * Transform2D(0, grip + Vector2(0, 7)))
			draw_winner_cup()
			g.draw_set_transform_matrix(body_root)
			g._ellipse(grip, Vector2(4.5, 4), INK)
			g._ellipse(grip, Vector2(3.2, 2.7), g.COLORS[i])
		g.draw_set_transform_matrix(body_root)
		if not crashed or r.squash < 0.35:
			_sprite(boots[skin], Rect2(side * 14 - 6, -11, 12, 12))
	g.draw_set_transform_matrix(body_root)
	_sprite(bodies[skin], Rect2(-28, -70, 56, 65))
	var mood: String = reaction if celebration else expression_for(i, flight, hero)
	if proud:
		mood = "proud"
	if finale and podium_rank == 0 and conflict > 8 and conflict < 10.5:
		mood = "surprised"
	face(skin, mood, clock)
	character_accessories(skin, mood, clock)
	g.draw_set_transform_matrix(root)
	if proud:
		for side in [-1, 1]:
			g._star(Vector2(side * 39, -62 + sin(r.finish_age * 7 + side) * 5), 5, CORAL)
	if finale and podium_rank == 2 and conflict > 6 and conflict < 8.3:
		# The bronze medallist checks whether the medal is edible.
		var nibble := sin(g.animation_time * 18) * 1.5
		g.draw_line(Vector2(-24, -36), Vector2(-10, -27), INK, 3, true)
		g._ellipse(Vector2(-12, -29 + nibble), Vector2(9, 9), INK)
		g._ellipse(Vector2(-12, -30 + nibble), Vector2(7, 7), Color("e5ad88"))
		for crumb in range(3):
			g._ellipse(Vector2(-5 + crumb * 6, -23 + fposmod(g.animation_time * 21 + crumb * 9, 19)), Vector2(1.5, 1.5), CORAL)
	if reaction == "champion":
		if finale and conflict > 8 and conflict < 10.5:
			var slip := sin((conflict - 8) / 2.5 * PI)
			g.draw_set_transform_matrix(root * Transform2D(slip * 0.22, Vector2(0, slip * 22)))
		var crown := PackedVector2Array([Vector2(-13, -76), Vector2(-16, -90), Vector2(-7, -85), Vector2(0, -96), Vector2(7, -85), Vector2(16, -90), Vector2(13, -76), Vector2(-13, -76)])
		g.draw_colored_polygon(crown, CORAL)
		g.draw_polyline(crown, INK, 1.6, true)
	if crashed:
		for k in range(3):
			g._star(Vector2(cos(g.animation_time * 3 + k * 2.1) * 31, -79 + sin(g.animation_time * 3 + k * 2.1) * 6), 5, Color("efd07d"))
	g.draw_set_transform_matrix(Transform2D.IDENTITY)
	if finished and flight:
		var place: int = g.reaction_order().find(i)
		var caption: String = ["1ST", "2ND", "3RD", "4TH"][place] if r.safe else "SPLAT"
		pill(feet + Vector2(0, 20), caption, i == 0)

# Short glances with pauses read as reactions rather than constantly rolling eyes.
func recap_gaze(rank: int, time: float) -> Vector2:
	var phase := fposmod(time + rank * 0.7, 6.8)
	var beat := floori(phase / 1.7)
	var poses := [Vector2.ZERO, Vector2(-3.0, -0.7), Vector2(3.0, -0.4), Vector2(0.0, -2.4)]
	if rank == 1:
		poses = [Vector2.ZERO, Vector2(3.0, -1.8), Vector2(0.0, -2.0), Vector2(-2.5, 0.8)]
	elif rank == 2:
		poses = [Vector2.ZERO, Vector2(-3.0, -1.8), Vector2(2.4, 0.7), Vector2(-1.0, -2.2)]
	var transition := smoothstep(0.0, 0.3, fposmod(phase, 1.7))
	return poses[(beat + 3) % 4].lerp(poses[beat], transition)

func face(i: int, mood: String, clock: float) -> void:
	var recap_eyes: bool = not is_instance_valid(portrait_target) and g.state == "results" and mood in ["champion", "runner_up", "relieved"]
	var recap_rank: int = g.reaction_order().find(g.racer_skins.find(i)) if recap_eyes else -1
	var gaze := recap_gaze(recap_rank, g.animation_time) if recap_eyes else Vector2.ZERO
	var dizzy := mood == "dizzy"
	var panic := mood == "panic"
	var happy: bool = mood in ["victory", "relief", "landed", "champion", "runner_up", "relieved", "proud"]
	var worried: bool = mood in ["concerned", "panic", "disappointed"]
	
	var look_x: float = sin(g.animation_time * 1.4 + i * 0.8) * 2
	for side in [-1, 1]:
		var eye := Vector2(side * 10, -48 + (1 if side == -1 else -1))
		# Each silhouette of the eyes is recognisable even at gameplay scale.
		if i == 1:
			eye.y += -2 if side == 1 else 1
		elif i == 2:
			eye.y += side * 1.5
		if dizzy:
			g._ellipse(eye, Vector2(8.5, 10), INK)
			g._ellipse(eye, Vector2(7, 8.5), CREAM)
			var spiral := PackedVector2Array()
			for k in range(26):
				var angle := k / 25.0 * TAU * 1.6
				spiral.append(eye + Vector2(cos(angle), sin(angle)) * (0.4 + k / 25.0 * 5))
			g.draw_polyline(spiral, INK, 1.5, true)
		elif eyes_are_closed(mood, i, side):
			g.draw_arc(eye + Vector2(0, 4), 6.5, PI + 0.15, TAU - 0.15, 14, INK, 3, true)
		else:
			var scale_eye := 1.16 if (i == 1 and side == 1) else 1.0
			var eye_height := 1.0 + sin(g.animation_time * 2.2 + recap_rank + side * 0.4) * 0.045 if recap_eyes else 1.0
			g._ellipse(eye, Vector2(9, 11 * eye_height) * scale_eye, INK)
			g._ellipse(eye, Vector2(7.4, 9.4 * eye_height) * scale_eye, CREAM)
			var look := Vector2(look_x, 3.0 if mood == "disappointed" else 2.0 if worried else sin(g.animation_time + i))
			if i == 0:
				look.x += 1.5
			elif i == 1:
				look.x += sin(clock * 0.7) * 1.5
			elif i == 2:
				look.x = -2.0
			elif i == 3:
				look.x *= 0.25
			if recap_eyes:
				look = gaze * (0.8 if i == 7 else 1.0)
			g._ellipse(eye + look, Vector2(3.4, 5.5), INK)
			g._ellipse(eye + look + Vector2(-1, -2), Vector2(1.3, 1.8), Color.WHITE)
		g._ellipse(Vector2(side * 20, -36), Vector2(5.5, 3.8), Color("f08087"))
		g._ellipse(Vector2(side * 21, -37), Vector2(1.5, 1.5), Color("ffbdad"))
		if recap_eyes:
			var lift := sin(g.animation_time * 1.6 + recap_rank * 1.8 + side * 0.6) * 1.5
			g.draw_arc(eye + Vector2(0, -11.5 + lift), 5.5, PI + 0.25, TAU - 0.25, 12, INK, 2.0, true)
		elif worried:
			g.draw_line(eye + Vector2(-5, -14 + side * 2), eye + Vector2(5, -14 - side * 2), INK, 2.6, true)
		elif not happy:
			g.draw_arc(eye + Vector2(0, -10), 5.5, PI + 0.3, TAU - 0.3, 12, INK, 2.3, true)
	if dizzy:
		var mouth := PackedVector2Array()
		for k in range(13):
			mouth.append(Vector2(-8 + k * 1.3, -31 + sin(k * 0.9) * 2))
		g.draw_polyline(mouth, INK, 2.5, true)
	elif not worried and mood != "surprised":
		personality_mouth(i, clock)
	elif mood == "relieved":
		g.draw_arc(Vector2(0, -34), 7, 0.15, PI - 0.15, 16, INK, 2.5, true)
	elif mood == "runner_up":
		g._ellipse(Vector2(0, -31), Vector2(7.5, 5.5), INK)
		g._ellipse(Vector2(1, -28), Vector2(4, 2), Color("ef7097"))
	elif mood in ["confident", "relief", "landed", "champion"]:
		ink_box(Rect2(-12, -35, 24, 12), CREAM, 5)
		g.draw_line(Vector2(0, -34), Vector2(0, -25), INK, 1.2, true)
	elif mood == "surprised":
		g._ellipse(Vector2(0, -31), Vector2(6, 8), INK)
	elif mood in ["concerned", "disappointed"]:
		g.draw_arc(Vector2(0, -26), 8, PI + 0.2, TAU - 0.2, 16, INK, 2.8, true)
	elif worried:
		g._ellipse(Vector2(0, -31), Vector2(8, 8), INK)
		g._ellipse(Vector2(1, -27), Vector2(5, 3), Color("ee6991"))
		var sweat := PackedVector2Array([Vector2(24, -49), Vector2(29, -42), Vector2(29, -39), Vector2(26, -38), Vector2(24, -41)])
		g.draw_colored_polygon(sweat, Color("bee9f2"))
		g.draw_polyline(sweat, INK, 1, true)
	else:
		g._ellipse(Vector2(0, -31), Vector2(10, 9), INK)
		g._ellipse(Vector2(1, -26), Vector2(6, 3.5), Color("ef7097"))
		g.draw_line(Vector2(-5, -36), Vector2(4, -35), CREAM, 2, true)

func chute_at(i: int, deploy: float, clock: float) -> void:
	if deploy < 0.01:
		return
	var sway := sin(clock * 0.4) * 2
	for side in [-1, 1]:
		for anchor in [19.0, 46.0]:
			var start := Vector2(side * 21, -27)
			var end := Vector2(side * anchor * deploy + sway, -126 * deploy)
			g.draw_line(start + Vector2(1, 1), end + Vector2(1, 1), INK, 2.3, true)
			g.draw_line(start, end, INK, 1.7, true)
	_sprite(canopies[i], Rect2(Vector2(-54 * deploy + sway, -193 * deploy), Vector2(108, 72) * deploy))
	if i == 9:
		# Reflections stay inside the mirror canopy and follow inflation and sway.
		var glints := [Vector2(-23, -167), Vector2(22, -150), Vector2(5, -179)]
		for k in range(glints.size()):
			var pulse := maxf(0.0, sin(clock * 1.7 + k * 2.1))
			g._star(glints[k] * deploy + Vector2(sway, 0), (1.0 + pulse * 2.2) * deploy, Color("fff9ea"))


func bird(pos: Vector2, phase: float) -> void:
	g.draw_set_transform(pos, sin(phase) * 0.12, Vector2(1, 1 + sin(phase) * 0.12))
	_sprite(props[2], Rect2(-15, -14, 30, 28))
	g.draw_set_transform_matrix(Transform2D.IDENTITY)

func launch_platform(y: float) -> void:
	# Hand-built candy-coloured sky dock; soles sit exactly on the deck.
	for x in [60.0, 480.0]:
		g.draw_line(Vector2(x, y + 8), Vector2(x + (65 if x < 270 else -65), y + 120), INK, 12, true)
		g.draw_line(Vector2(x, y + 8), Vector2(x + (65 if x < 270 else -65), y + 120), Color("bc7b98"), 7, true)
	cloud(Vector2(115, y + 120), 1.0)
	cloud(Vector2(422, y + 123), 1.1)
	ink_box(Rect2(43, y, 454, 44), Color("df8f9e"), 13)
	ink_box(Rect2(36, y - 5, 468, 18), CREAM, 7)
	for i in range(4):
		var x: float = g._lane_x(i)
		g.draw_line(Vector2(x - 29, y + 5), Vector2(x + 29, y + 5), g.COLORS[i], 6, true)
		g._ellipse(Vector2(x, y + 28), Vector2(5, 5), CORAL)
	ink_box(Rect2(148, y + 47, 244, 35), CORAL, 12)
	var sign_size := 15
	while bold.get_string_size(g.platform_sign, HORIZONTAL_ALIGNMENT_LEFT, -1, sign_size).x > 220:
		sign_size -= 1
	text_at(Vector2(270, y + 65), g.platform_sign, sign_size, INK)
	for x in [45.0, 495.0]:
		g.draw_line(Vector2(x, y), Vector2(x, y - 90), INK, 5, true)
		g._ellipse(Vector2(x, y - 93), Vector2(8, 8), CORAL)
		var flag := PackedVector2Array([Vector2(x, y - 84), Vector2(x + 31, y - 74), Vector2(x, y - 61)])
		g.draw_colored_polygon(flag, Color("f48cab"))
		flag.append(flag[0])
		g.draw_polyline(flag, INK, 2, true)


func expression_for(i: int, flight: bool, hero: bool = false) -> String:
	var r: Dictionary = g.racers[i]
	if r.done and g.state in ["race", "settle", "results", "podium"]:
		return reaction_for(i)
	if hero:
		return ["excited", "confident", "concerned", "relief"][g.racer_skins[i] % 4] if g.state == "menu" else "victory"
	if not flight or g.state == "countdown":
		return "excited"
	if r.open:
		if r.deploy < 0.85:
			return "surprised"
		return "victory" if r.alt < 1.5 else "relief"
	if r.alt < 25:
		return "panic"
	if r.alt < 48:
		return "concerned"
	if g.race_time < 2.5:
		return "excited"
	return "confident"


func draw_dust() -> void:
	for puff in g.dust:
		var progress: float = puff.age / puff.duration
		var alpha := (1.0 - progress) * 0.82
		var center: Vector2 = puff.pos + Vector2(0, g._ground_y())
		var radius: float = puff.radius
		g._ellipse(center + Vector2(0, 1), Vector2(radius * 1.1, radius * 0.66), Color(0.50, 0.32, 0.25, alpha * 0.35))
		g._ellipse(center, Vector2(radius, radius * 0.67), Color(0.93, 0.81, 0.61, alpha))
		g._ellipse(center + Vector2(-radius * 0.2, -radius * 0.26), Vector2(radius * 0.6, radius * 0.5), Color(1.0, 0.91, 0.72, alpha * 0.9))

func responsive_landscape(bounds: Rect2) -> void:
	var width: float = 540 + game_ref.get_ref().responsive.extra_width
	var ratio := width / 540.0
	var bottom: float = bounds.end.y + g.responsive.extra_height * 0.5
	_sprite(landscape, Rect2((540 - width) * 0.5, bottom - bounds.size.y * ratio, width, bounds.size.y * ratio))

func render_menu() -> void:
	var t: float = g.animation_time
	_sprite(sky, g.responsive.background_rect())
	for i in range(4):
		var x := fposmod(50 + i * 167.0 + t * (5 + i), 700.0) - 80
		cloud(Vector2(x, 335 + i * 57), 0.6 + i * 0.13)
	responsive_landscape(Rect2(0, 226, 540, 780))
	g.draw_set_transform(Vector2(0, -g.responsive.extra_height * 0.5))
	_sprite(menu_decor[0], Rect2(-30 - g.responsive.extra_width * 0.5, -12, 294, 142))
	# Logo, character art, chooser and records have separate vertical bands.
	_sprite(logo, Rect2(30, 34 + sin(t * 1.1) * 2, 480, 240))
	g.draw_set_transform(Vector2(0, -g.responsive.extra_height * 0.25))
	text_at(Vector2(270, 291), "CHOOSE YOUR JELLY", 20, INK)
	text_at(Vector2(270, 315), "%s • %d / %d" % [g.CHUTE_NAMES[g.selected_chute], g.selected_chute + 1, g.CHUTE_NAMES.size()], 11, INK)
	g.draw_set_transform(Vector2.ZERO)
	var progress: float = clampf(g.carousel_time / g.CAROUSEL_DURATION, 0, 1)
	var eased := 1.0 - pow(1.0 - progress, 3)
	var bounce := sin(progress * PI) * 12.0
	var position := Vector2(270 + g.carousel_direction * (1 - eased) * 78 + sin(t * 0.7) * 3, 594 + sin(t * 1.5) * 4 - bounce)
	jelly(position, 0, false, true, 1.38 * (0.78 + 0.22 * eased + sin(progress * PI * 2) * 0.035))
	ink_box(Rect2(150, 616, 240, 43), CREAM, 18)
	var name_size := 23
	while bold.get_string_size(g.CHARACTER_NAMES[g.selected_character], HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x > 218:
		name_size -= 1
	text_at(Vector2(270, 637), g.CHARACTER_NAMES[g.selected_character], name_size, INK)
	text_at(Vector2(270, 686), g.CHARACTER_TRAITS[g.selected_character], 15, INK)
	for character in range(g.CHARACTER_NAMES.size()):
		var center := Vector2(270 + (character - (g.CHARACTER_NAMES.size() - 1) * 0.5) * 22, 721)
		if not g.owns_character(character):
			# Compact lock replaces the dot, retaining the same carousel spacing.
			g.draw_arc(center + Vector2(0, -3), 3.3, PI, TAU, 16, INK, 2.2, true)
			ink_box(Rect2(center + Vector2(-5, -2), Vector2(10, 8)), CREAM, 2)
			g._ellipse(center + Vector2(0, 1), Vector2(1.2, 1.2), INK)
			g.draw_line(center + Vector2(0, 1), center + Vector2(0, 3), INK, 1.4, true)
		else:
			g._ellipse(center, Vector2(7, 7) if character == g.selected_character else Vector2(5, 5), INK)
			g._ellipse(center, Vector2(4.5, 4.5) if character == g.selected_character else Vector2(3, 3), g.CHARACTER_COLORS[character])
	g.draw_set_transform(Vector2(0, g.responsive.extra_height * 0.5))
	draw_career_points()
	g.draw_set_transform(Vector2.ZERO)

func eyes_are_closed(mood: String, i: int, side: int) -> bool:
	if mood in ["landed", "dizzy", "champion", "runner_up", "relieved", "disappointed", "proud"]:
		return false
	# Stable within a frame, independent per character and rerolled every round.
	# Rendering never consumes the gameplay RNG.
	var animation_seed: int = 0 if is_instance_valid(portrait_target) else g.eye_seed
	var seed_value := hash(str(animation_seed) + ":" + str(i))
	var period := 1.8 + float(seed_value % 170) / 100.0
	var clock: float = g.animation_time + float(seed_value % 240) / 100.0
	var beat := floori(clock / period)
	var phase := fposmod(clock, period)
	var expression := hash(str(seed_value) + ":" + str(beat)) % 5
	if phase < 0.12:
		return true
	if phase > 0.48 or mood == "panic":
		return false
	# Left wink, right wink, both shut, double blink, or eyes open.
	match expression:
		0: return side == -1
		1: return side == 1
		2: return true
		3: return phase > 0.24 and phase < 0.36
	return false


func _flight_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = INK
	style.set_border_width_all(3)
	style.set_corner_radius_all(27)
	style.shadow_color = INK
	style.shadow_offset = Vector2(0, 5)
	style.shadow_size = 1
	return style

func configure_shop_portraits() -> void:
	for index in range(COLLECTION_IDS.size()):
		var slot: int = g.CHARACTER_SHOP_ORDER.find(index + 4)
		var clip := Control.new()
		clip.name = "ShopPortraitClip%d" % index
		clip.position = Vector2(47 + (slot % 3) * 152, 297 + floori(slot / 3.0) * 200 - (8 if index == 3 else 0))
		clip.size = Vector2(138, 130)
		clip.clip_contents = true
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var portrait := preload("res://shop_portrait.gd").new()
		portrait.art = self
		portrait.skin = index + 4
		clip.add_child(portrait)
		g.ui.add_child(clip)
		shop_portrait_clips.append(clip)
		var buy := Button.new()
		buy.name = "ShopBuy%d" % index
		buy.position = Vector2(56 + (slot % 3) * 152, 446 + floori(slot / 3.0) * 200)
		buy.size = Vector2(120, 27)
		buy.focus_mode = Control.FOCUS_NONE
		buy.add_theme_font_override("font", bold)
		buy.add_theme_font_size_override("font_size", 12)
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			buy.add_theme_color_override(key, INK)
		buy.add_theme_stylebox_override("normal", _flight_button_style(CORAL))
		buy.add_theme_stylebox_override("hover", _flight_button_style(Color("ffe49b")))
		buy.add_theme_stylebox_override("pressed", _flight_button_style(Color("ffb86b")))
		buy.add_theme_stylebox_override("disabled", _flight_button_style(Color("ddd6cb")))
		buy.pressed.connect(g._shop_character_action.bind(index + 4))
		g.ui.add_child(buy)
		shop_buy_buttons.append(buy)

	for index in range(g.CHUTE_IDS.size()):
		var slot: int = g.CHUTE_SHOP_ORDER.find(index + 4)
		var buy := Button.new()
		buy.name = "ShopChuteBuy%d" % index
		buy.position = Vector2(56 + (slot % 3) * 152, 446 + floori(slot / 3.0) * 200)
		buy.size = Vector2(120, 27)
		buy.focus_mode = Control.FOCUS_NONE
		buy.add_theme_font_override("font", bold)
		buy.add_theme_font_size_override("font_size", 12)
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			buy.add_theme_color_override(key, INK)
		buy.add_theme_stylebox_override("normal", _flight_button_style(CORAL))
		buy.add_theme_stylebox_override("hover", _flight_button_style(Color("ffe49b")))
		buy.add_theme_stylebox_override("pressed", _flight_button_style(Color("ffb86b")))
		buy.add_theme_stylebox_override("disabled", _flight_button_style(Color("ddd6cb")))
		buy.pressed.connect(g._shop_chute_action.bind(index + 4))
		g.ui.add_child(buy)
		shop_chute_buttons.append(buy)

func sync_ui() -> void:
	var shopping: bool = g.state == "shop"
	for clip in shop_portrait_clips:
		clip.visible = shopping and g.shop_category == 0
		if clip.visible:
			var portrait := clip.get_child(0)
			portrait.animation_time = g.animation_time
			portrait.queue_redraw()
	for index in range(shop_buy_buttons.size()):
		var skin := index + 4
		var owned: bool = g.owns_character(skin)
		var buy: Button = shop_buy_buttons[index]
		buy.visible = shopping and g.shop_category == 0
		buy.text = ("EQUIPPED" if g.selected_character == skin else "EQUIP") if owned else "BUY  %d" % g.CHARACTER_PRICES[skin]
		buy.disabled = (g.selected_character == skin) if owned else g.credits < g.CHARACTER_PRICES[skin]
		buy.tooltip_text = ("Owned" if owned else ("%d more credits needed" % (g.CHARACTER_PRICES[skin] - g.credits) if buy.disabled else "Unlock this jelly"))
		shop_portrait_clips[index].modulate = Color.WHITE
	for index in range(shop_chute_buttons.size()):
		var chute := index + 4
		var owned: bool = g.owns_chute(chute)
		var buy: Button = shop_chute_buttons[index]
		buy.visible = shopping and g.shop_category == 1
		buy.text = ("EQUIPPED" if g.selected_chute == chute else "EQUIP") if owned else "BUY  %d" % g.CHUTE_PRICES[chute]
		buy.disabled = (g.selected_chute == chute) if owned else g.credits < g.CHUTE_PRICES[chute]
		buy.tooltip_text = "Owned" if owned else ("%d more credits needed" % (g.CHUTE_PRICES[chute] - g.credits) if buy.disabled else "Unlock this parachute")
	g.action.visible = not shopping
	for i in range(g.shop_tabs.size()):
		g.shop_tabs[i].visible = shopping
		g.shop_tabs[i].add_theme_stylebox_override("normal", _flight_button_style(CORAL if i == g.shop_category else CREAM))
	for button in g.menu_side_buttons:
		button.visible = g.state == "menu"
	g.home_button.visible = g.state != "menu"
	g.home_button.position = Vector2(28, 873) if g.state in ["results", "podium"] else Vector2(438, 23)
	g.home_button.size = Vector2(88, 56) if g.state in ["results", "podium"] else Vector2(82, 57)
	for arrow in g.character_buttons + g.chute_buttons:
		arrow.visible = g.state == "menu"
	if shopping:
		g.home_button.position = Vector2(28, 28)
		g.home_button.size = Vector2(100, 56)
		for label in [g.heading, g.detail, g.badge, g.stats]:
			label.visible = false
		g.responsive.apply_ui()
		return
	var flight: bool = g.state in ["countdown", "race", "settle"]
	if flight:
		g.heading.visible = false
		g.detail.visible = false
		g.badge.visible = false
		g.stats.visible = false
		g.action.position = Vector2(30, 852)
		g.action.size = Vector2(480, 84)
		var mode := "ready"
		if g.state == "countdown":
			mode = "countdown"
		elif g.racers[0].done:
			mode = "safe" if g.racers[0].safe else "crash"
		elif g.racers[0].open:
			mode = "open"
		g.action.disabled = mode != "ready"
		g.action.text = {"ready": "OPEN PARACHUTE", "countdown": "GET READY...", "open": "CHUTE DEPLOYED", "safe": "LANDED SAFELY!", "crash": "TOUGH LANDING!"}[mode]
		g.action_hint.visible = true
		g.action_hint.text = "Jumping in 3, 2, 1..." if mode == "countdown" else ("Tap anywhere to deploy" if mode == "ready" else "Watch your jelly stick the landing")
		if mode != ui_mode:
			g.action.add_theme_font_size_override("font_size", 25)
			var color: Color = {"ready": CORAL, "countdown": CREAM, "open": Color("8ee1c2"), "safe": Color("8ee1c2"), "crash": Color("ff8f96")}[mode]
			set_action_style(color, true)
		ui_mode = mode
	elif g.state in ["results", "podium"]:
		for label in [g.heading, g.detail, g.badge, g.stats]:
			label.visible = false
		g.action.position = Vector2(130, 866)
		g.action.size = Vector2(382, 70)
		g.action.disabled = false
		g.action_hint.visible = false
		if ui_mode != g.state:
			set_action_style(CORAL, false)
		ui_mode = g.state
	else:
		g.action_hint.visible = true
		g.action_hint.text = "Tiny jellies. Big drops. Zero dignity."
		if ui_mode != "menu":
			set_action_style(CORAL, true)
		ui_mode = "menu"

	g.responsive.apply_ui()

func hud_status() -> Dictionary:
	var r: Dictionary = g.racers[0]
	if g.state == "countdown":
		return {"text": "YOU ARE " + g.CHARACTER_NAMES[g.selected_character] + " • LEFT LANE", "color": g.COLORS[0].lightened(0.5)}
	if r.done:
		return {"text": "SWEET LANDING!" if r.safe else "PANCAKE DELIVERY!", "color": Color("a4e8ce") if r.safe else Color("ffabb0")}
	if r.open:
		return {"text": "CHUTE INFLATING..." if r.deploy < 1.0 else "GLIDE TO THE FINISH", "color": Color("b6e8d8")}
	return {"text": "TRUST THE ALTITUDE BAR", "color": CREAM}

func draw_race_hud() -> void:
	var r: Dictionary = g.racers[0]
	var order: Array[int] = g.live_order()
	var place := order.find(0) + 1
	g.draw_set_transform(Vector2(0, -g.responsive.extra_height * 0.5))
	# Aligned, fixed header. No gameplay labels share its visual lane.
	ink_box(Rect2(20, 23, 146, 57), CREAM, 17)
	text_at(Vector2(93, 39), "ROUND", 10, INK)
	text_at(Vector2(93, 61), "%02d / 03" % g.round_number, 23, INK)
	ink_box(Rect2(178, 23, 139, 57), CREAM, 17)
	text_at(Vector2(247, 39), "RACE TIME", 10, INK)
	text_at(Vector2(247, 61), "%05.2f" % g.race_time, 23, INK)
	ink_box(Rect2(329, 23, 96, 57), Color("ffe49b"), 17)
	text_at(Vector2(377, 39), "POSITION", 10, INK)
	text_at(Vector2(377, 61), ["1ST", "2ND", "3RD", "4TH"][place - 1], 23, INK)
	for i in range(3):
		var center := Vector2(75 + i * 18, 94)
		g._ellipse(center, Vector2(5, 5), INK)
		g._ellipse(center, Vector2(3.2, 3.2), CORAL if i < g.round_number else CREAM)
	text_at(Vector2(270, 97), g.DIFFICULTY_NAMES[g.round_difficulty()], 11, INK)
	g.draw_set_transform(Vector2.ZERO)
	# Every height is shaded by the actual braking limit, not an arbitrary zone.
	ink_box(Rect2(10, 278, 29, 406), CREAM, 13)
	# Leave a 2px cream rim inside the dark frame, preserving the gauge's
	# altitude mapping between the marker's top and bottom positions.
	for pixel in range(396):
		var y := 283.0 + pixel
		var cap_distance := maxf(0.0, absf(y + 0.5 - 481.0) - 188.5)
		var half_width := sqrt(maxf(0.0, 9.5 * 9.5 - cap_distance * cap_distance))
		var altitude: float = clampf((674.0 - y - 0.5) / 383.0, 0.0, 1.0) * g.start_altitude
		g.draw_rect(Rect2(24.5 - half_width, y, half_width * 2.0, 1.0), g.deployment_color(altitude))
	var marker_y: float = 674 - clampf(r.alt / g.start_altitude, 0, 1) * 383
	g._ellipse(Vector2(24.5, marker_y), Vector2(12, 12), INK)
	g._ellipse(Vector2(24.5, marker_y), Vector2(8, 8), g.COLORS[0])
	var status := hud_status()
	var status_width: float = bold.get_string_size(status.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 36
	# Keep flight messages just above the action panel, below racer labels.
	var status_top: float = g.action.position.y - 45.0
	ink_box(Rect2(270 - status_width / 2, status_top, status_width, 29), status.color, 14)
	text_at(Vector2(270, status_top + 14), status.text, 14, INK)
	if g.state == "countdown" or g.jump_flash > 0:
		draw_jump_countdown()

func draw_jump_countdown() -> void:
	var jumping: bool = g.state != "countdown"
	var progress: float = clampf(1.0 - g.jump_flash / 0.65, 0, 1) if jumping else fposmod(3.0 - maxf(g.timer, 0.0), 1.0)
	var digit: int = g.countdown_number
	var color: Color = Color("8ee1c2") if jumping else [Color("ff9fbb"), CORAL, Color("b6a1ef")][3 - digit]
	var center := Vector2(270, 210)
	var fade: float = 1.0 - smoothstep(0.5, 1.0, progress) if jumping else 1.0
	# A ring drains once per beat, while a second shockwave expands outward.
	g.draw_arc(center, 77, -PI / 2, TAU - PI / 2, 72, Color(0.25, 0.07, 0.2, fade * 0.2), 6, true)
	if not jumping:
		g.draw_arc(center, 77, -PI / 2, -PI / 2 + TAU * maxf(0.001, 1.0 - progress), 72, color, 6, true)
	g.draw_arc(center, 62 + progress * (64 if jumping else 32), 0, TAU, 72, Color(color, (1 - progress) * 0.65 * fade), 3, true)
	for k in range(8):
		var angle := TAU * k / 8.0 + progress * 0.3
		var direction := Vector2(cos(angle), sin(angle))
		var origin := center + direction * (86 + progress * (38 if jumping else 8))
		g.draw_line(origin, origin + direction * (12 if jumping else 5), Color(color, fade * (1.0 - progress * 0.6)), 3, true)
	var spring: float = sin(progress * PI * 3.0) * exp(-progress * 5.0)
	var scale: float = (0.72 + minf(progress / 0.12, 1.0) * 0.28) + spring * 0.16
	if jumping:
		scale = 1.0 + sin(progress * PI) * 0.22
	var squash := Vector2(scale * (1 + spring * 0.08), scale * (1 - spring * 0.08))
	g.draw_set_transform(center + Vector2(0, -spring * 8), spring * 0.12, squash)
	g._ellipse(Vector2(2, 6), Vector2(62, 62), Color(INK, fade))
	g._ellipse(Vector2.ZERO, Vector2(61, 61), Color(INK, fade))
	g._ellipse(Vector2.ZERO, Vector2(57, 57), Color(CREAM, fade))
	g._ellipse(Vector2(-17, -24), Vector2(21, 10), Color(1, 1, 1, fade * 0.5))
	var content := "GO!" if jumping else str(digit)
	var font_size := 49 if jumping else 66
	var width := bold.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := Vector2(-width / 2, font_size * 0.32)
	g.draw_string_outline(bold, baseline, content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(INK, fade))
	g.draw_string(bold, baseline, content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, fade))
	g.draw_set_transform_matrix(Transform2D.IDENTITY)
	if not jumping:
		var caption: String = ["READY TO WOBBLE?", "TUCK IN YOUR JELLY!", "NEXT STOP: GRAVITY!"][3 - digit]
		ink_box(Rect2(156, 263, 228, 29), CREAM, 12)
		text_at(Vector2(270, 277), caption, 12, INK)
		for k in range(3):
			g._ellipse(Vector2(250 + k * 20, 307), Vector2(5, 5), INK)
			g._ellipse(Vector2(250 + k * 20, 307), Vector2(3, 3), color if k <= 3 - digit else CREAM)

func reaction_for(i: int) -> String:
	if not g.racers[i].safe and g.state != "podium":
		return "dizzy"
	var order: Array[int] = g.reaction_order()
	return ["champion", "runner_up", "relieved", "disappointed"][order.find(i)]

func reaction_arm_angle(reaction: String, side: int, elapsed: float) -> float:
	match reaction:
		"champion": return side * (-2.3 + sin(elapsed * 7) * 0.18)
		"runner_up": return side * (1.05 + sin(elapsed * 8) * 0.28)
		"relieved": return 2.5 + sin(elapsed * 3) * 0.12 if side == 1 else 0.15
		"disappointed": return side * -0.08
	return side * -0.28


func render_celebration() -> void:
	_sprite(sky, g.responsive.background_rect())
	responsive_landscape(Rect2(0, 255, 540, 780))
	var final: bool = g.state == "podium"
	var order: Array[int] = g.reaction_order() if final else g._ranked()
	var winner: int = order[0]
	if final and order.find(0) in [0, 1, 2]:
		draw_tournament_confetti()
	g.draw_set_transform(Vector2(0, -g.responsive.extra_height * 0.5))
	ink_box(Rect2(32, 24, 476, 111), CORAL, 26)
	text_at(Vector2(270, 48), "FLIGHT CLUB CHAMPION" if final else "ROUND %d • FRESHLY LANDED" % g.round_number, 15, INK)
	text_at(Vector2(270, 87), ("YOU TAKE THE CAKE!" if winner == 0 else g.NAMES[winner] + " TAKES THE CAKE!") if g.racers[winner].safe or final else "EVERYBODY IS TOAST!", 25, INK)
	text_at(Vector2(270, 117), "Gravity: 0. Wobble: 1." if winner == 0 else "Please clap. Their arms are jelly.", 14, INK)
	g.draw_set_transform(Vector2.ZERO)
	# Keep the round recap smaller than the tournament finale.
	var podium_scale := 1.0 if final else 0.82
	var tops := [387.0, 425.0, 450.0]
	for rank in range(3):
		var x: float = 270.0 + ([270.0, 132.0, 408.0][rank] - 270.0) * podium_scale
		var top: float = 510.0 + (tops[rank] - 510.0) * podium_scale
		ink_box(Rect2(x - 53 * podium_scale, top, 106 * podium_scale, 510 - top), [CORAL, Color("c5dbe7"), Color("e5ad88")][rank], 13)
		text_at(Vector2(x, top + 27), str(rank + 1), 26, INK)
		jelly(Vector2(x, top), order[rank], false, false, (1.3 if rank == 0 else 1.05) * podium_scale)
		podium_gag(Vector2(x, top), rank)
		pill(Vector2(x, 531), g.NAMES[order[rank]], order[rank] == 0)
	g.draw_set_transform_matrix(Transform2D.IDENTITY)
	draw_results_table(order, final)
	text_at(Vector2(270, 817), ("+%d CREDITS • TOURNAMENT COMPLETE" % g.tournament_reward) if final and g.tournament_paid else "CREDITS PAID AFTER ALL 3 ROUNDS", 13, INK)
	text_at(Vector2(270, 842), "WINS %d   •   BEST %s" % [g.wins, g._time_text(g.best_time)] if final else "Soft landings score points. Pancakes score sympathy.", 12, INK)


# Paper flutter uses no gameplay randomness.
func draw_tournament_confetti() -> void:
	var palette := [Color("ffca39"), Color("ff7f9f"), Color("70d9da"), Color("b29bff"), Color("fff1d0")]
	var time: float = g.podium_dialogue_time
	for k in range(64):
		var phase: float = k * 2.39996
		var speed: float = 38.0 + (k % 7) * 7.0
		var y: float = fposmod(k * 97.0 + time * speed, 810.0) - 45.0
		var x: float = fposmod(k * 83.0 + sin(time * 1.5 + phase) * 24.0 + time * (4.0 + k % 3), 580.0) - 20.0
		var fade: float = 1.0 - smoothstep(570.0, 755.0, y)
		var tint: Color = palette[k % palette.size()]
		tint.a = fade * 0.9
		var flutter: float = 0.25 + absf(cos(time * 3.0 + phase)) * 0.75
		g.draw_set_transform(Vector2(x, y), phase + time * (0.7 + (k % 5) * 0.35), Vector2(flutter, 1.0))
		if k % 4 == 0:
			g.draw_colored_polygon(PackedVector2Array([Vector2(-4, -3), Vector2(4, -3), Vector2(0, 5)]), tint)
		elif k % 4 == 1:
			g.draw_circle(Vector2.ZERO, 2.8, tint, true, -1, true)
		else:
			g.draw_rect(Rect2(-2.5, -5.0, 5.0, 10.0), tint)
			g.draw_line(Vector2(-1.5, -3), Vector2(-1.5, 2), Color(1, 1, 1, fade * 0.4), 1.0, true)
	g.draw_set_transform_matrix(Transform2D.IDENTITY)
# Separate phases keep the podium readable while each jelly has its own routine.
func podium_pose(rank: int, time: float) -> Dictionary:
	if g.state == "results":
		var breath := sin(time * 1.8 + rank * 1.7)
		var width := 1.0 + breath * 0.009
		return {"offset": Vector2(0, -breath * 1.2), "lean": breath * 0.018, "stretch": Vector2(width, 1.0 / width)}
	var phase := time * 5.0 + rank * 1.7
	var offset := Vector2.ZERO
	var lean := 0.0
	var width := 1.0
	match rank:
		0: # Bouncy victory dance, with exaggerated jelly knees.
			offset = Vector2(sin(phase) * 7, -maxf(0, sin(phase)) * 19)
			lean = sin(phase) * 0.13
			width = 1.0 + cos(phase * 2) * 0.08
		1: # Overenthusiastic applause and a dignified bow that goes too far.
			var bow := pow(maxf(0, sin(time * 1.8)), 5)
			lean = -0.28 * bow + sin(phase) * 0.045
			width = 1.0 + bow * 0.16
		2: # Wobbly balancing act, relieved to still be solid.
			lean = sin(phase * 0.6) * 0.19
			offset.x = sin(phase * 0.6) * 5
			width = 1.0 + sin(phase) * 0.055
	return {"offset": offset, "lean": lean, "stretch": Vector2(width, 1.0 / width)}

func podium_arm_angle(rank: int, side: int, time: float) -> float:
	if g.state == "results":
		var resting_angle: float = [-1.5, 0.5, -0.35][clampi(rank, 0, 2)]
		return side * (resting_angle + sin(time * 1.8 + rank + side) * 0.06)
	var conflict := fposmod(g.podium_dialogue_time, 12.0)
	if rank == 1 and conflict > 3 and conflict < 5.5:
		return -1.7 if side == 1 else 0.3
	if rank == 0 and conflict > 4.5 and conflict < 6:
		return 1.0 if side == -1 else -2.0
	if rank == 2 and conflict > 6 and conflict < 8.3:
		return 1.2 if side == -1 else -0.25
	if rank == 0 and conflict > 8 and conflict < 10.5:
		return side * -2.65
	match rank:
		0: return side * (-2.2 + sin(time * 7 + side) * 0.55)
		1: return side * (1.1 + sin(time * 13) * 0.55)
		2: return side * (-1.35 + sin(time * 5 + side) * 0.65)
	return side * -0.28

# Trace the rounded box and tail as one silhouette, with no seam at the join.
func draw_podium_bubble(center: Vector2, width: float) -> void:
	var outline := PackedVector2Array()
	var half := width * 0.5
	var radius := 12.0
	var corners := [Vector2(half - radius, -4), Vector2(half - radius, 4), Vector2(-half + radius, 4), Vector2(-half + radius, -4)]
	for corner in range(4):
		if corner == 2:
			outline.append(center + Vector2(8, 16))
			outline.append(center + Vector2(1, 25))
			outline.append(center + Vector2(-6, 16))
		for step in range(9):
			var angle: float = -PI * 0.5 + corner * PI * 0.5 + step * PI / 16.0
			outline.append(center + corners[corner] + Vector2(cos(angle), sin(angle)) * radius)
	var shadow := PackedVector2Array()
	for point in outline:
		shadow.append(point + Vector2(1, 3))
	g.draw_colored_polygon(shadow, Color("40133390"))
	g.draw_colored_polygon(outline, CREAM)
	outline.append(outline[0])
	g.draw_polyline(outline, INK, 3.0, true)
func podium_gag(feet: Vector2, rank: int) -> void:
	if g.state != "podium":
		return
	var t: float = g.animation_time
	# Brief speech bubbles take turns rather than talking over one another.
	if g.podium_speaker == rank and fposmod(g.podium_dialogue_time, 2.8) < 2.45:
		var center := feet + Vector2(0, -148 if rank == 0 else -125)
		var words: String = g.podium_line
		var width: float = bold.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 20
		center.x = clampf(center.x, width / 2 + 8, 532 - width / 2)
		draw_podium_bubble(center, width)
		text_at(center, words, 11, INK)
	if rank == 1:
		# Comic applause flashes beside the clapping hands.
		for side in [-1, 1]:
			var origin := feet + Vector2(side * 40, -34)
			if sin(t * 13) > 0.5:
				for k in range(3):
					g.draw_line(origin + Vector2(side * 3, k * 6 - 6), origin + Vector2(side * 10, k * 9 - 9), CORAL, 2, true)
	if rank == 2:
		# A theatrical sweat drop flies off during the balancing act.
		var phase := fposmod(t * 0.8, 1.0)
		var drop := feet + Vector2(31 + phase * 16, -65 + phase * 28)
		g._ellipse(drop, Vector2(3, 5), Color(0.64, 0.89, 1.0, 1.0 - phase))

func personality_mouth(i: int, clock: float) -> void:
	if i >= 4:
		collection_mouth(i, clock)
		return
	match i:
		0: # A lopsided movie-star grin.
			g.draw_arc(Vector2(1, -36), 11, 0.1, PI - 0.38, 18, INK, 3, true)
			g.draw_line(Vector2(6, -32), Vector2(11, -34), CREAM, 2.5, true)
		1: # Open laugh with two conspicuous buck teeth.
			g._ellipse(Vector2(0, -30), Vector2(10, 9), INK)
			g._ellipse(Vector2(1, -25), Vector2(6, 3), Color("ef7097"))
			g.draw_rect(Rect2(-5, -38, 10, 7), CREAM)
			g.draw_line(Vector2(0, -38), Vector2(0, -31), INK, 1.3, true)
		2: # The elegant smirk of someone who definitely meant to come second.
			g.draw_line(Vector2(-8, -29), Vector2(7, -32), INK, 2.8, true)
			g.draw_arc(Vector2(7, -34), 4, 0.2, 1.6, 10, INK, 2, true)
		3: # A tiny contented smile, unreasonably calm for a falling jelly.
			g.draw_arc(Vector2(0, -34), 6, 0.15, PI - 0.15, 14, INK, 2.6, true)

func character_accessories(i: int, mood: String, clock: float) -> void:
	var alarm: bool = mood in ["panic", "concerned", "surprised", "dizzy", "disappointed"]
	if i >= 4:
		collection_accessories(i, mood, clock)
		return
	match i:
		0: # Pink: rooted fringe, with tips fluttering in the actual airflow.
			var star_slot: int = g.racer_skins.find(0)
			var wind := 0.0
			if g.state == "race" and not g.racers[star_slot].done:
				wind = clampf(float(g.racers[star_slot].speed) / g.TERMINAL, 0, 1)
			var quiff := PackedVector2Array([
				Vector2(-24, -59), Vector2(-26, -69), Vector2(-22, -77),
				Vector2(-14, -81), Vector2(-5, -82), Vector2(5, -88),
				Vector2(15, -85), Vector2(22, -78), Vector2(23, -71),
				Vector2(18, -65), Vector2(9, -62), Vector2(2, -63),
				Vector2(9, -69), Vector2(-2, -65), Vector2(-13, -63),
				Vector2(-19, -56), Vector2(-24, -59)
			])
			quiff = flutter_hair(quiff, g.animation_time, wind)
			g.draw_colored_polygon(quiff, Color("ffd46c"))
			g.draw_polyline(quiff, INK, 2, true)
			g.draw_polyline(flutter_hair(PackedVector2Array([Vector2(-20, -69), Vector2(-15, -75), Vector2(-4, -76), Vector2(6, -81), Vector2(13, -79)]), g.animation_time, wind), Color("fff0ac"), 3, true)
			g.draw_polyline(flutter_hair(PackedVector2Array([Vector2(-13, -66), Vector2(-4, -70), Vector2(7, -73), Vector2(16, -72)]), g.animation_time, wind), Color("d69b40"), 1.5, true)
		1: # Mango: wonky goggles pushed up and permanent freckles.
			g.draw_line(Vector2(-26, -65), Vector2(26, -65), Color("9c623f"), 5, true)
			for side in [-1, 1]:
				var center := Vector2(side * 10, -69 + side * 2)
				g._ellipse(center, Vector2(10, 8), INK)
				g._ellipse(center, Vector2(7, 5), Color("a6e6ec"))
				g.draw_line(center + Vector2(-3, -2), center + Vector2(2, -3), CREAM, 2, true)
				for k in range(3):
					g._ellipse(Vector2(side * (16 + k * 3), -36 + k % 2 * 3), Vector2(1.2, 1.2), Color("a85e34"))
		2: # Bubbles: little tilted beret, monocle and flamboyant bow tie.
			# The lower band wraps over the head instead of floating above it.
			g._ellipse(Vector2(-3, -68), Vector2(24, 10), INK)
			g._ellipse(Vector2(-3, -69), Vector2(21.5, 7.5), Color("703852"))
			g._ellipse(Vector2(0, -61), Vector2(20, 4), INK)
			g._ellipse(Vector2(0, -62), Vector2(17.5, 2.3), Color("8d506b"))
			g.draw_arc(Vector2(-8, -69), 10, PI + 0.2, PI * 1.7, 16, Color("a36981"), 1.8, true)
			g.draw_line(Vector2(-9, -77), Vector2(-7, -81), INK, 3, true)
			g.draw_arc(Vector2(10, -48), 12, 0, TAU, 28, CORAL, 2.3, true)
			g.draw_line(Vector2(21, -45), Vector2(25, -20), CORAL, 1.3, true)
			for side in [-1, 1]:
				var bow := PackedVector2Array([Vector2(0, -18), Vector2(side * 13, -25), Vector2(side * 13, -12), Vector2(0, -18)])
				g.draw_colored_polygon(bow, Color("ffcf66"))
				g.draw_polyline(bow, INK, 1.5, true)
			g._ellipse(Vector2(0, -18), Vector2(3, 3), INK)
			if not alarm:
				g.draw_line(Vector2(-18, -59), Vector2(-5, -57), INK, 3, true)
		3: # Pickle: propeller beanie, a tiny moustache and sleepy eyelids.
			g._ellipse(Vector2(0, -72), Vector2(19, 8), INK)
			g._ellipse(Vector2(0, -73), Vector2(16, 6), Color("68c05e"))
			g.draw_line(Vector2(-19, -69), Vector2(22, -69), INK, 3, true)
			g.draw_line(Vector2(0, -77), Vector2(0, -89), INK, 2.5, true)
			var hub := Vector2(0, -89)
			for blade in range(3):
				var angle: float = g.hat_rotor_angle + blade * TAU / 3.0
				var shape := PackedVector2Array()
				for point in [Vector2(1, -2), Vector2(11, -5), Vector2(16, -2), Vector2(14, 3), Vector2(4, 3)]:
					shape.append(hub + point.rotated(angle))
				g.draw_colored_polygon(shape, [CORAL, Color("f48cab"), Color("8ed8f1")][blade])
				shape.append(shape[0])
				g.draw_polyline(shape, INK, 1.3, true)
			g._ellipse(hub, Vector2(3, 3), INK)
			for side in [-1, 1]:
				g.draw_arc(Vector2(side * 4, -35), 5, 0.1, PI - 0.1, 12, INK, 2.6, true)
				if not alarm:
					g.draw_line(Vector2(side * 10 - 7, -52), Vector2(side * 10 + 7, -52), INK, 2.6, true)

func set_action_style(color: Color, subtitle: bool) -> void:
	for mode in ["normal", "hover", "pressed", "disabled"]:
		var tint: Color = color.lightened(0.08) if mode == "hover" else color.darkened(0.06) if mode == "pressed" else color
		var style := _flight_button_style(tint)
		style.content_margin_bottom = 24 if subtitle else 0
		style.content_margin_top = 0
		style.content_margin_left = 12
		style.content_margin_right = 12
		g.action.add_theme_stylebox_override(mode, style)

func flutter_hair(points: PackedVector2Array, time: float, wind: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		var height := clampf((-point.y - 62) / 26.0, 0, 1)
		var wave := sin(time * 19 + height * 3) * 4.5 + sin(time * 31 + point.x * 0.12) * 1.5
		result.append(point + Vector2(wave * height * height + height * 2, -height * (3 + sin(time * 23) * 1.5)) * wind)
	return result

func draw_results_table(order: Array[int], final: bool) -> void:
	ink_box(Rect2(24, 557, 492, 245), CREAM, 23)
	text_at(Vector2(270, 579), "FLIGHT CLUB LEADERBOARD" if final else "THE LANDING LINE-UP", 17, INK)
	var secondary := Color("946077")
	g.draw_string(bold, Vector2(146, 607), "JELLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, secondary)
	text_at(Vector2(65, 604), "PLACE", 9, secondary)
	if final:
		text_at(Vector2(447, 604), "TOTAL POINTS", 10, secondary)
	else:
		text_at(Vector2(365, 604), "TIME", 10, secondary)
		text_at(Vector2(460, 604), "POINTS", 10, secondary)
	for rank in range(4):
		var slot: int = order[rank]
		var y := 634.0 + rank * 46
		var player: bool = slot == 0
		var tint: Color = g.COLORS[slot].lightened(0.78) if player else Color("fff9e8")
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = tint
		row_style.border_color = g.COLORS[slot].darkened(0.25) if player else Color("e6d1b8")
		row_style.set_border_width_all(2 if player else 1)
		row_style.set_corner_radius_all(12)
		g.draw_style_box(row_style, Rect2(36, y - 20, 468, 40))
		# Medal geometry communicates place without depending on character colour.
		var medal: Color = [CORAL, Color("c5dbe7"), Color("e5ad88"), Color("eadfcf")][rank]
		if rank < 3:
			g.draw_colored_polygon(PackedVector2Array([Vector2(54, y + 5), Vector2(53, y + 17), Vector2(64, y + 12), Vector2(76, y + 17), Vector2(74, y + 5)]), medal.darkened(0.2))
		g._ellipse(Vector2(65, y), Vector2(14, 14), INK)
		g._ellipse(Vector2(65, y - 1), Vector2(12, 12), medal)
		text_at(Vector2(65, y - 1), str(rank + 1), 15, INK)
		var skin: int = g.racer_skins[slot]
		g.draw_set_transform(Vector2(114, y + 14), 0, Vector2.ONE * 0.38)
		_sprite(bodies[skin], Rect2(-28, -70, 56, 65))
		face(skin, "relief", g.animation_time)
		character_accessories(skin, "relief", g.animation_time)
		g.draw_set_transform_matrix(Transform2D.IDENTITY)
		g.draw_string(bold, Vector2(146, y + 6), g.NAMES[slot], HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if player else 16, INK)
		if final:
			var value: String = str(g.totals[slot])
			var width: float = bold.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 23).x
			g.draw_string(bold, Vector2(453 - width, y + 8), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, INK)
			g.draw_string(bold, Vector2(461, y + 6), "pts", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, secondary)
		else:
			var safe: bool = g.racers[slot].safe
			var value: String = g._time_text(g.racers[slot].time) if safe else "SPLAT!"
			var width: float = bold.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			g.draw_string(bold, Vector2(401 - width, y + 6), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK if safe else Color("bc4768"))
			var score_style := StyleBoxFlat.new()
			score_style.bg_color = Color("f9df88") if safe else Color("f5d4d7")
			score_style.set_corner_radius_all(9)
			g.draw_style_box(score_style, Rect2(428, y - 13, 62, 26))
			text_at(Vector2(459, y), "+%d" % (g.POINTS[rank] if safe else 0), 16, INK)

func draw_career_points() -> void:
	# A compact collector badge occupies the gap above the confirmation button.
	ink_box(Rect2(138, 746, 264, 60), CREAM, 20)
	var center := Vector2(178, 776)
	g._ellipse(center + Vector2(0, 2), Vector2(22, 22), INK)
	g._ellipse(center, Vector2(20, 20), CORAL)
	g.draw_arc(center, 16, PI * 1.05, PI * 1.75, 20, Color("fff5bb"), 2.5, true)
	g._star(center, 12, INK)
	g._star(center, 9, Color("ffe891"))
	text_at(Vector2(295, 761), "CREDITS", 10, INK)
	var content := str(floori(g.displayed_career_points))
	var size := 25
	while size > 13 and bold.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > 158:
		size -= 1
	text_at(Vector2(295, 786), content, size, INK)
	var sparkle := 0.75 + sin(g.animation_time * 2.5) * 0.25
	g._star(Vector2(391, 751), 5 * sparkle, CORAL)

func draw_winner_cup() -> void:
	# Local origin is the base: the stem passes through the animated hand.
	for side in [-1, 1]:
		g.draw_arc(Vector2(side * 12, -27), 9, -PI / 2, PI / 2 if side == 1 else PI * 1.5, 24, INK, 5, true)
		g.draw_arc(Vector2(side * 12, -27), 9, -PI / 2, PI / 2 if side == 1 else PI * 1.5, 24, CORAL, 2.5, true)
	var bowl := PackedVector2Array([Vector2(-15, -38), Vector2(15, -38), Vector2(13, -24), Vector2(8, -17), Vector2(0, -14), Vector2(-8, -17), Vector2(-13, -24), Vector2(-15, -38)])
	g.draw_colored_polygon(bowl, Color("f9b83e"))
	g.draw_polyline(bowl, INK, 2, true)
	g.draw_line(Vector2(-10, -34), Vector2(-8, -25), Color("fff0ac"), 3, true)
	g.draw_line(Vector2(-16, -38), Vector2(16, -38), INK, 4, true)
	g.draw_line(Vector2(-14, -39), Vector2(14, -39), Color("ffe390"), 2, true)
	g.draw_line(Vector2(0, -14), Vector2(0, -4), INK, 7, true)
	g.draw_line(Vector2(0, -14), Vector2(0, -4), CORAL, 4, true)
	ink_box(Rect2(-12, -5, 24, 7), Color("e89c36"), 2)
	g._star(Vector2(0, -28), 5.5, CREAM)
	var sparkle := 0.7 + sin(g.animation_time * 5) * 0.3
	g._star(Vector2(18, -42), 4 * sparkle, CREAM)

func render_shop() -> void:
	# A dedicated full-screen view; inventory will be designed separately.
	g.draw_rect(g.responsive.background_rect(), Color("28bee0"))
	g.draw_texture_rect(sky, g.responsive.background_rect(), false)
	responsive_landscape(Rect2(0, 560, 540, 780))
	g.draw_set_transform(Vector2(0, -g.responsive.extra_height * 0.5))
	text_at(Vector2(270, 58), "JELLY SHOP", 30, INK)
	ink_box(Rect2(118, 103, 304, 65), CREAM, 22)
	var center := Vector2(153, 135)
	g._ellipse(center, Vector2(21, 21), INK)
	g._ellipse(center, Vector2(18, 18), CORAL)
	g._star(center, 11, INK)
	g._star(center, 8, Color("ffe891"))
	text_at(Vector2(285, 120), "AVAILABLE CREDITS", 10, INK)
	var amount := str(g.credits)
	var font_size := 26
	while font_size > 12 and bold.get_string_size(amount, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 210:
		font_size -= 1
	text_at(Vector2(285, 148), amount, font_size, INK)
	g.draw_set_transform(Vector2.ZERO)
	ink_box(Rect2(28, 278, 484, 634), CREAM, 26)
	if g.shop_category == 1:
		for index in range(g.CHUTE_IDS.size()):
			var chute: int = g.CHUTE_SHOP_ORDER[index]
			var top_left := Vector2(44 + (index % 3) * 152, 294 + floori(index / 3.0) * 200)
			var owned: bool = g.owns_chute(chute)
			ink_box(Rect2(top_left, Vector2(144, 192)), CREAM, 16)
			_sprite(canopies[chute], Rect2(top_left + Vector2(12, 36), Vector2(120, 80)), Color.WHITE)
			if not owned:
				var lock := top_left + Vector2(123, 20)
				g._ellipse(lock, Vector2(13, 13), CREAM)
				g.draw_arc(lock + Vector2(0, -2), 4, PI, TAU, 14, INK, 2, true)
				ink_box(Rect2(lock + Vector2(-6, -2), Vector2(12, 10)), CORAL, 3)
				g.draw_line(lock + Vector2(0, 1), lock + Vector2(0, 4), INK, 1.5, true)
			var words: PackedStringArray = g.CHUTE_NAMES[chute].split(" ", false, 1)
			text_at(top_left + Vector2(72, 126), words[0], 13, INK)
			text_at(top_left + Vector2(72, 141), words[1], 13, INK)
	if g.shop_category == 0:
		for index in range(COLLECTION_IDS.size()):
			var skin := index + 4
			var slot: int = g.CHARACTER_SHOP_ORDER.find(skin)
			var top_left := Vector2(44 + (slot % 3) * 152, 294 + floori(slot / 3.0) * 200)
			ink_box(Rect2(top_left, Vector2(144, 192)), g.CHARACTER_COLORS[skin].lightened(0.76), 16)
			if not g.owns_character(skin):
				var lock := top_left + Vector2(123, 20)
				g._ellipse(lock, Vector2(13, 13), CREAM)
				g.draw_arc(lock + Vector2(0, -2), 4, PI, TAU, 14, INK, 2, true)
				ink_box(Rect2(lock + Vector2(-6, -2), Vector2(12, 10)), CORAL, 3)
				g.draw_line(lock + Vector2(0, 1), lock + Vector2(0, 4), INK, 1.5, true)
			if skin == 7:
				text_at(top_left + Vector2(72, 128), "2 CHAINZ,", 13, INK)
				text_at(top_left + Vector2(72, 141), "NO BONES", 13, INK)
				continue
			var name_size := 14
			while bold.get_string_size(g.CHARACTER_NAMES[skin], HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x > 130:
				name_size -= 1
			text_at(top_left + Vector2(72, 140), g.CHARACTER_NAMES[skin], name_size, INK)
	if not g.shop_message.is_empty():
		text_at(Vector2(270, 899), g.shop_message, 11, INK)


func collection_extra_parts(skin: int, clock: float, wind: float) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []
	match skin:
		4, 5, 9, 11:
			var wag := sin(clock * (1.8 if skin == 5 else 0.65)) * (0.32 if skin == 5 else 0.15)
			var rect := Rect2(0, -34, 40, 38) if skin == 4 else Rect2(0, -17, 35, 27)
			if skin == 11:
				rect = Rect2(-2, -12, 43, 24)
			parts.append({"transform": Transform2D(wag - wind * 0.25, Vector2(20, -18)), "rect": rect})
		6, 8:
			for side in [-1, 1]:
				var flutter := sin(clock * (3.4 if skin == 8 else 1.5))
				var wing_scale := Vector2(side, 0.75 + flutter * 0.2)
				parts.append({"transform": Transform2D(side * flutter * 0.14, wing_scale, 0, Vector2(side * 20, -44)), "rect": Rect2(0, -25, 39 if skin == 6 else 31, 37)})
		10:
			parts.append({"transform": Transform2D(0, Vector2(1, 0.65 + absf(cos(clock)) * 0.35), 0, Vector2(23, -38)), "rect": Rect2(0, -9, 23, 18)})
	return parts

func collection_extra(skin: int, clock: float, wind: float, base: Transform2D) -> void:
	if skin < 4 or skin == 12:
		return
	for part in collection_extra_parts(skin, clock, wind):
		g.draw_set_transform_matrix(base * part.transform)
		_sprite(collection_extras[skin - 4], part.rect)
	g.draw_set_transform_matrix(base)

func collection_head_rect(skin: int) -> Rect2:
	var rect: Rect2 = HEAD_RECTS[skin - 4]
	var contact: float = preload("res://assets/toon/collection/atlas_regions.gd").HEAD_CONTACT_RATIOS[skin - 4]
	rect.position.y = HEAD_SEAT_Y[skin - 4] - rect.size.y * contact
	return rect

func collection_accessories(skin: int, mood: String, clock: float) -> void:
	var rect := collection_head_rect(skin)
	var alarm: bool = mood in ["panic", "concerned", "surprised", "dizzy", "disappointed"]
	# Hood and band use the same body transform, with no independent translation.
	_sprite(collection_heads[skin - 4], rect)
	match skin:
		4:
			var nose := PackedVector2Array([Vector2(-3, -37), Vector2(3, -37), Vector2(0, -34), Vector2(-3, -37)])
			g.draw_colored_polygon(nose, Color("9e4663"))
			g.draw_line(Vector2(0, -35), Vector2(0, -31), INK, 1.4, true)
			for side in [-1, 1]:
				for whisker in range(3):
					g.draw_line(Vector2(side * 17, -36 + whisker * 3), Vector2(side * 31, -39 + whisker * 6), INK, 1.2, true)
		5:
			g._ellipse(Vector2(0, -36), Vector2(5, 3.5), INK)
			g._ellipse(Vector2(-1, -37), Vector2(1.7, 0.8), CREAM)
			if not alarm:
				g._ellipse(Vector2(2, -25), Vector2(3, 5), Color("f690a0"))
		6:
			if not alarm:
				for side in [-1, 1]:
					g.draw_colored_polygon(PackedVector2Array([Vector2(side * 6 - 2, -33), Vector2(side * 6 + 2, -33), Vector2(side * 6, -28)]), CREAM)
		7:
			_sprite(collection_extras[skin - 4], Rect2(-25, -26, 50, 31))
			g._star(Vector2(21, -21), 2.0 + sin(clock * 1.7) * 0.6, Color("fff2a7"))
		8:
			g._ellipse(Vector2(0, -37), Vector2(2.5, 2), Color("a76332"))
		9:
			for side in [-1, 1]:
				g._star(Vector2(side * 21, -38), 3.2, Color("fff1a8"))
		10:
			for side in [-1, 1]:
				g.draw_line(Vector2(side * 18, -52), Vector2(side * 23, -52), INK, 1.5, true)
				g._ellipse(Vector2(side * 23, -52), Vector2(1.8, 1.8), CORAL)
		11:
			if alarm:
				g._ellipse(Vector2(0, -31), Vector2(5, 7), INK)
		12:
			_sprite(collection_extras[skin - 4], Rect2(-17, -24, 34, 16))
			for side in [-1, 1]:
				g.draw_arc(Vector2(side * 4, -36), 5, 0.1, PI - 0.1, 12, INK, 2.5, true)

func collection_mouth(skin: int, clock: float) -> void:
	match skin:
		4:
			for side in [-1, 1]:
				g.draw_arc(Vector2(side * 3.5, -33), 4, 0.1, PI - 0.1, 12, INK, 1.8, true)
		7:
			ink_box(Rect2(-9, -35, 18, 7), CREAM, 3)
			for tooth in [-3, 3]:
				g.draw_line(Vector2(tooth, -35), Vector2(tooth, -29), Color("cb9135"), 1, true)
		5, 6, 8, 12:
			g._ellipse(Vector2(0, -30), Vector2(8, 7), INK)
			g._ellipse(Vector2(1, -27), Vector2(5, 2.5), Color("ef7097"))
			if skin == 8:
				g.draw_rect(Rect2(-3, -36, 6, 4), CREAM)
		9:
			g.draw_arc(Vector2(0, -35), 8, 0.1, PI - 0.15, 16, INK, 2.6, true)
		10:
			ink_box(Rect2(-8, -35, 16, 8), CREAM, 2)
			for x in [-3, 3]:
				g.draw_line(Vector2(x, -34), Vector2(x, -28), INK, 1, true)
		11:
			g._ellipse(Vector2(0, -30), Vector2(5, 6 + sin(clock) * 0.8), INK)

func collection_portrait(skin: int, feet: Vector2, size: float) -> void:
	# Preserve identical body alignment and scale; the card clips free accessories.
	var base := Transform2D(0, Vector2.ONE * size, 0, feet)
	var clock: float = g.animation_time * 5 + skin
	g.draw_set_transform_matrix(base)
	collection_extra(skin, clock, 0, base)
	for side in [-1, 1]:
		g.draw_set_transform_matrix(base * Transform2D(side * -0.3, Vector2(side * 23, -31)))
		_sprite(arms[skin], Rect2(-6, -2, 12, 29))
		g.draw_set_transform_matrix(base)
		_sprite(boots[skin], Rect2(side * 14 - 6, -11, 12, 12))
	_sprite(bodies[skin], Rect2(-28, -70, 56, 65))
	face(skin, "excited", clock)
	character_accessories(skin, "excited", clock)
	g.draw_set_transform_matrix(Transform2D.IDENTITY)
