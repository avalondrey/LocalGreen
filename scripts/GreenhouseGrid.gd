extends Node2D

class_name GreenhouseGrid

# ─── Configuration de la grille ──────────────────────────────────────

const GRID_WIDTH := 6
const GRID_HEIGHT := 4
const TILE_SIZE := Vector2(128, 64)

# ─── État du jeu ─────────────────────────────────────────────────────

var plants: Dictionary = {}
var selected_tool: String = "plant"
var selected_plant_type: int = 0
var grid_origin: Vector2 = Vector2.ZERO
var tile_nodes: Dictionary = {}

@onready var plant_container: Node2D = $PlantContainer

# ─── Signal ──────────────────────────────────────────────────────────

signal plant_planted(pos: Vector2i, plant: PlantData)
signal plant_watered(pos: Vector2i)
signal plant_harvested(pos: Vector2i, value: int)
signal tool_changed(tool_name: String)

# ─── Initialisation ──────────────────────────────────────────────────

func _ready() -> void:
	print("🌱 LocalGreen démarre — Grille %dx%d" % [GRID_WIDTH, GRID_HEIGHT])
	await get_tree().process_frame
	grid_origin = get_grid_origin()
	print("  Grille origin: ", grid_origin)
	render_grid()

func get_grid_origin() -> Vector2:
	var min_x: float = 9999.0
	var max_x: float = -9999.0
	var min_y: float = 9999.0
	var max_y: float = -9999.0
	for gy in range(GRID_HEIGHT):
		for gx in range(GRID_WIDTH):
			var wx: float = float(gx - gy) * TILE_SIZE.x / 2.0
			var wy: float = float(gx + gy) * TILE_SIZE.y / 2.0
			if wx < min_x:
				min_x = wx
			if wx > max_x:
				max_x = wx
			if wy < min_y:
				min_y = wy
			if wy > max_y:
				max_y = wy
	return Vector2(-(min_x + max_x) / 2.0, -(min_y + max_y) / 2.0)

# ─── Coordonnées isométriques ────────────────────────────────────────

func grid_to_world(gx: int, gy: int) -> Vector2:
	var wx = (gx - gy) * TILE_SIZE.x / 2.0
	var wy = (gx + gy) * TILE_SIZE.y / 2.0
	return Vector2(wx, wy) + grid_origin

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var adjusted = world_pos - grid_origin
	var gx = (adjusted.x / (TILE_SIZE.x / 2.0) + adjusted.y / (TILE_SIZE.y / 2.0)) / 2.0
	var gy = (adjusted.y / (TILE_SIZE.y / 2.0) - adjusted.x / (TILE_SIZE.x / 2.0)) / 2.0
	return Vector2i(floori(gx), floori(gy))

func is_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < GRID_HEIGHT

# ─── Rendu de la grille ──────────────────────────────────────────────

func render_grid() -> void:
	for gy in range(GRID_HEIGHT):
		for gx in range(GRID_WIDTH):
			var world_pos = grid_to_world(gx, gy)
			var tile = _create_tile_sprite(world_pos, gx, gy)
			tile_nodes["%d,%d" % [gx, gy]] = tile
			add_child(tile)

