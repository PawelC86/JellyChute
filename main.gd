extends Node2D
## All distances are metres. Drawing uses a fixed portrait canvas.
const W := 540.0
const H := 960.0
const JELLY_HEIGHT_METRES := 1.0
const PIXELS_PER_METRE := 63.0
const RACER_SCALE := 0.9
const CAMERA_LEAD_METRES := 294.0 / PIXELS_PER_METRE
const ALTITUDE := 48.0
const GRAVITY := 12.0
const TERMINAL := 12.0
const SAFE_SPEED := 2.5
const FIRST_LANDING_DELAY := 3.0
var first_landing_time := -1.0
const CAMERA_SETTLE_DURATION := 1.6
const GROUND_RESULTS_HOLD := 2.0
const NORMAL_FINISH_HOLD := 0.8
var settle_camera_offset := 0.0
const PHYSICS_STEP := 1.0 / 120.0
var red_altitude := 0.0
var player_skill := 0.5
var learned_rounds := 0
var round_player_skill := 0.5
const OPTIMAL_LOW := 16.0
const OPTIMAL_HIGH := 21.0
const CHARACTER_COLORS := [Color("ff779d"), Color("ffc857"), Color("a390ff"), Color("50dbbd"), Color("f5a66b"), Color("c99157"), Color("f67b76"), Color("5265a0"), Color("f3bc38"), Color("c6a4ed"), Color("98d4ca"), Color("b9e8f4"), Color("f16b7e")]
const CHARACTER_NAMES := ["STAR", "MANGO", "BUBBLES", "PICKLE", "SIR POUNCE", "BARKLEY", "TOASTY", "SNEAKY BEAN", "BUZZBERT", "SIR SPARKLES", "WOBBLEBOT", "BOOBERRY", "CHEF WOBBLE"]
const CHARACTER_TRAITS := ["BORN TO SHINE", "HAPPILY CLUELESS", "DRAMA WITH STYLE", "PROFESSIONALLY CHILL", "NINE LIVES. ONE CHUTE.", "GOOD DOG. GREAT DROP.", "SMALL WINGS. BIG BRAVERY.", "SILENT BUT WOBBLY", "TOO SWEET TO STING", "RAINBOWS BEFORE GRAVITY", "SOFT BODY. SMART CIRCUITS.", "BOO! ALSO: AAAH!", "FIVE-STAR FREEFALL"]
var COLORS: Array[Color] = [Color("ff779d"), Color("ffc857"), Color("a390ff"), Color("50dbbd")]
var NAMES: Array[String] = ["YOU", "MANGO", "BUBBLES", "PICKLE"]
var selected_character := 0
const CHUTE_IDS := ["underpants", "cow", "royal", "breakfast", "patched", "disco", "bling", "cat", "dog"]
const CHUTE_NAMES := ["STARFALL", "SUNNY SIDE", "CLOUD NINE", "CHECKMATE", "EMERGENCY UNDERPANTS", "HOLY COW!", "ROYAL FLUSH", "FLYING BREAKFAST", "DEFINITELY SAFE", "DISCO DROP", "BLING BLING", "PURRFECT LANDING", "WOOF WOOF"]
const CHUTE_PRICES := [0, 0, 0, 0, 150, 150, 200, 150, 200, 200, 500, 200, 200]
const CHUTE_SHOP_ORDER := [4, 5, 6, 7, 8, 9, 11, 10, 12]
var selected_chute := 0
var owned_chutes: Array[int] = [0, 1, 2, 3]
var chute_buttons: Array[Button] = []
var character_confirmed := false
var racer_skins: Array[int] = [0, 1, 2, 3]
var character_buttons: Array[Button] = []
var carousel_time := 1.0
var carousel_direction := 1.0
const CAROUSEL_DURATION := 0.42
const POINTS := [10, 7, 4, 2]
const CHARACTER_PRICES := [0, 0, 0, 0, 500, 500, 300, 300, 200, 500, 300, 200, 200]
# Earlier deployments cost time; all opponents use the player's flight physics.
const RIVAL_DEPLOY_RANGES := [Vector2(18.6, 20.0), Vector2(17.0, 18.6), Vector2(16.0, 17.0)]
var rival_round_form := 0.0
const DIFFICULTY_NAMES := ["CHILL JELLIES", "WOBBLE PROS", "JELLY ACES"]
var difficulty_order: Array[int] = [0, 1, 2]
var racers: Array[Dictionary] = []
var totals: Array[int] = [0, 0, 0, 0]
var state := "menu"
var round_number := 1
var timer := 0.0
var race_time := 0.0
var start_altitude := ALTITUDE
var camera_alt := ALTITUDE
var finish_order: Array[int] = []
var best_time := 0.0
var wins := 0
var career_points := 0
var credits := 0
var owned_characters: Array[int] = [0, 1, 2, 3]
var rounds_completed := 0
var tournament_paid := false
var tournament_reward := 0
var shop_message := ""
var displayed_career_points := 0.0
var round_scored := false
var sound: AudioStreamPlayer
var ui: Control
var action: Button
var action_hint: Label
var home_button: Button
var menu_side_buttons: Array[Button] = []
var shop_tabs: Array[Button] = []
var shop_category := 0
var heading: Label
var detail: Label
var badge: Label
var stats: Label
var particles: Array[Dictionary] = []
var dust: Array[Dictionary] = []
var toon_art: RefCounted
var rng := RandomNumberGenerator.new()
var animation_time := 0.0
var countdown_number := 3
var jump_flash := 0.0
var hat_rotor_angle := 0.0
var hat_rotor_speed := 1.2
var dialogue_rng := RandomNumberGenerator.new()
var podium_dialogue_time := 0.0
var podium_speaker := 0
var podium_line := ""
var previous_podium_lines: Array[String] = ["", "", ""]
const PLATFORM_SIGNS := ["CERTIFIED BAD IDEA", "NO REFUNDS AFTER JUMP", "GRAVITY TESTED DAILY", "LEAVE DIGNITY HERE", "MIND THE VERY BIG STEP", "FLYING IS JUST FALLING", "PLEASE WOBBLE SAFELY", "ZERO FLIGHT EXPERIENCE", "CHUTES SOLD SEPARATELY", "DO NOT FEED THE CLOUDS", "NEXT FLOOR: THE FLOOR", "INSPECTED BY A PIGEON"]
var platform_sign := "CERTIFIED BAD IDEA"
const PLACE_JOKES := [
	["ALL HAIL THE WOBBLE!", "GRAVITY WORKS FOR ME!", "I ACCEPT SNACKS!", "BORN TO BOUNCE!", "MY EGO NEEDS A CHUTE!", "CROWN FITS. OBVIOUSLY.", "PLEASE HOLD YOUR GASPS!", "FIRST CLASS JELLY!", "CALL MY JELLY AGENT!", "I LANDED. YOU CLAPPED."],
	["I WAS BEING POLITE!", "FIRST IS SO MAINSTREAM!", "I LET YOU HAVE THAT!", "SILVER MATCHES MY EYES!", "MY CHUTE HAD LAG!", "I DEMAND A RE-WOBBLE!", "SAVING FIRST FOR LATER!", "SECOND TO NONE. ALMOST.", "I BLAME THE CLOUDS!", "GOLD WAS TOO HEAVY!"],
	["MY KNEES ARE JELLY!", "STILL MOSTLY SOLID!", "IS THE GROUND ALWAYS HERE?", "THIRD HELPING, PLEASE!", "I BROUGHT THE WOBBLE!", "MY BOOTS LANDED FIRST!", "MUM, I MADE THE BOX!", "AT LEAST I AM DESSERT!", "CAN I SIT DOWN NOW?", "BRONZE IS CRUNCHY GOLD!"]
]
const CHARACTER_JOKES := [
	["DID MY HAIR WIN TOO?", "NO AUTOGRAPHS IN FLIGHT!", "GOOD HAIR. GREAT AIR."],
	["WHO PACKED THE SNACKS?", "GOGGLES: ON. BRAIN: OFF.", "WAS THAT THE PRACTICE?"],
	["MY BERET DESERVES GOLD!", "A MOST ELEGANT DESCENT!", "DRAMA? I CALL IT STYLE."],
	["MY HAT DID ALL THE WORK!", "WAKE ME FOR THE CAKE.", "PROPELLER. STILL NO LIFT."],
	["I MEANT TO LAND THERE.", "EIGHT LIVES LEFT!", "PURRFECT LANDING."],
	["WHO IS A GOOD PILOT?", "DID SOMEONE SAY TREAT?", "TAILWIND INCLUDED!"],
	["MY WINGS ARE DECORATIVE!", "THAT WAS JUST A WARM-UP.", "FIRE? I PREFER JELLY."],
	["YOU NEVER SAW ME FALL.", "STEALTH MODE: WOBBLY.", "GRAVITY FOUND ME."],
	["BUZZING WITH TALENT!", "MY WINGS NEED A BREAK.", "HONEY, I LANDED!"],
	["RAINBOW EXPRESS!", "MY MANE LANDED FIRST.", "MAGIC NEEDS A CHUTE TOO."],
	["LANDING.EXE COMPLETE.", "ERROR: TOO MUCH GRAVITY.", "REBOOTING MY DIGNITY."],
	["I SCARED MYSELF!", "BOO WAS THE PLAN.", "STILL AFRAID OF HEIGHTS."],
	["A PERFECT JELLY SOUFFLE!", "AL DENTE LANDING.", "THE FLOOR NEEDS SALT."]
]

