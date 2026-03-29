extends Node2D
class_name WeatherSystem

# ─── Système météo dynamique ─────────────────────────────────────────

enum Weather { SUNNY, CLOUDY, RAINY, STORMY }

var weather_names := {
		Weather.SUNNY: "☀️ Ensoleillé", Weather.CLOUDY: "☁️ Nuageux",
		Weather.RAINY: "🌧️ Pluie", Weather.STORMY: "⛈️ Orageux"
}
var weather_mods := {
		Weather.SUNNY:  {"growth_mult": 1.2, "water_mult": 1.3, "auto_water": 0.0},
		Weather.CLOUDY: {"growth_mult": 1.0, "water_mult": 1.0, "auto_water": 0.0},
		Weather.RAINY:  {"growth_mult": 1.1, "water_mult": 0.7, "auto_water": 3.0},
		Weather.STORMY: {"growth_mult": 0.8, "water_mult": 0.4, "auto_water": 8.0}
}

var current_weather: Weather = Weather.SUNNY
var weather_timer: float = 0.0
var weather_duration: float = 30.0
var rain_drops: Array = []
var cloud_nodes: Array = []
var overlay: ColorRect
var lightning_timer: float = 0.0

signal weather_changed(weather_name: String, weather_type: int)

@onready var game_manager: Node = get_parent().get_node_or_null("GameManager")
@onready var camera: Camera2D = get_parent().get_node_or_null("Camera")
@onready var greenhouse: Node = get_parent().get_node_or_null("GreenhouseGrid")

func _ready() -> void:
		print("🌤️ WeatherSystem initialisé — %s" % weather_names[current_weather])
		_create_overlay(); _create_clouds()
		z_index = 999; randomize()

func _create_overlay() -> void:
		overlay = ColorRect.new()
		overlay.color = Color(0, 0, 0, 0)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(overlay)

func _create_clouds() -> void:
		for i in range(5):
				var cloud = _create_cloud()
				cloud.position = Vector2(randf_range(-700, 700), randf_range(-300, -100))
				cloud.modulate.a = 0.0
				add_child(cloud); cloud_nodes.append(cloud)

func _create_cloud() -> Sprite2D:
		var sprite = Sprite2D.new()
		var img = Image.create(200, 60, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		var c = Color(0.85, 0.85, 0.9, 0.6)
		Draw.circle(img, Vector2(40, 40), 30, c)
		Draw.circle(img, Vector2(70, 30), 25, c)
		Draw.circle(img, Vector2(100, 35), 28, c)
		Draw.circle(img, Vector2(130, 40), 22, c)
		Draw.circle(img, Vector2(160, 42), 18, c)
		var light = Color(0.95, 0.95, 1.0, 0.3)
		Draw.circle(img, Vector2(65, 25), 15, light)
		Draw.circle(img, Vector2(95, 28), 12, light)
		sprite.texture = ImageTexture.create_from_image(img)
		return sprite

func _spawn_rain() -> void:
		if current_weather != Weather.RAINY and current_weather != Weather.STORMY: return
		var drop = _create_raindrop()
		add_child(drop); rain_drops.append(drop)
		if rain_drops.size() > 100:
				var old = rain_drops.pop_front()
				if is_instance_valid(old): old.queue_free()

func _create_raindrop() -> Node2D:
		var drop = Node2D.new()
		var sprite = Sprite2D.new()
		var img = Image.create(2, 12, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		var alpha = randf_range(0.3, 0.7)
		var color = Color(0.5, 0.6, 0.8, alpha)
		if current_weather == Weather.STORMY: color = Color(0.4, 0.5, 0.7, alpha + 0.1)
		Draw.rect(img, Rect2(Vector2(0, 0), Vector2(2, 12)), color)
		sprite.texture = ImageTexture.create_from_image(img)
		drop.add_child(sprite)
		drop.position = Vector2(randf_range(-50, 1330), randf_range(-30, -10))
		drop.z_index = 998
		var speed = randf_range(400, 700)
		var wind = randf_range(-20, 20)
		var tween = drop.create_tween()
		tween.tween_property(drop, "position:y", 750.0, 750.0 / speed)
		tween.parallel().tween_property(drop, "position:x", drop.position.x + wind, 750.0 / speed)
		tween.tween_callback(drop.queue_free)
		return drop

func _trigger_lightning() -> void:
		if current_weather != Weather.STORMY: return
		overlay.color = Color(1, 1, 1, 0.7)
		var tween = create_tween()
		tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.15)
		tween.tween_property(overlay, "color", Color(1, 1, 0.9, 0.4), 0.05)
		tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.2)