func _create_tile_sprite(pos: Vector2, gx: int, gy: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	var img = Image.create(128, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var cx = 64.0
	var cy = 32.0
	var points = PackedVector2Array([
		Vector2(cx, 2), Vector2(126, cy), Vector2(cx, 62), Vector2(2, cy)
	])
	var colors = PackedColorArray([
		Color(0.45, 0.72, 0.45, 1.0),
		Color(0.40, 0.65, 0.40, 1.0),
		Color(0.38, 0.62, 0.38, 1.0),
		Color(0.42, 0.68, 0.42, 1.0)
	])
	Draw.polygon(img, points, colors)
	Draw.polyline(img, points, Color(0.30, 0.55, 0.30, 0.8), 2.0)
	var inner_points = PackedVector2Array([
		Vector2(cx, 8), Vector2(120, cy), Vector2(cx, 56), Vector2(8, cy)
	])
	Draw.polyline(img, inner_points, Color(0.50, 0.75, 0.50, 0.4), 1.0)
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.position = pos
	sprite.z_index = gy
	sprite.name = "Tile_%d_%d" % [gx, gy]
	return sprite

# ─── Entrées joueur ──────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos = get_global_mouse_position()
		var grid = world_to_grid(pos)
		print("🖱️ Click pos=", pos, " grid=", grid, " valid=", is_valid(grid), " tool=", selected_tool)
		if is_valid(grid):
			handle_click(grid.x, grid.y)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		set_tool("water")

func _is_over_ui(node: Control, mouse_pos: Vector2) -> bool:
	if not node.visible:
		return false
	if node.get_global_rect().has_point(mouse_pos):
		return true
	for child in node.get_children():
		if child is Control and _is_over_ui(child, mouse_pos):
			return true
	return false

# ─── Actions du joueur ───────────────────────────────────────────────

func handle_click(x: int, y: int) -> void:
	var key = "%d,%d" % [x, y]
	print("  handle_click: key=", key, " tool=", selected_tool)
	match selected_tool:
		"plant":
			if plants.has(key):
				print("⚠️ Il y a déjà une plante ici !")
			else:
				plant_seed(x, y, selected_plant_type)
		"water":
			water_plant(x, y)
		"harvest":
			harvest_plant(x, y)
		"remove":
			remove_plant(x, y)

func plant_seed(x: int, y: int, ptype: int) -> bool:
	var key = "%d,%d" % [x, y]
	if plants.has(key):
		return false
	var data = PlantData.new()
	data.plant_type = ptype as PlantData.PlantType
	data.current_stage = PlantData.GrowthStage.SEED
	data.water_level = 50.0
	var datetime = Time.get_datetime_string_from_system()
	data.planted_at = datetime
	plants[key] = data
	update_visual(x, y)
	print("🌱 Planté %s en (%d,%d)" % [PlantData.PlantType.keys()[ptype], x, y])
	plant_planted.emit(Vector2i(x, y), data)
	return true

func water_plant(x: int, y: int, amount: float = 30.0) -> bool:
	var key = "%d,%d" % [x, y]
	if not plants.has(key):
		return false
	plants[key].water(amount)
	update_visual(x, y)
	print("💧 Arrosé (%d,%d) — eau: %.0f" % [x, y, plants[key].water_level])
	plant_watered.emit(Vector2i(x, y))
	return true

func harvest_plant(x: int, y: int) -> bool:
	var key = "%d,%d" % [x, y]
	if not plants.has(key):
		return false
	var plant = plants[key]
	if not plant.can_harvest():
		print("⏳ Pas encore prêt ! Stade: %s" % PlantData.GrowthStage.keys()[plant.current_stage])
		return false
	var value = plant.get_harvest_value()
	remove_plant_visual(x, y)
	plants.erase(key)
	print("🧺 Récolté (%d,%d) — valeur: %d" % [x, y, value])
	plant_harvested.emit(Vector2i(x, y), value)
	return true

func remove_plant(x: int, y: int) -> bool:
	var key = "%d,%d" % [x, y]
	if not plants.has(key):
		return false
	remove_plant_visual(x, y)
	plants.erase(key)
	print("🗑️ Supprimé (%d,%d)" % [x, y])
	return true

# ─── Mise à jour continue ────────────────────────────────────────────

func _process(delta: float) -> void:
	for key in plants.keys():
		var plant = plants[key] as PlantData
		plant.consume_water(delta)
		var advanced = plant.process(delta)
		if advanced:
			print("🌿 Croissance ! %s → %s" % [key, PlantData.GrowthStage.keys()[plant.current_stage]])
			var parts = key.split(",")
			update_visual(int(parts[0]), int(parts[1]))

# ─── Rendu visuel des plantes ────────────────────────────────────────

func update_visual(x: int, y: int) -> void:
	var key = "%d,%d" % [x, y]
	remove_plant_visual(x, y)
	if not plants.has(key):
		return
	var plant = plants[key] as PlantData
	var world_pos = grid_to_world(x, y)
	var container = Node2D.new()
	container.name = "Plant_%d_%d" % [x, y]
	container.position = world_pos
	container.z_index = y + 1
	var sprite = Sprite2D.new()
	sprite.texture = _generate_plant_texture(plant)
	sprite.position = Vector2(0, -8)
	sprite.name = "Sprite"
	container.add_child(sprite)
	var water_bar = _create_water_bar(plant.water_level)
	water_bar.name = "WaterBar"
	container.add_child(water_bar)
	var tween = create_tween()
	sprite.scale = Vector2(0.3, 0.3)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)
	plant_container.add_child(container)

func remove_plant_visual(x: int, y: int) -> void:
	var key = "%d,%d" % [x, y]
	var node_name = "Plant_%d_%d" % [x, y]
	if plant_container.has_node(node_name):
		var node = plant_container.get_node(node_name)
		var tween = create_tween()
		tween.tween_property(node, "scale", Vector2(0.0, 0.0), 0.2)
		tween.tween_callback(node.queue_free)

func _generate_plant_texture(plant: PlantData) -> ImageTexture:
	var type_colors = {
		PlantData.PlantType.TOMATO: {
			"stem": Color(0.25, 0.55, 0.15),
			"leaf": Color(0.35, 0.70, 0.20),
			"fruit": Color(0.90, 0.20, 0.15),
			"flower": Color(0.95, 0.85, 0.30)
		},
		PlantData.PlantType.CARROT: {
			"stem": Color(0.20, 0.50, 0.15),
			"leaf": Color(0.30, 0.65, 0.20),
			"fruit": Color(0.95, 0.60, 0.15),
			"flower": Color(0.95, 0.85, 0.30)
		},
		PlantData.PlantType.LETTUCE: {
			"stem": Color(0.20, 0.50, 0.15),
			"leaf": Color(0.40, 0.75, 0.25),
			"fruit": Color(0.55, 0.85, 0.30),
			"flower": Color(0.90, 0.90, 0.40)
		}
	}
	var colors = type_colors[plant.plant_type]
	var stage = plant.current_stage
	var img = Image.create(64, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var cx = 32.0
	match stage:
		PlantData.GrowthStage.SEED:
			Draw.circle(img, Vector2(cx, 65), 5, Color(0.45, 0.30, 0.15))
			Draw.circle(img, Vector2(cx, 65), 3, Color(0.55, 0.40, 0.20))
			for i in range(3):
				Draw.circle(img, Vector2(cx - 6 + i * 6, 68), 1.5, Color(0.40, 0.28, 0.12))
		PlantData.GrowthStage.SPROUT:
			_draw_line_thick(img, Vector2(cx, 70), Vector2(cx, 50), 2, colors["stem"])
			_draw_leaf(img, Vector2(cx, 50), Vector2(cx - 10, 42), 6, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 50), Vector2(cx + 10, 42), 6, colors["leaf"])
		PlantData.GrowthStage.YOUNG:
			_draw_line_thick(img, Vector2(cx, 70), Vector2(cx, 35), 3, colors["stem"])
			_draw_leaf(img, Vector2(cx, 55), Vector2(cx - 18, 45), 10, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 55), Vector2(cx + 18, 45), 10, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 42), Vector2(cx - 14, 34), 8, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 42), Vector2(cx + 14, 34), 8, colors["leaf"])
		PlantData.GrowthStage.MATURE:
			_draw_line_thick(img, Vector2(cx, 70), Vector2(cx, 25), 3, colors["stem"])
			_draw_leaf(img, Vector2(cx, 58), Vector2(cx - 22, 48), 12, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 58), Vector2(cx + 22, 48), 12, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 45), Vector2(cx - 18, 36), 10, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 45), Vector2(cx + 18, 36), 10, colors["leaf"])
			Draw.circle(img, Vector2(cx, 22), 5, colors["flower"])
			Draw.circle(img, Vector2(cx - 6, 26), 3, colors["flower"])
			Draw.circle(img, Vector2(cx + 6, 26), 3, colors["flower"])
		PlantData.GrowthStage.READY:
			_draw_line_thick(img, Vector2(cx, 70), Vector2(cx, 22), 4, colors["stem"])
			_draw_leaf(img, Vector2(cx, 58), Vector2(cx - 24, 48), 14, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 58), Vector2(cx + 24, 48), 14, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 44), Vector2(cx - 20, 35), 11, colors["leaf"])
			_draw_leaf(img, Vector2(cx, 44), Vector2(cx + 20, 35), 11, colors["leaf"])
			match plant.plant_type:
				PlantData.PlantType.TOMATO:
					Draw.circle(img, Vector2(cx - 8, 20), 7, colors["fruit"])
					Draw.circle(img, Vector2(cx + 8, 24), 6, colors["fruit"])
					Draw.circle(img, Vector2(cx, 15), 7, colors["fruit"])
					Draw.circle(img, Vector2(cx - 6, 18), 2, Color(1, 1, 1, 0.4))
					Draw.circle(img, Vector2(cx + 10, 22), 1.5, Color(1, 1, 1, 0.4))
				PlantData.PlantType.CARROT:
					_draw_carrot(img, cx, 60, colors["fruit"])
					_draw_leaf(img, Vector2(cx, 30), Vector2(cx - 16, 18), 12, colors["leaf"])
					_draw_leaf(img, Vector2(cx, 30), Vector2(cx + 16, 18), 12, colors["leaf"])
					_draw_leaf(img, Vector2(cx, 30), Vector2(cx, 14), 10, colors["leaf"])
				PlantData.PlantType.LETTUCE:
					Draw.circle(img, Vector2(cx, 30), 18, colors["fruit"])
					Draw.circle(img, Vector2(cx - 2, 28), 14, colors["leaf"])
					Draw.circle(img, Vector2(cx + 2, 32), 10, Color(0.60, 0.90, 0.35))
					Draw.line(img, Vector2(cx, 18), Vector2(cx, 42), Color(0.35, 0.65, 0.20), 1)
					Draw.line(img, Vector2(cx - 12, 28), Vector2(cx + 12, 28), Color(0.35, 0.65, 0.20), 1)
	return ImageTexture.create_from_image(img)

