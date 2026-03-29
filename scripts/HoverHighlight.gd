extends Node2D
class_name HoverHighlight

# ─── Surbrillance au survol des tuiles ───────────────────────────────
var highlight_sprite: Sprite2D
var prev_grid_pos: Vector2i = Vector2i(-99, -99)

@onready var greenhouse: Node = get_parent().get_node_or_null("GreenhouseGrid")

func _ready() -> void:
	print("🖱️ HoverHighlight initialisé")
	_create_highlight()

func _create_highlight() -> void:
	highlight_sprite = Sprite2D.new()
	highlight_sprite.visible = false; highlight_sprite.z_index = 99
	var img = Image.create(128, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var points = PackedVector2Array([
		Vector2(64, 0), Vector2(128, 32), Vector2(64, 64), Vector2(0, 32)
	])
	var colors = PackedColorArray([
		Color(1.0, 1.0, 0.5, 0.35), Color(1.0, 1.0, 0.5, 0.35),
		Color(1.0, 1.0, 0.5, 0.35), Color(1.0, 1.0, 0.5, 0.35)
	])
	Draw.polygon(img, points, colors)
	Draw.polyline(img, points, Color(1.0, 1.0, 0.3, 0.7), 2.5)
	Draw.circle(img, Vector2(64, 32), 3, Color(1.0, 1.0, 0.5, 0.6))
	highlight_sprite.texture = ImageTexture.create_from_image(img)
	add_child(highlight_sprite)

func _process(_delta: float) -> void:
	if not greenhouse: return
	var mouse_pos = get_global_mouse_position()
	var grid_pos = greenhouse.world_to_grid(mouse_pos)
	if grid_pos == prev_grid_pos: return
	prev_grid_pos = grid_pos
	if greenhouse.is_valid(grid_pos):
		var world_pos = greenhouse.grid_to_world(grid_pos.x, grid_pos.y)
		highlight_sprite.position = world_pos
		highlight_sprite.visible = true
		highlight_sprite.z_index = grid_pos.y + 2
		match greenhouse.selected_tool:
			"plant": highlight_sprite.modulate = Color(0.5, 1.0, 0.5, 0.8)
			"water": highlight_sprite.modulate = Color(0.4, 0.6, 1.0, 0.8)
			"harvest": highlight_sprite.modulate = Color(1.0, 0.9, 0.3, 0.8)
			"remove": highlight_sprite.modulate = Color(1.0, 0.4, 0.4, 0.8)
			_: highlight_sprite.modulate = Color(1.0, 1.0, 0.5, 0.8)
	else:
		highlight_sprite.visible = false