func _ready() -> void:
	rng.randomize()
	dialogue_rng.randomize()
	red_altitude = braking_distance(TERMINAL)
	_load_record()
	displayed_career_points = float(credits)
	_assign_characters()
	_make_sound()
	_make_ui()
	toon_art = preload("res://toon_art.gd").new(self)
	toon_art.configure_ui()
	_reset_racers()
	_menu()

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	heading = _label(30, 95, 480, 120, 39)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail = _label(35, 238, 470, 330, 22)
	badge = _label(35, 25, 360, 40, 18)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats = _label(25, 797, 490, 50, 17)
	stats.add_theme_color_override("font_color", Color("fff7df"))
	action = Button.new()
	action.position = Vector2(30, 852)
	action.size = Vector2(480, 84)
	action.add_theme_font_size_override("font_size", 25)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("ffce67")
	normal.border_color = Color("d99a49")
	normal.border_width_bottom = 5
	normal.set_corner_radius_all(22)
	normal.shadow_color = Color("254b6520")
	normal.shadow_size = 7
	normal.shadow_offset = Vector2(0, 5)
	action.add_theme_stylebox_override("normal", normal)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("ffb952")
	action.add_theme_stylebox_override("pressed", pressed)
	action.add_theme_stylebox_override("hover", normal)
	var disabled_style := normal.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color("a4bec7")
	disabled_style.border_color = Color("8ba7b3")
	action.add_theme_stylebox_override("disabled", disabled_style)
	action.add_theme_color_override("font_disabled_color", Color("f3fbff"))
	action.add_theme_color_override("font_color", Color("30344f"))
	action.add_theme_color_override("font_hover_color", Color("30344f"))
	action.add_theme_color_override("font_pressed_color", Color("30344f"))
	action.pressed.connect(_action)
	ui.add_child(action)
	action_hint = Label.new()
	action_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	action_hint.offset_left = 12
	action_hint.offset_right = -12
	action_hint.offset_top = -29
	action_hint.offset_bottom = -9
	action_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_hint.add_theme_font_size_override("font_size", 12)
	action.add_child(action_hint)
	home_button = Button.new()
	home_button.position = Vector2(438, 23)
	home_button.size = Vector2(82, 57)
	home_button.text = "MENU"
	home_button.tooltip_text = "Back to main menu"
	home_button.focus_mode = Control.FOCUS_NONE
	home_button.mouse_filter = Control.MOUSE_FILTER_STOP
	home_button.pressed.connect(_return_to_menu)
	ui.add_child(home_button)
	# Reserved menu actions: visual feedback only until options/shop are implemented.
	for item in [["options", 58.0, "Options"], ["shop", 422.0, "Shop"]]:
		var button := Button.new()
		button.name = "OptionsButton" if item[0] == "options" else "ShopButton"
		button.position = Vector2(item[1], 746)
		button.size = Vector2(60, 60)
		button.icon = load("res://assets/icons/menu-%s.svg" % item[0])
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.tooltip_text = item[2]
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		ui.add_child(button)
		menu_side_buttons.append(button)
		if item[0] == "shop":
			button.pressed.connect(_open_shop)
	for category in range(2):
		var tab := Button.new()
		tab.position = Vector2(28 + category * 246, 190)
		tab.size = Vector2(238, 64)
		tab.text = "JELLIES" if category == 0 else "PARACHUTES"
		tab.focus_mode = Control.FOCUS_NONE
		tab.pressed.connect(_select_shop_tab.bind(category))
		ui.add_child(tab)
		shop_tabs.append(tab)
	for direction in [-1, 1]:
		var button := Button.new()
		button.position = Vector2(42 if direction == -1 else 426, 479)
		button.size = Vector2(72, 76)
		button.text = "‹" if direction == -1 else "›"
		button.tooltip_text = "Previous jelly" if direction == -1 else "Next jelly"
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 48)
		button.pressed.connect(_cycle_character.bind(direction))
		ui.add_child(button)
		character_buttons.append(button)
	for direction in [-1, 1]:
		var button := Button.new()
		button.position = Vector2(42 if direction == -1 else 426, 346)
		button.size = Vector2(72, 64)
		button.text = "‹" if direction == -1 else "›"
		button.tooltip_text = "Previous parachute" if direction == -1 else "Next parachute"
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 42)
		button.pressed.connect(_cycle_chute.bind(direction))
		ui.add_child(button)
		chute_buttons.append(button)