func _draw_line_thick(img: Image, from: Vector2, to: Vector2, width: int, color: Color) -> void:
	Draw.line(img, from, to, color, width)

func _draw_leaf(img: Image, base: Vector2, tip: Vector2, size: float, color: Color) -> void:
	var dir = (tip - base).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var points = PackedVector2Array([base, tip, base + perp * size * 0.4])
	var leaf_colors = PackedColorArray([color, color, Color(color.r * 0.8, color.g * 0.9, color.b * 0.7)])
	Draw.polygon(img, points, leaf_colors)
	Draw.line(img, base, tip, Color(color.r * 0.7, color.g * 0.8, color.b * 0.6), 1)

func _draw_carrot(img: Image, cx: float, base_y: float, color: Color) -> void:
	var points = PackedVector2Array([
		Vector2(cx - 6, base_y),
		Vector2(cx + 6, base_y),
		Vector2(cx + 1, base_y + 22),
		Vector2(cx - 1, base_y + 22)
	])
	var carrot_colors = PackedColorArray([color, color, Color(0.85, 0.50, 0.10), Color(0.85, 0.50, 0.10)])
	Draw.polygon(img, points, carrot_colors)
	for i in range(3):
		var yy = base_y + 5 + i * 5
		Draw.line(img, Vector2(cx - 4 + i, yy), Vector2(cx + 4 - i, yy), Color(0.80, 0.45, 0.10), 1)

