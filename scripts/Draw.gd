class_name Draw
extends RefCounted

# ─── Helper de dessin pour Image (Godot 4) ───────────────────────────
# Godot 4 a supprimé les draw_* de Image. Ce helper les recrée.

static func circle(img: Image, center: Vector2, radius: float, color: Color) -> void:
	var cx: int = int(center.x)
	var cy: int = int(center.y)
	var r: int = int(radius)
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				put_pixel(img, x, y, color)

static func line(img: Image, from: Vector2, to: Vector2, color: Color, width: float = 1.0) -> void:
	var dx: float = abs(to.x - from.x)
	var dy: float = -abs(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: float = dx + dy
	var x: int = int(from.x)
	var y: int = int(from.y)
	var ex: int = int(to.x)
	var ey: int = int(to.y)
	while true:
		if width <= 1.5:
			put_pixel(img, x, y, color)
		else:
			circle(img, Vector2(x, y), width / 2.0, color)
		if x == ex and y == ey:
			break
		var e2: float = 2.0 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

static func polygon(img: Image, points: PackedVector2Array, colors: PackedColorArray) -> void:
	if points.size() < 3:
		return
	var color: Color = colors[0] if colors.size() > 0 else Color.WHITE
	var min_x: float = points[0].x
	var max_x: float = points[0].x
	var min_y: float = points[0].y
	var max_y: float = points[0].y
	for p in points:
		if p.x < min_x: min_x = p.x
		if p.x > max_x: max_x = p.x
		if p.y < min_y: min_y = p.y
		if p.y > max_y: max_y = p.y
	for y in range(int(min_y), int(max_y) + 1):
		var intersections: Array = []
		var n: int = points.size()
		for i in range(n):
			var j: int = (i + 1) % n
			var yi: float = points[i].y
			var yj: float = points[j].y
			if (yi <= y and yj > y) or (yj <= y and yi > y):
				var x_int: float = points[i].x + (y - yi) / (yj - yi) * (points[j].x - points[i].x)
				intersections.append(x_int)
		intersections.sort()
		for k in range(0, intersections.size() - 1, 2):
			var x_start: int = int(intersections[k])
			var x_end: int = int(intersections[k + 1])
			for x in range(x_start, x_end + 1):
				put_pixel(img, x, y, color)

static func polyline(img: Image, points: PackedVector2Array, color: Color, width: float = 1.0) -> void:
	for i in range(points.size() - 1):
		line(img, points[i], points[i + 1], color, width)
	if points.size() > 2 and points[0].distance_to(points[points.size() - 1]) < 2.0:
		line(img, points[points.size() - 1], points[0], color, width)

static func rect(img: Image, rect: Rect2, color: Color) -> void:
	var x1: int = int(rect.position.x)
	var y1: int = int(rect.position.y)
	var x2: int = int(rect.end.x)
	var y2: int = int(rect.end.y)
	for y in range(y1, y2 + 1):
		for x in range(x1, x2 + 1):
			put_pixel(img, x, y, color)

static func put_pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)
