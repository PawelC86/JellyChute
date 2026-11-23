extends RefCounted
## Paper Sky renderer. Original transparent atlases remain editable source assets.
var game_ref: WeakRef
var g: Node2D:
	get:
		return game_ref.get_ref() as Node2D
var bodies: Array[Texture2D] = []
var canopies: Array[Texture2D] = []
var arms: Array[Texture2D] = []
var boots: Array[Texture2D] = []
var props: Array[Texture2D] = []
var landscape: Texture2D
var sky: Texture2D
var cream_paper: Texture2D
var bold: FontVariation
const INK := Color("674337")
const CREAM := Color("fff1d4")
const CORAL := Color("db7c70")

func _init(game: Node2D) -> void:
	game_ref = weakref(game)
	var actors := _atlas("res://assets/paper/actors.png", 4, 4)
	for i in range(4):
		bodies.append(actors[i])
		canopies.append(actors[4 + i])
		arms.append(actors[8 + i])
		boots.append(actors[12 + i])
	props = _atlas("res://assets/paper/props.png", 3, 3)
	var prop_image := (load("res://assets/paper/props.png") as Texture2D).get_image()
	cream_paper = ImageTexture.create_from_image(prop_image.get_region(Rect2i(int(prop_image.get_width() * 0.12), int(prop_image.get_height() * 0.15), 80, 80)))
	landscape = load("res://assets/paper/landscape.png") as Texture2D
	# A material swatch cut from the approved reference, not a painted imitation.
	var reference := (load("res://assets/paper/style-reference.png") as Texture2D).get_image()
	var swatch := Rect2i(int(reference.get_width() * 0.40), int(reference.get_height() * 0.12), 80, 80)
	sky = ImageTexture.create_from_image(reference.get_region(swatch))
	bold = FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.65

func _atlas(path: String, columns: int, rows: int) -> Array[Texture2D]:
	var texture := load(path) as Texture2D
	var image := texture.get_image()
	var result: Array[Texture2D] = []
	var cell := Vector2i(image.get_width() / columns, image.get_height() / rows)
	for row in range(rows):
		for column in range(columns):
			var origin := Vector2i(column * cell.x, row * cell.y)
			var piece := image.get_region(Rect2i(origin, cell))
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
	g.action.add_theme_stylebox_override("normal", button_style())
	g.action.add_theme_stylebox_override("hover", button_style(Color("fff7e9")))
	g.action.add_theme_stylebox_override("pressed", button_style(Color("e8c5b0")))
	g.action.add_theme_stylebox_override("disabled", button_style(Color("d9c7b9")))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		g.action.add_theme_color_override(key, CREAM)
	g.action.add_theme_font_override("font", bold)
	g.action.add_theme_font_size_override("font_size", 23)
	for label in [g.heading, g.detail, g.badge]:
		label.add_theme_color_override("font_color", INK)
	g.heading.add_theme_font_override("font", bold)
	g.badge.add_theme_font_override("font", bold)
	g.stats.add_theme_color_override("font_color", INK)
	var mute_style := StyleBoxFlat.new()
	mute_style.bg_color = CREAM
	mute_style.set_corner_radius_all(17)
	mute_style.border_color = Color("e2c5a0")
	mute_style.border_width_bottom = 3
	g.mute_button.add_theme_stylebox_override("normal", mute_style)
	g.mute_button.add_theme_stylebox_override("hover", mute_style)
	g.mute_button.add_theme_color_override("font_color", INK)

func render() -> void:
	var flight: bool = g.state in ["race", "settle", "countdown"]
	g.draw_rect(Rect2(0, 0, 540, 960), Color("acd2e3"))
	g.draw_texture_rect(sky, Rect2(0, 0, 540, 960), true, Color("f4f8ff"))
	_sprite(props[2], Rect2(384, 86, 123, 123))
	for i in range(7):
		var y: float = fposmod(float(i * 183) - (g.ALTITUDE - g.camera_alt) * g.PIXELS_PER_METRE * 0.10, 1150.0) - 80
		if flight or y > 410:
			cloud(Vector2(float((i * 191 + 45) % 540), y), 0.65 + float(i % 3) * 0.22)
	var ground: float = g._ground_y() if flight else 760.0
	if ground < 1250:
		_sprite(landscape, Rect2(0, ground - 645, 540, 960))
	if flight:
		g._draw_flight_world()
		if g.state == "countdown" or (g.state == "race" and g.race_time < 2):
			var offset: float = (g.ALTITUDE - g.camera_alt) * g.PIXELS_PER_METRE
			plane(Vector2(270, 265 - offset))
			paper_box(Rect2(40, 393 - offset, 460, 10), Color("bc9c77"), 4)
		for i in range(4):
			var x: float = 95 + i * 115
			pad(Vector2(x, ground), i)
			var feet: Vector2 = g._racer_feet(i)
			if feet.y >= 145 and feet.y < 780:
				jelly(feet, i, true)
				if not g.racers[i].done:
					pill(Vector2(x, feet.y + 20), g.NAMES[i], i == 0)
			elif feet.y < 145:
				pill(Vector2(x, 168), g.NAMES[i] + " ↑", i == 0)
			elif not g.racers[i].done:
				pill(Vector2(x, 746), g.NAMES[i] + " ↓", i == 0)
		paper_box(Rect2(17, 315, 10, 340), Color("f5e6cba0"), 5)
		paper_box(Rect2(19, 655 - 25.0 / g.ALTITUDE * 340, 6, 25.0 / g.ALTITUDE * 340), CORAL, 3)
		g._ellipse(Vector2(22, 655 - float(g.racers[0].alt) / g.ALTITUDE * 340), Vector2(7, 7), CREAM)
		if g.state == "countdown":
			pill(Vector2(270, 222), "READY TO GET WOBBLY?", false)
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
				paper_box(Rect2(x - 47, top, 94, 785 - top), Color("e9c075"), 8)
				text_at(Vector2(x, top + 30), str(rank + 1), 22, INK)
				jelly(Vector2(x, top), order[rank], false)
		else:
			for i in range(4):
				jelly(Vector2(95 + i * 115, 748), i, true)
		if g.state != "menu":
			paper_box(Rect2(27, 215, 486, 355), CREAM, 24)
	paper_box(Rect2(20, 20, 188, 48), CREAM, 23)
	paper_box(Rect2(24, 782, 492, 68), Color("f4e1bc"), 21)
	for p in g.particles:
		g._star(p.pos + Vector2(0, g._ground_y()), 4, Color("edc270"))