func _create_water_bar(water_level: float) -> Node2D:
	var container = Node2D.new()
	container.position = Vector2(-16, -38)
	var bg = ColorRect.new()
	bg.size = Vector2(32, 4)
	bg.color = Color(0.2, 0.2, 0.2, 0.6)
	bg.name = "BG"
	container.add_child(bg)
	var fill = ColorRect.new()
	fill.size = Vector2(32 * (water_level / 100.0), 4)
	fill.color = Color(0.20, 0.50, 0.90, 0.9)
	fill.name = "Fill"
	container.add_child(fill)
	return container

# ─── Outils ──────────────────────────────────────────────────────────

func set_tool(tool_name: String) -> void:
	selected_tool = tool_name
	tool_changed.emit(tool_name)
	print("🔧 Outil sélectionné: %s" % tool_name)

func set_plant_type(type_index: int) -> void:
	selected_plant_type = type_index
	print("🌱 Type de plante: %s" % PlantData.PlantType.keys()[type_index])

# ─── Utilitaires ─────────────────────────────────────────────────────

func get_plant_at(x: int, y: int) -> PlantData:
	var key = "%d,%d" % [x, y]
	if plants.has(key):
		return plants[key]
	return null

func get_all_plants() -> Dictionary:
	return plants

func get_plant_count() -> int:
	return plants.size()

func highlight_tile(x: int, y: int, highlight: bool) -> void:
	var key = "%d,%d" % [x, y]
	if tile_nodes.has(key):
		var tile = tile_nodes[key] as Sprite2D
		if highlight:
			tile.modulate = Color(1.2, 1.2, 0.8, 1.0)
		else:
			tile.modulate = Color(1.0, 1.0, 1.0, 1.0)