func _label(x: float, y: float, width: float, height: float, font_size: int) -> Label:
	var label := Label.new()
	label.position = Vector2(x, y)
	label.size = Vector2(width, height)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("30344f"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(label)
	return label

func _reset_racers() -> void:
	round_scored = false
	first_landing_time = -1.0
	racers.clear()
	finish_order.clear()
	particles.clear()
	dust.clear()
	for i in range(4):
		racers.append({"alt": start_altitude, "speed": 0.0, "open": false,
			"deploy": 0.0, "done": false, "safe": false, "time": 0.0,
			"target": _rival_deploy_height(), "deploy_altitude": -1.0, "deploy_speed": 0.0, "squash": 0.0, "finish_age": 0.0})
	camera_alt = start_altitude
	race_time = 0.0

func _menu() -> void:
	state = "menu"
	for label in [heading, detail, badge, stats]:
		label.visible = false
	action.position = Vector2(48, 822)
	action.size = Vector2(444, 86)
	action.add_theme_font_size_override("font_size", 29)
	action.text = "CONFIRM & JUMP!"
	action.disabled = false
	toon_art.sync_ui()

func _open_shop() -> void:
	state = "shop"
	shop_category = 0
	shop_message = ""
	toon_art.sync_ui()
	queue_redraw()

func _select_shop_tab(category: int) -> void:
	shop_category = clampi(category, 0, 1)
	shop_message = ""
	toon_art.sync_ui()
	queue_redraw()

func _action() -> void:
	match state:
		"menu", "podium":
			if state == "menu" and (not owns_character(selected_character) or not owns_chute(selected_chute)):
				_open_shop()
				return
			if state == "menu":
				character_confirmed = true
				_save_record()
			rounds_completed = 0
			tournament_paid = false
			tournament_reward = 0
			totals = [0, 0, 0, 0]
			round_number = 1
			_shuffle_difficulties()
			_start_round()
		"results":
			if round_number == 3:
				_podium()
			else:
				round_number += 1
				_start_round()
		"race":
			_deploy(0)

func _unhandled_input(event: InputEvent) -> void:
	if state == "menu" and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_UP, KEY_DOWN]:
			_cycle_chute(-1 if event.keycode == KEY_UP else 1)
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_LEFT, KEY_RIGHT]:
			_cycle_character(-1 if event.keycode == KEY_LEFT else 1)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and state != "menu":
		_return_to_menu()
		get_viewport().set_input_as_handled()
		return
	if state != "race":
		return
	if event is InputEventScreenTouch and event.pressed:
		_deploy(0)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_deploy(0)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_deploy(0)