func _process(delta: float) -> void:
		weather_timer += delta
		if current_weather == Weather.RAINY and randf() < 0.6: _spawn_rain()
		elif current_weather == Weather.STORMY:
				if randf() < 0.85: _spawn_rain()
				lightning_timer += delta
				if lightning_timer > randf_range(5.0, 12.0):
						lightning_timer = 0.0; _trigger_lightning()
		if (current_weather == Weather.RAINY or current_weather == Weather.STORMY) and greenhouse:
				_auto_water_plants(weather_mods[current_weather]["auto_water"] * delta)
		_update_overlay(delta); _animate_clouds(delta)
		if weather_timer >= weather_duration: _change_weather()

func _auto_water_plants(amount: float) -> void:
		if not greenhouse: return
		var plants = greenhouse.get_all_plants()
		for key in plants:
				var plant = plants[key]
				if plant.water_level < 80: plant.water(min(amount, 100.0 - plant.water_level))

func _update_overlay(delta: float) -> void:
		var target_color: Color
		match current_weather:
				Weather.SUNNY: target_color = Color(0, 0, 0, 0)
				Weather.CLOUDY: target_color = Color(0.1, 0.1, 0.15, 0.08)
				Weather.RAINY: target_color = Color(0.05, 0.08, 0.15, 0.15)
				Weather.STORMY: target_color = Color(0.02, 0.03, 0.08, 0.25)
		overlay.color = overlay.color.lerp(target_color, delta * 2.0)

func _animate_clouds(delta: float) -> void:
	if camera:
		position.x = camera.position.x
		position.y = camera.position.y
	for cloud in cloud_nodes:
		if not is_instance_valid(cloud):
			continue
		cloud.position.x += delta * randf_range(10, 25)
		if cloud.position.x > 700:
			cloud.position.x = -700
		var target_alpha = 0.0
		match current_weather:
			Weather.CLOUDY:
				target_alpha = 0.4
			Weather.RAINY:
				target_alpha = 0.6
			Weather.STORMY:
				target_alpha = 0.8
		cloud.modulate.a = lerp(cloud.modulate.a, target_alpha, delta * 1.5)

func _change_weather() -> void:
		weather_timer = 0.0
		weather_duration = randf_range(20.0, 50.0)
		var roll = randf()
		if roll < 0.4: current_weather = Weather.SUNNY
		elif roll < 0.65: current_weather = Weather.CLOUDY
		elif roll < 0.88: current_weather = Weather.RAINY
		else: current_weather = Weather.STORMY
		print("🌤️ Météo : %s" % weather_names[current_weather])
		weather_changed.emit(weather_names[current_weather], current_weather)
		if current_weather == Weather.SUNNY or current_weather == Weather.CLOUDY:
				for drop in rain_drops:
						if is_instance_valid(drop): drop.queue_free()
				rain_drops.clear()

func get_weather() -> Weather: return current_weather
func get_growth_multiplier() -> float: return weather_mods[current_weather]["growth_mult"]
func get_water_multiplier() -> float: return weather_mods[current_weather]["water_mult"]
func get_weather_name() -> String: return weather_names[current_weather]
