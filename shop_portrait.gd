extends Node2D
## Shared character renderer on a canvas clipped by its parent card Control.
var art: RefCounted
var skin := 4
var animation_time := 0.0
const FEET := Vector2(69, 122) # Original (72, 125), relative to the 3px inset.
const PORTRAIT_SCALE := 1.1

func _draw() -> void:
	if art == null:
		return
	art.portrait_target = self
	art.collection_portrait(skin, FEET, PORTRAIT_SCALE)
	art.portrait_target = null

func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for k in range(48):
		var angle := TAU * k / 48.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)

func _star(center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array()
	for k in range(10):
		var angle := -PI / 2 + TAU * k / 10.0
		points.append(center + Vector2(cos(angle), sin(angle)) * size * (1.0 if k % 2 == 0 else 0.45))
	draw_colored_polygon(points, color)