func _start_round() -> void:
	_roll_platform_sign()
	for label in [heading, detail, badge, stats]:
		label.visible = true
	action.position = Vector2(30, 852)
	action.size = Vector2(480, 84)
	action.add_theme_font_size_override("font_size", 23)
	# At 12m/s terminal speed, acceleration adds half a second.
	start_altitude = OPTIMAL_HIGH + TERMINAL * (rng.randf_range(2.0, 4.0) - 0.5)
	round_player_skill = player_skill
	rival_round_form = rng.randf_range(-0.7, 0.7)
	_reset_racers()
	state = "countdown"
	heading.add_theme_font_size_override("font_size", 64)
	timer = 3.0
	countdown_number = 3
	jump_flash = 0.0
	_tone(440.0, 0.09)
	heading.text = "3"
	detail.text = ""
	stats.text = "You are " + CHARACTER_NAMES[selected_character]
	badge.text = "ROUND %d / 3" % round_number
	action.text = "GET READY..."
	action.disabled = true
	toon_art.sync_ui()

func _deploy(i: int) -> void:
	if state not in ["race", "settle"] or racers[i].open or racers[i].done:
		return
	racers[i].deploy_altitude = float(racers[i].alt)
	racers[i].deploy_speed = float(racers[i].speed)
	racers[i].open = true
	if i == 0:
		action.text = "CHUTE OPEN!"
		_tone(660.0, 0.12)

func _process(delta: float) -> void:
	if state == "menu":
		displayed_career_points = move_toward(displayed_career_points, float(credits), maxf(12.0, absf(credits - displayed_career_points) * 7.0) * delta)
	if state in ["results", "podium"]:
		_advance_podium_dialogue(delta)
	carousel_time = minf(CAROUSEL_DURATION, carousel_time + delta)
	animation_time += delta
	var rotor_target := 1.2
	var pickle_slot := racer_skins.find(3)
	if state == "race" and pickle_slot >= 0 and not racers[pickle_slot].done:
		rotor_target += float(racers[pickle_slot].speed) * 2.7
	hat_rotor_speed = lerpf(hat_rotor_speed, rotor_target, 1.0 - exp(-delta * 4.0))
	hat_rotor_angle = fposmod(hat_rotor_angle + hat_rotor_speed * delta, TAU)
	jump_flash = maxf(0.0, jump_flash - delta)
	timer -= delta
	if state == "settle":
		if finish_order.size() < racers.size():
			race_time += delta
		_advance_racers(delta)
		var progress := clampf(1.0 - (timer - GROUND_RESULTS_HOLD) / CAMERA_SETTLE_DURATION, 0.0, 1.0)
		# Quintic easing has zero velocity and acceleration at both ends.
		var eased := progress * progress * progress * (progress * (progress * 6.0 - 15.0) + 10.0)
		camera_alt = CAMERA_LEAD_METRES + settle_camera_offset * (1.0 - eased)
	for r in racers:
		if r.done:
			r.finish_age += delta
			r.squash = maxf(0.0, r.squash - delta * (2.5 if r.safe else 0.9))
	for p in particles:
		p.pos += p.vel * delta
		p.vel.y += 120.0 * delta
		p.life -= delta
	particles = particles.filter(func(p): return p.life > 0.0)
	for puff in dust:
		puff.age += delta
		puff.pos += puff.vel * delta
		puff.vel *= maxf(0.0, 1.0 - delta * 1.3)
		puff.radius += delta * 12.0
	dust = dust.filter(func(puff): return puff.age < puff.duration)
	if state == "countdown":
		var digit := clampi(ceili(timer), 1, 3)
		if digit != countdown_number:
			countdown_number = digit
			_tone(440.0 + (3 - digit) * 110.0, 0.09)
		heading.text = str(digit) + "..."
		heading.scale = Vector2.ONE * (1.0 + 0.08 * fposmod(timer, 1.0))
		heading.pivot_offset = heading.size * 0.5
		if timer <= 0.0:
			state = "race"
			jump_flash = 0.65
			heading.scale = Vector2.ONE
			heading.text = "GO!"
			action.disabled = false
			action.text = "OPEN PARACHUTE"
			_tone(880.0, 0.15)
	elif state == "race":
		if finish_order.size() < racers.size():
			race_time += delta
		heading.text = "GO!" if jump_flash > 0.0 else ""
		_advance_racers(delta)
		var lowest := float(racers[0].alt)
		if racers[0].done:
			lowest = 0.0
		camera_alt = lerpf(camera_alt, lowest, minf(1.0, delta * 18.0))
		stats.text = "%.1f m   •   %.1f m/s   •   %.1f s\n%s" % [racers[0].alt, racers[0].speed, race_time, _flight_hint()]
		if finish_order.size() == 4 or (first_landing_time >= 0.0 and race_time - first_landing_time >= FIRST_LANDING_DELAY):
			settle_camera_offset = maxf(camera_alt - CAMERA_LEAD_METRES, 0.0)
			state = "settle"
			if settle_camera_offset > 0.05:
				timer = CAMERA_SETTLE_DURATION + GROUND_RESULTS_HOLD
			else:
				settle_camera_offset = 0.0
				timer = NORMAL_FINISH_HOLD
			action.disabled = true
	elif state == "settle" and timer <= 0.0:
		# Resolve classification only after the live finish-line view ends.
		while finish_order.size() < 4:
			race_time += PHYSICS_STEP
			_advance_racers(PHYSICS_STEP)
		_results()
	toon_art.sync_ui()
	queue_redraw()

func _advance_racers(delta: float) -> void:
	for i in range(4):
		var r: Dictionary = racers[i]
		if r.done:
			continue
		var remaining := delta
		while remaining > 0.000001 and not r.done:
			var step := minf(PHYSICS_STEP, remaining)
			remaining -= step
			if i > 0 and r.alt <= r.target:
				_deploy(i)
			if r.open:
				r.deploy = minf(1.0, r.deploy + step / 0.65)
				r.speed = move_toward(r.speed, 8.0 if r.alt > 35.0 else 2.0, 8.0 * r.deploy * step)
			else:
				r.speed = minf(TERMINAL, r.speed + GRAVITY * step)
			r.alt = maxf(0.0, r.alt - r.speed * step)
			if r.alt <= 0.0:
				_land(i)

