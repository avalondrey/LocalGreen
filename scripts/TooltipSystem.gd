extends CanvasLayer
class_name TooltipSystem

# ─── Infobulles au survol des plantes ────────────────────────────────

var tooltip_panel: PanelContainer
var is_visible: bool = false
var check_timer: float = 0.0
var check_interval: float = 0.15

@onready var greenhouse: Node = get_parent().get_node_or_null("GreenhouseGrid")

func _ready() -> void:
	print("💡 TooltipSystem initialisé")
	_build_tooltip()

func _build_tooltip() -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.visible = false; tooltip_panel.z_index = 1000
	tooltip_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.12, 0.92)
	style.border_color = Color(0.4, 0.55, 0.4, 0.9)
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_width_left = 1; style.border_width_right = 1
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6; style.corner_radius_bottom_left = 6
	style.set_content_margin_all(8)
	style.shadow_color = Color(0, 0, 0, 0.4); style.shadow_size = 4
	tooltip_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	var title = Label.new(); title.name = "TooltipTitle"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	vbox.add_child(title)
	var stage = Label.new(); stage.name = "TooltipStage"
	stage.add_theme_font_size_override("font_size", 11); vbox.add_child(stage)
	var water = Label.new(); water.name = "TooltipWater"
	water.add_theme_font_size_override("font_size", 11); vbox.add_child(water)
	var info = Label.new(); info.name = "TooltipInfo"
	info.add_theme_font_size_override("font_size", 10)
	info.add_theme_color_override("font_color", Color(0.6, 0.7, 0.6))
	vbox.add_child(info)
	tooltip_panel.add_child(vbox)
	add_child(tooltip_panel)

func _process(delta: float) -> void:
	check_timer += delta
	if check_timer < check_interval or not greenhouse: return
	check_timer = 0.0
	var mouse_pos = get_viewport().get_mouse_position()
	var grid = greenhouse.world_to_grid(mouse_pos)
	if greenhouse.is_valid(grid):
		var plant = greenhouse.get_plant_at(grid.x, grid.y)
		if plant: show_tooltip(plant, mouse_pos); return
	hide_tooltip()

func show_tooltip(plant: PlantData, screen_pos: Vector2) -> void:
	var type_names = {
		PlantData.PlantType.TOMATO: "🍅 Tomate",
		PlantData.PlantType.CARROT: "🥕 Carotte",
		PlantData.PlantType.LETTUCE: "🥬 Laitue"
	}
	var stage_names = {
		PlantData.GrowthStage.SEED: "🌰 Graine",
		PlantData.GrowthStage.SPROUT: "🌱 Pousse",
		PlantData.GrowthStage.YOUNG: "🌿 Jeune",
		PlantData.GrowthStage.MATURE: "☘️ Mature",
		PlantData.GrowthStage.READY: "✨ Prêt à récolter !"
	}
	var title_lbl = tooltip_panel.get_node_or_null("VBoxContainer/TooltipTitle")
	var stage_lbl = tooltip_panel.get_node_or_null("VBoxContainer/TooltipStage")
	var water_lbl = tooltip_panel.get_node_or_null("VBoxContainer/TooltipWater")
	var info_lbl = tooltip_panel.get_node_or_null("VBoxContainer/TooltipInfo")
	if title_lbl: title_lbl.text = type_names.get(plant.plant_type, "Plante")
	if stage_lbl:
		stage_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if plant.can_harvest() else Color(1, 1, 1))
		stage_lbl.text = "Stade: %s" % stage_names.get(plant.current_stage, "Inconnu")
	if water_lbl:
		var water_pct = int(plant.water_level)
		water_lbl.add_theme_color_override("font_color", Color(0.3, 0.5, 0.9) if water_pct > 30 else Color(0.9, 0.4, 0.3))
		var bar = ""
		var filled = int(water_pct / 10.0)
		for i in range(10): bar += "█" if i < filled else "░"
		water_lbl.text = "💧 Eau: %s %d%%" % [bar, water_pct]
	if info_lbl:
		if plant.can_harvest():
			info_lbl.text = "🧺 Cliquez avec l'outil Récolter !"
			info_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
		elif plant.water_level <= 0:
			info_lbl.text = "⚠️ A besoin d'eau pour grandir !"
			info_lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
		else:
			var remaining = 0.0
			if plant.current_stage in plant.growth_times:
				remaining = plant.growth_times[plant.current_stage] - plant.growth_timer
			info_lbl.text = "⏱ Temps restant: ~%.0fs" % remaining
			info_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.6))
	tooltip_panel.position = Vector2(screen_pos.x + 20, screen_pos.y - 10)
	var vp = get_viewport().get_visible_rect()
	if tooltip_panel.position.x + 200 > vp.size.x: tooltip_panel.position.x = screen_pos.x - 220
	if tooltip_panel.position.y + 100 > vp.size.y: tooltip_panel.position.y = screen_pos.y - 100
	tooltip_panel.visible = true; is_visible = true

func hide_tooltip() -> void:
	if is_visible: tooltip_panel.visible = false; is_visible = false