func paper_box(rect: Rect2, color: Color, radius: int) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color("725b4628")
	shadow.set_corner_radius_all(radius)
	g.draw_style_box(shadow, Rect2(rect.position + Vector2(1, 3), rect.size))
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var r := minf(float(radius), minf(rect.size.x, rect.size.y) / 2)
	var centers := [rect.position + Vector2(r, r), rect.position + Vector2(rect.size.x - r, r), rect.end - Vector2(r, r), rect.position + Vector2(r, rect.size.y - r)]
	for corner in range(4):
		for k in range(9):
			var angle := PI + corner * PI / 2 + k / 8.0 * PI / 2
			var point: Vector2 = centers[corner] + Vector2(cos(angle), sin(angle)) * r
			points.append(point)
			uvs.append((point - rect.position) / rect.size)
	var tint := Color(color.r / CREAM.r, color.g / CREAM.g, color.b / CREAM.b, color.a)
	g.draw_polygon(points, PackedColorArray([tint]), uvs, cream_paper)

func pill(center: Vector2, content: String, player: bool) -> void:
	var width := bold.get_string_size(content, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 22
	paper_box(Rect2(center - Vector2(width / 2, 12), Vector2(width, 24)), Color("f2c1b6") if player else CREAM, 12)
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
	var index: int = [3, 4, 5, 6][i]
	# Feet meet the top face 22% down the source oval, not the sprite bounds.
	_sprite(props[index], Rect2(feet - Vector2(52, 9), Vector2(104, 40)))

func jelly(feet: Vector2, i: int, flight: bool, hero: bool = false, size: float = 1.25) -> void:
	var r: Dictionary = g.racers[i]
	var wind := clampf(float(r.speed) / g.TERMINAL, 0, 1) if flight and g.state == "race" and not r.done else 0.0
	var clock: float = g.animation_time * (5 + wind * 14) + i
	var crashed: bool = flight and r.done and not r.safe
	var stretch := Vector2(1 + sin(clock) * 0.018, 1.0)
	stretch.y = 1.0 / stretch.x
	if flight and g.state == "race" and not r.open and not r.done:
		stretch = Vector2(1 - wind * 0.1 + sin(clock) * wind * 0.02, 1 + wind * 0.12)
	if flight and r.done:
		stretch = g._landing_stretch(r.squash, r.safe)
	var lean: float = sin(clock * 0.5) * wind * 0.025
	var root := Transform2D(lean, Vector2.ONE * size, 0, feet)
	var body_root := root * Transform2D(0, stretch, 0, Vector2.ZERO)
	var chute: bool = hero or (flight and r.open and not r.done)
	g.draw_set_transform_matrix(root)
	if chute:
		chute_at(i, 1.0 if hero else float(r.deploy), clock)
	# Paper ribbon follows airflow, attached behind the torso.
	var scarf_points := PackedVector2Array()
	for k in range(10):
		var t := k / 9.0
		scarf_points.append(Vector2(20 + t * (25 - wind * 10) + sin(clock - t * 5) * 4 * wind, -25 - t * (8 + wind * 58)))
	for k in range(9, -1, -1):
		var t := k / 9.0
		scarf_points.append(Vector2(13 + t * (25 - wind * 10) + sin(clock - t * 5) * 4 * wind, -25 - t * (8 + wind * 58)))
	g.draw_colored_polygon(scarf_points, [Color("d77b87"), Color("d69459"), Color("9f80ae"), Color("5b957d")][i])
	for side in [-1, 1]:
		var angle: float = side * (-0.28 - (1.95 if chute else wind * 2.1) + sin(clock + side) * wind * 0.15)
		g.draw_set_transform_matrix(body_root * Transform2D(angle, Vector2.ONE, 0, Vector2(side * 23, -31)))
		_sprite(arms[i], Rect2(-6, -2, 12, 29))
		g.draw_set_transform_matrix(body_root)
		if not crashed or r.squash < 0.35:
			_sprite(boots[i], Rect2(side * 14 - 6, -11, 12, 12))
	g.draw_set_transform_matrix(body_root)
	_sprite(bodies[i], Rect2(-28, -70, 56, 65))
	face(i, crashed, flight and not r.open and float(r.alt) < 25, clock, hero or (flight and (r.done or (r.open and float(r.alt) < 1.5))))
	g.draw_set_transform_matrix(root)
	if crashed:
		for k in range(3):
			g._star(Vector2(cos(g.animation_time * 3 + k * 2.1) * 31, -79 + sin(g.animation_time * 3 + k * 2.1) * 6), 5, Color("efd07d"))
	g.draw_set_transform_matrix(Transform2D.IDENTITY)

func face(i: int, dizzy: bool, panic: bool, clock: float, happy: bool) -> void:
	for side in [-1, 1]:
		var eye := Vector2(side * 10, -46)
		if dizzy:
			g._ellipse(eye, Vector2(7, 8), CREAM)
			var points := PackedVector2Array()
			for k in range(24):
				var angle := k / 23.0 * TAU * 1.5
				points.append(eye + Vector2(cos(angle), sin(angle)) * (0.5 + k / 23.0 * 4.5))
			g.draw_polyline(points, INK, 1.5, true)
		elif (happy and i in [0, 2]) or (i == 1 and not panic and side == -1):
			g.draw_arc(eye + Vector2(0, 3), 6, PI + 0.1, TAU - 0.1, 12, INK, 2, true)
		else:
			g._ellipse(eye + Vector2(0, 0.7), Vector2(7.5, 9), Color("92755c"))
			g._ellipse(eye, Vector2(7.5, 9), CREAM)
			g._ellipse(eye + Vector2(-1 if i == 3 else 1, 1), Vector2(3.8, 5.5), INK)
			g._ellipse(eye + Vector2(0, -1.5), Vector2(1.2, 1.6), Color.WHITE)
		g._ellipse(Vector2(side * 20, -34), Vector2(5, 3), Color("e9989670"))
		if not dizzy and not panic and not happy:
			g.draw_arc(eye + Vector2(0, -9), 5.5, PI + 0.25, TAU - 0.25, 12, INK, 1.5, true)
		if panic:
			g.draw_line(eye + Vector2(-5, -13), eye + Vector2(5, -16 * side), INK, 1.5, true)
	if dizzy:
		var points := PackedVector2Array()
		for k in range(13):
			points.append(Vector2(-8 + k * 1.3, -31 + sin(k * 0.9) * 1.5))
		g.draw_polyline(points, INK, 2, true)
	else:
		g._ellipse(Vector2(0, -30), Vector2(5 if panic else 9, 7 if panic else 6), Color("824c40"))
		g._ellipse(Vector2(1, -27), Vector2(4, 2), Color("e49a8d"))

func chute_at(i: int, deploy: float, clock: float) -> void:
	if deploy < 0.01:
		return
	var sway := sin(clock * 0.4) * 2
	for side in [-1, 1]:
		for anchor in [19.0, 46.0]:
			var start := Vector2(side * 21, -27)
			var end := Vector2(side * anchor * deploy + sway, -126 * deploy)
			g.draw_line(start + Vector2(1, 1), end + Vector2(1, 1), Color("836b4d55"), 2.3, true)
			g.draw_line(start, end, Color("f4e5c4"), 1.7, true)
	_sprite(canopies[i], Rect2(Vector2(-54 * deploy + sway, -193 * deploy), Vector2(108, 72) * deploy))

func bird(pos: Vector2, phase: float) -> void:
	g.draw_set_transform(pos, sin(phase) * 0.12, Vector2(1, 1 + sin(phase) * 0.12))
	_sprite(props[7], Rect2(-13, -8, 26, 17))
	g.draw_set_transform_matrix(Transform2D.IDENTITY)

func plane(pos: Vector2) -> void:
	paper_box(Rect2(pos - Vector2(200, 27), Vector2(400, 57)), CREAM, 28)
	g.draw_colored_polygon(PackedVector2Array([pos + Vector2(-35, -20), pos + Vector2(70, -80), pos + Vector2(93, -75), pos + Vector2(20, -8)]), CORAL)
	g.draw_colored_polygon(PackedVector2Array([pos + Vector2(-35, 15), pos + Vector2(70, 65), pos + Vector2(93, 60), pos + Vector2(20, 5)]), CORAL)
	for k in range(5):
		g._ellipse(pos + Vector2(-120 + k * 48, -5), Vector2(10, 11), Color("a8c9d8"))
	g.draw_line(pos + Vector2(210, -40), pos + Vector2(210, 40), INK, 5, true)