func _flight_hint() -> String:
	if racers[0].done:
		return "BUTTER-SOFT LANDING!" if racers[0].safe else "PANCAKE DELIVERY!"
	if racers[0].open:
		return "Hold on to your cheeks!"
	if racers[0].alt < OPTIMAL_LOW:
		return "PULL! Pancakes are not a body type!"
	if racers[0].alt <= OPTIMAL_HIGH:
		return "PULL NOW! Save your wobble!"
	return "Wait for it..."

func _land(i: int) -> void:
	var r: Dictionary = racers[i]
	if finish_order.is_empty():
		first_landing_time = race_time
	r.done = true
	r.safe = r.speed <= SAFE_SPEED
	r.speed = 0.0
	r.time = race_time
	r.squash = 1.0
	r.finish_age = 0.0
	finish_order.append(i)
	if not r.safe:
		_spawn_dust(i)
	for k in range(12):
		particles.append({"pos": Vector2(_lane_x(i), -8),
			"vel": Vector2(rng.randf_range(-90, 90), rng.randf_range(-140, -30)),
			"life": rng.randf_range(0.4, 1.0), "color": COLORS[i]})
	if i == 0:
		_tone(440.0 if r.safe else 100.0, 0.2)
		if r.safe and (best_time == 0.0 or race_time < best_time):
			best_time = race_time
			_save_record()

func _ranked() -> Array[int]:
	var order: Array[int] = []
	for i in finish_order:
		if racers[i].safe:
			order.append(i)
	for i in finish_order:
		if not racers[i].safe:
			order.append(i)
	return order

func _results() -> void:
	if round_scored:
		return
	round_scored = true
	state = "results"
	_begin_podium_dialogue()
	var order := _ranked()
	heading.add_theme_font_size_override("font_size", 39)
	heading.text = "SMOOTH MOVES!" if racers[0].safe else "OH, CREPE!"
	detail.text = "ROUND %d RESULTS\n\n" % round_number
	for rank in range(4):
		var i := order[rank]
		var points: int = POINTS[rank] if racers[i].safe else 0
		totals[i] += points
		detail.text += "%d. %s   %s   +%d\n" % [rank + 1, NAMES[i], _time_text(racers[i].time) if racers[i].safe else "SPLAT", points]
	rounds_completed += 1
	_learn_player_round(order.find(0))
	if rounds_completed == 3 and round_number == 3:
		_settle_tournament()
	else:
		_save_record()
	stats.text = "TOTAL POINTS   YOU %d  •  MANGO %d\nBUBBLES %d  •  PICKLE %d" % totals
	action.text = "SHOW PODIUM" if round_number == 3 else "NEXT ROUND"
	action.disabled = false

func _podium() -> void:
	state = "podium"
	_begin_podium_dialogue()
	heading.add_theme_font_size_override("font_size", 36)
	var order: Array[int] = [0, 1, 2, 3]
	order.sort_custom(func(a, b):
		if totals[a] == totals[b]:
			return order_tiebreak(a) < order_tiebreak(b)
		return totals[a] > totals[b])
	_settle_tournament()
	heading.text = "YOU TAKE THE CROWN!" if order[0] == 0 else "%s WINS!" % NAMES[order[0]]
	detail.text = "FLIGHT CLUB PODIUM\n\n"
	for rank in range(4):
		detail.text += "%d. %s     %d pts\n" % [rank + 1, NAMES[order[rank]], totals[order[rank]]]
	detail.text += "\nTied scores: final round decides."
	stats.text = "WINS  %d     •     BEST  %s" % [wins, _time_text(best_time)]
	action.text = "ONE MORE TOURNAMENT!"

func _settle_tournament() -> void:
	if tournament_paid or rounds_completed != 3 or round_number != 3:
		return
	var reward := totals[0]
	var old_wins := wins
	var order := reaction_order() if state == "podium" else _tournament_order()
	credits += reward
	career_points += reward
	if order[0] == 0:
		wins += 1
	if _save_record() == OK:
		tournament_paid = true
		tournament_reward = reward
	else:
		credits -= reward
		career_points -= reward
		wins = old_wins

func _tournament_order() -> Array[int]:
	var order: Array[int] = [0, 1, 2, 3]
	order.sort_custom(func(a: int, b: int) -> bool: return totals[a] > totals[b] if totals[a] != totals[b] else order_tiebreak(a) < order_tiebreak(b))
	return order

func owns_character(character: int) -> bool:
	return character >= 0 and character < CHARACTER_NAMES.size() and character in owned_characters

func owns_chute(chute: int) -> bool:
	return chute >= 0 and chute < CHUTE_NAMES.size() and chute in owned_chutes

func _shop_chute_action(chute: int) -> void:
	if state != "shop" or shop_category != 1 or chute < 4 or chute >= CHUTE_NAMES.size():
		return
	shop_message = ""
	if owns_chute(chute):
		var previous := selected_chute
		var was_confirmed := character_confirmed
		selected_chute = chute
		character_confirmed = true
		if _save_record() != OK:
			selected_chute = previous
			character_confirmed = was_confirmed
			shop_message = "SAVE FAILED. PLEASE TRY AGAIN."
	else:
		var price: int = CHUTE_PRICES[chute]
		if credits < price:
			shop_message = "%d MORE CREDITS NEEDED" % (price - credits)
		else:
			credits -= price
			owned_chutes.append(chute)
			if _save_record() != OK:
				credits += price
				owned_chutes.erase(chute)
				shop_message = "SAVE FAILED. PLEASE TRY AGAIN."
			else:
				shop_message = "%s UNLOCKED!" % CHUTE_NAMES[chute]
	toon_art.sync_ui()
	queue_redraw()

