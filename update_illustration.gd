extends Control
## Small native illustration using the same painted character atlas as the game.
var face_only := false
func _draw() -> void:
	if face_only:
		for x in [219.0, 241.0]:
			draw_circle(Vector2(x, 158), 4, Color("51243e"), true, -1, true)
			draw_circle(Vector2(x - 1, 156.5), 1.2, Color("fffaf0"), true, -1, true)
		for x in [210.0, 250.0]:
			draw_circle(Vector2(x, 166), 4.5, Color("f77c98"), true, -1, true)
		draw_arc(Vector2(230, 164), 6, 0.15, PI - 0.15, 20, Color("51243e"), 2.5, true)
		return
	draw_circle(Vector2(230, 133), 103, Color("e2f0df"), true, -1, true)
	draw_arc(Vector2(230, 133), 113, -2.9, -0.4, 64, Color("d3dfc9"), 2, true)
	cloud(Vector2(112, 173), 1.0)
	cloud(Vector2(336, 102), 0.75)
	cloud(Vector2(313, 215), 0.8)
	for segment in [[Vector2(165, 111), Vector2(208, 153)], [Vector2(295, 111), Vector2(252, 153)]]:
		draw_line(segment[0], segment[1], Color("714255"), 2, true)
	star(Vector2(117, 83), 13, Color("efb546"))
	star(Vector2(337, 168), 10, Color("efb546"))
	star(Vector2(150, 225), 7, Color("e9a184"))
	draw_circle(Vector2(321, 56), 4, Color("ce8a9e"), true, -1, true)
	draw_circle(Vector2(107, 130), 3, Color("98baa4"), true, -1, true)
	draw_circle(Vector2(292, 213), 22, Color("fff4dc"), true, -1, true)
	draw_circle(Vector2(292, 211), 18, Color("59b798"), true, -1, true)
	draw_polyline(PackedVector2Array([Vector2(283, 211), Vector2(289, 217), Vector2(301, 204)]), Color("fff9e6"), 4, true)
func cloud(center: Vector2, scale_factor: float) -> void:
	for circle in [Vector3(-22, 0, 15), Vector3(0, -10, 23), Vector3(23, 0, 16)]:
		draw_circle(center + Vector2(circle.x, circle.y) * scale_factor, circle.z * scale_factor, Color("fffaf0"), true, -1, true)
func star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(8):
		var angle := i * TAU / 8.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * (1.0 if i % 2 == 0 else 0.3))
	draw_colored_polygon(points, color)
