extends Node2D

const GRID_WIDTH := 6
const GRID_HEIGHT := 4
const TILE_SIZE := Vector2(128, 64)

var plants: Dictionary = {}
var selected_tool: String = "water"
var selected_plant_type: int = 0

func _ready():
	print("LocalGreen demarre - Grille 6x4")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos = get_global_mouse_position()
		var grid = world_to_grid(pos)
		if is_valid(grid):
			handle_click(grid.x, grid.y)

func handle_click(x: int, y: int):
	match selected_tool:
		"plant": plant_seed(x, y, selected_plant_type)
		"water": water_plant(x, y)
		"harvest": harvest_plant(x, y)

func plant_seed(x: int, y: int, ptype: int) -> bool:
	var key = str(x) + "," + str(y)
	if plants.has(key): return false
	var plant = PlantData.new()
	plant.plant_type = ptype
	plant.planted_at = Time.get_datetime_string_from_system()
	plants[key] = plant
	print("Plante en ", x, ",", y)
	update_visual(x, y)
	return true

func water_plant(x: int, y: int, amount: float = 25.0) -> bool:
	var key = str(x) + "," + str(y)
	if plants.has(key):
		plants[key].water(amount)
		print("Arrose en ", x, ",", y)
		return true
	return false

func harvest_plant(x: int, y: int) -> bool:
	var key = str(x) + "," + str(y)
	if plants.has(key) and plants[key].can_harvest():
		var val = plants[key].get_harvest_value()
		plants.erase(key)
		print("Recolte +", val)
		update_visual(x, y)
		return true
	return false

func _process(delta):
	for key in plants:
		var p = plants[key]
		p.consume_water(delta)
		if p.process(delta):
			var parts = key.split(",")
			update_visual(int(parts[0]), int(parts[1]))

func is_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < GRID_HEIGHT

func world_to_grid(wp: Vector2) -> Vector2i:
	var x = int((wp.x / TILE_SIZE.x) + (wp.y / TILE_SIZE.y))
	var y = int((wp.y / TILE_SIZE.y) - (wp.x / TILE_SIZE.x))
	return Vector2i(x, y)

func update_visual(x: int, y: int):
	pass