func _shop_character_action(character: int) -> void:
	if state != "shop" or shop_category != 0 or character < 4 or character >= CHARACTER_NAMES.size():
		return
	shop_message = ""
	if owns_character(character):
		var previous := selected_character
		var was_confirmed := character_confirmed
		selected_character = character
		character_confirmed = true
		if _save_record() != OK:
			selected_character = previous
			character_confirmed = was_confirmed
			shop_message = "SAVE FAILED. PLEASE TRY AGAIN."
		else:
			_assign_characters()
			_reset_racers()
	else:
		var price: int = CHARACTER_PRICES[character]
		if credits < price:
			shop_message = "%d MORE CREDITS NEEDED" % (price - credits)
		else:
			credits -= price
			owned_characters.append(character)
			if _save_record() != OK:
				credits += price
				owned_characters.erase(character)
				shop_message = "SAVE FAILED. PLEASE TRY AGAIN."
			else:
				shop_message = "%s UNLOCKED!" % CHARACTER_NAMES[character]
	toon_art.sync_ui()
	queue_redraw()

func order_tiebreak(i: int) -> int:
	return _ranked().find(i)

# The jelly origin is its sole: altitude zero always touches the pad top.
func _ground_y() -> float:
	return 690.0 + maxf(camera_alt - CAMERA_LEAD_METRES, 0.0) * PIXELS_PER_METRE

func _lane_x(i: int) -> float:
	return 151.0 + i * 100.0

func _racer_feet(i: int) -> Vector2:
	return Vector2(_lane_x(i), _ground_y() - float(racers[i].alt) * PIXELS_PER_METRE)

func _draw() -> void:
	if toon_art != null:
		toon_art.render()

func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for k in range(48):
		var a := TAU * k / 48.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, color)

func _text(center: Vector2, content: String, font_size: int, color: Color) -> void:
	toon_art.text_at(center, content, font_size, color)

func _cloud(pos: Vector2, size: float) -> void:
	toon_art.cloud(pos, size)

func _star(center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array()
	for k in range(10):
		var angle := -PI / 2 + TAU * k / 10.0
		points.append(center + Vector2(cos(angle), sin(angle)) * size * (1.0 if k % 2 == 0 else 0.45))
	draw_colored_polygon(points, color)

func _time_text(value: float) -> String:
	return "--" if value <= 0 else "%.2fs" % value

# App-owned key keeps local scores opaque; it is not a server-side anti-cheat secret.
const SAVE_PASSWORD := "JellyChute:WobbleVault:2026:9c2f7a4e6d108b35"
var save_path := "user://records.dat"
var legacy_save_path := "user://records.cfg"
var save_blocked := false

func _load_record() -> void:
	var config := ConfigFile.new()
	var migrating := false
	if FileAccess.file_exists(save_path):
		if config.load_encrypted_pass(save_path, SAVE_PASSWORD) != OK:
			save_blocked = true
			push_warning("Cannot read saved progress; preserving the existing file.")
			return
	elif FileAccess.file_exists(legacy_save_path):
		if config.load(legacy_save_path) != OK:
			save_blocked = true
			push_warning("Cannot read legacy progress; preserving the existing file.")
			return
		migrating = true
	else:
		return
	save_blocked = false
	best_time = maxf(0.0, float(config.get_value("records", "best_time", 0.0)))
	wins = maxi(0, int(config.get_value("records", "wins", 0)))
	career_points = maxi(0, int(config.get_value("records", "career_points", 0)))
	selected_character = clampi(int(config.get_value("settings", "character", 0)), 0, CHARACTER_NAMES.size() - 1)
	selected_chute = clampi(int(config.get_value("settings", "chute", selected_character % 4)), 0, CHUTE_NAMES.size() - 1)
	var chute_migration := not config.has_section_key("wallet", "owned_chutes")
	owned_chutes.assign([0, 1, 2, 3])
	for value in config.get_value("wallet", "owned_chutes", []):
		var chute := int(value)
		if chute >= 4 and chute < CHUTE_NAMES.size() and chute not in owned_chutes:
			owned_chutes.append(chute)
	if not owns_chute(selected_chute):
		selected_chute = 0
	var economy_migration := not config.has_section_key("wallet", "credits")
	credits = maxi(0, int(config.get_value("wallet", "credits", career_points)))
	owned_characters.assign([0, 1, 2, 3])
	for value in config.get_value("wallet", "owned_characters", []):
		var character := int(value)
		if character >= 4 and character < CHARACTER_NAMES.size() and character not in owned_characters:
			owned_characters.append(character)
	# Preserve a previously confirmed premium character when upgrading old saves.
	if economy_migration and selected_character >= 4:
		owned_characters.append(selected_character)
	if not owns_character(selected_character):
		selected_character = 0
	character_confirmed = config.has_section_key("settings", "character")
	player_skill = clampf(float(config.get_value("adaptive", "skill", 0.5)), 0, 1)
	learned_rounds = maxi(0, int(config.get_value("adaptive", "rounds", 0)))
	if (economy_migration or chute_migration) and not migrating:
		_save_record()
	if migrating and _save_record() == OK:
		# Remove plaintext only after the encrypted replacement was verified.
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_save_path))
		if error != OK:
			push_warning("Encrypted progress saved, but the legacy file could not be removed.")

func _save_record() -> Error:
	if save_blocked:
		return ERR_FILE_CORRUPT
	var config := ConfigFile.new()
	config.set_value("records", "best_time", best_time)
	config.set_value("records", "wins", wins)
	config.set_value("records", "career_points", career_points)
	config.set_value("wallet", "credits", credits)
	config.set_value("wallet", "owned_characters", owned_characters)
	config.set_value("wallet", "owned_chutes", owned_chutes)
	config.set_value("adaptive", "skill", player_skill)
	config.set_value("adaptive", "rounds", learned_rounds)
	if character_confirmed:
		config.set_value("settings", "character", selected_character)
		config.set_value("settings", "chute", selected_chute)
	var temporary := save_path + ".tmp"
	var error := config.save_encrypted_pass(temporary, SAVE_PASSWORD)
	if error == OK:
		var verification := ConfigFile.new()
		error = verification.load_encrypted_pass(temporary, SAVE_PASSWORD)
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(save_path))
	if error != OK:
		push_warning("Progress could not be saved; the previous save was preserved.")
	return error

func _make_sound() -> void:
	sound = AudioStreamPlayer.new()
	add_child(sound)

func _tone(frequency: float, duration: float) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var frames := int(22050 * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for frame in range(frames):
		var sample := sin(TAU * frequency * frame / 22050.0) * 0.18 * (1.0 - float(frame) / frames)
		bytes.encode_s16(frame * 2, int(sample * 32767))
	stream.data = bytes
	sound.stream = stream
	sound.play()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_save_record()
		get_tree().paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		get_tree().paused = false

func _world_y(altitude: float, parallax: float = 1.0) -> float:
	# Every foreground object shares the jelly's metres-to-pixels conversion.
	return 690.0 + (maxf(camera_alt - CAMERA_LEAD_METRES, 0.0) - altitude) * PIXELS_PER_METRE * parallax

func _draw_flight_world() -> void:
	if state == "countdown":
		return
	# Near cloud banks overtake the racers upward. Far clouds move more slowly.
	for k in range(12):
		var altitude := 8.0 + k * 11.0
		var y := _world_y(altitude, 0.45)
		if y > 110 and y < 780:
			_cloud(Vector2(-22 if k % 2 == 0 else 565, y), 1.5)
	# Five discrete flocks, sized at about 0.35 m wingspan (25px).
	for flock in range(5):
		var altitude := 18.0 + flock * 21.0
		for bird_index in range(3):
			var y := _world_y(altitude + bird_index * 0.35)
			if y < 115 or y > 765:
				continue
			var direction := 1.0 if flock % 2 == 0 else -1.0
			var x := fposmod(60 + flock * 97 + bird_index * 43 + animation_time * 35 * direction, 500) + 20
			_bird(Vector2(x, y), animation_time * 11 + bird_index)
	# Streak displacement is driven by actual descent, not an unrelated timer.
	var speed := 0.0 if racers[0].done else float(racers[0].speed)
	var intensity := clampf(speed / TERMINAL, 0.0, 1.0)
	if intensity < 0.15:
		return
	for k in range(22):
		var x := float((k * 83 + 7) % 530) + 5
		var travelled := (start_altitude - camera_alt) * PIXELS_PER_METRE
		var y := fposmod(k * 137.0 - travelled * (0.65 + (k % 3) * 0.18), 650.0) + 110
		var length := lerpf(7, 62, intensity) * (0.5 + (k % 3) * 0.25)
		draw_line(Vector2(x, y), Vector2(x, y - length), Color(1, 1, 1, 0.16 + intensity * 0.3), 1.5, true)

func _bird(pos: Vector2, phase: float) -> void:
	toon_art.bird(pos, phase)

func _landing_stretch(impact: float, safe: bool) -> Vector2:
	if safe:
		var width := 1.0 + impact * 0.27
		return Vector2(width, 1.0 / width)
	var progress := 1.0 - impact
	var rebound := sin(progress * PI * 3) * sin(progress * PI) * 0.1
	return Vector2(1.0 + impact * 0.65 - rebound, 1.0 - impact * 0.72 + rebound)







func _spawn_dust(i: int) -> void:
	for k in range(10):
		dust.append({"pos": Vector2(_lane_x(i) + rng.randf_range(-24, 24), rng.randf_range(-8, 0)),
			"vel": Vector2(rng.randf_range(-56, 56), rng.randf_range(-45, -14)),
			"radius": rng.randf_range(7, 14), "age": 0.0, "duration": rng.randf_range(0.75, 1.15)})

func live_order() -> Array[int]:
	var order: Array[int] = [0, 1, 2, 3]
	order.sort_custom(func(a: int, b: int) -> bool:
		var ra: Dictionary = racers[a]
		var rb: Dictionary = racers[b]
		var category_a := 0 if ra.done and ra.safe else (2 if ra.done else 1)
		var category_b := 0 if rb.done and rb.safe else (2 if rb.done else 1)
		if category_a != category_b:
			return category_a < category_b
		if category_a != 1 and ra.time != rb.time:
			return ra.time < rb.time
		if category_a == 1 and ra.alt != rb.alt:
			return ra.alt < rb.alt
		return a < b)
	return order

func reaction_order() -> Array[int]:
	if state != "podium":
		return live_order()
	var order: Array[int] = [0, 1, 2, 3]
	order.sort_custom(func(a: int, b: int) -> bool:
		if totals[a] == totals[b]:
			return order_tiebreak(a) < order_tiebreak(b)
		return totals[a] > totals[b])
	return order



func _assign_characters() -> void:
	racer_skins.assign([selected_character])
	if selected_character < 4:
		for character in range(4):
			if character != selected_character:
				racer_skins.append(character)
	else:
		for offset in range(1, 4):
			racer_skins.append((selected_character + offset) % CHARACTER_NAMES.size())
	for slot in range(4):
		COLORS[slot] = CHARACTER_COLORS[racer_skins[slot]]
		NAMES[slot] = "YOU" if slot == 0 else CHARACTER_NAMES[racer_skins[slot]]

func _select_character(character: int) -> void:
	if state != "menu" or not owns_character(character):
		return
	if selected_character != character:
		carousel_time = 0.0
	selected_character = character
	_assign_characters()
	_reset_racers()
	_menu()
	queue_redraw()

func _cycle_character(direction: int) -> void:
	if state != "menu":
		return
	carousel_direction = 1.0 if direction > 0 else -1.0
	for step in range(1, CHARACTER_NAMES.size() + 1):
		var candidate := posmod(selected_character + direction * step, CHARACTER_NAMES.size())
		if owns_character(candidate):
			_select_character(candidate)
			break

func _cycle_chute(direction: int) -> void:
	if state != "menu":
		return
	carousel_direction = 1.0 if direction > 0 else -1.0
	carousel_time = 0.0
	for step in range(1, CHUTE_NAMES.size() + 1):
		var candidate := posmod(selected_chute + direction * step, CHUTE_NAMES.size())
		if owns_chute(candidate):
			selected_chute = candidate
			break
	queue_redraw()

func chute_skin(slot: int) -> int:
	return selected_chute if slot == 0 else racer_skins[slot] % 4

func _return_to_menu() -> void:
	rounds_completed = 0
	tournament_paid = false
	tournament_reward = 0
	totals.assign([0, 0, 0, 0])
	round_number = 1
	timer = 0.0
	jump_flash = 0.0
	hat_rotor_speed = 1.2
	start_altitude = ALTITUDE
	sound.stop()
	_reset_racers()
	_menu()
	queue_redraw()

func _shuffle_difficulties() -> void:
	difficulty_order.assign([0, 1, 2])
	for i in range(2, 0, -1):
		var other := rng.randi_range(0, i)
		var previous: int = difficulty_order[i]
		difficulty_order[i] = difficulty_order[other]
		difficulty_order[other] = previous

func round_difficulty() -> int:
	return difficulty_order[clampi(round_number - 1, 0, 2)]

func _rival_deploy_height() -> float:
	var limits: Vector2 = RIVAL_DEPLOY_RANGES[round_difficulty()]
	var adaptation := lerpf(2.5, -2.0, round_player_skill) - 0.25
	return clampf(rng.randf_range(limits.x, limits.y) + rival_round_form + rng.randf_range(-0.3, 0.3) + adaptation, red_altitude + 1.2, 24.0)

func _begin_podium_dialogue() -> void:
	podium_dialogue_time = 0.0
	podium_speaker = dialogue_rng.randi_range(0, 2)
	_pick_podium_line()

func _advance_podium_dialogue(delta: float) -> void:
	var previous_beat := floori(podium_dialogue_time / 2.8)
	podium_dialogue_time += delta
	if floori(podium_dialogue_time / 2.8) != previous_beat:
		podium_speaker = (podium_speaker + 1) % 3
		_pick_podium_line()

func _pick_podium_line() -> void:
	var slot: int = reaction_order()[podium_speaker]
	var pool: Array = PLACE_JOKES[podium_speaker].duplicate()
	pool.append_array(CHARACTER_JOKES[racer_skins[slot]])
	pool.erase(previous_podium_lines[podium_speaker])
	podium_line = pool[dialogue_rng.randi_range(0, pool.size() - 1)]
	previous_podium_lines[podium_speaker] = podium_line

func _roll_platform_sign() -> void:
	var choices: Array = PLATFORM_SIGNS.filter(func(line): return line != platform_sign)
	platform_sign = choices[dialogue_rng.randi_range(0, choices.size() - 1)]

func braking_distance(speed: float) -> float:
	# Match the exact integration used by flight; only unsafe-speed steps count.
	var distance := 0.0
	var inflation := 0.0
	var velocity := speed
	while velocity > SAFE_SPEED:
		inflation = minf(1.0, inflation + PHYSICS_STEP / 0.65)
		velocity = move_toward(velocity, 2.0, 8.0 * inflation * PHYSICS_STEP)
		if velocity > SAFE_SPEED:
			distance += velocity * PHYSICS_STEP
	return distance

func deployment_color(altitude: float) -> Color:
	var red := Color("ef5269")
	var orange := Color("ffad43")
	var green := Color("64dfad")
	if altitude <= red_altitude:
		return red
	var warning_top := red_altitude + 5.0
	var midway := red_altitude + 2.0
	if altitude < midway:
		return red.lerp(orange, smoothstep(red_altitude, midway, altitude))
	if altitude < warning_top:
		return orange.lerp(green, smoothstep(midway, warning_top, altitude))
	return green

func _learn_player_round(place: int) -> void:
	var player: Dictionary = racers[0]
	var performance := 0.0
	if player.safe:
		var precision := 0.35
		if player.deploy_altitude >= 0:
			var margin: float = maxf(0, player.deploy_altitude - braking_distance(player.deploy_speed))
			precision = clampf(1.0 - margin / 12.0, 0, 1)
		performance = 0.25 + precision * 0.25 + (3 - clampi(place, 0, 3)) / 3.0 * 0.5
	var rate := 0.22 if learned_rounds < 6 else 0.12
	var target := lerpf(player_skill, performance, rate)
	player_skill = clampf(move_toward(player_skill, target, 0.08), 0, 1)
	learned_rounds += 1
