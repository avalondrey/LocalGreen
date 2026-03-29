extends Node2D
class_name ParticleEffects

# ─── Effets de particules simples dessinés par programme ─────────────
# Arrosage, récolte, croissance

# ─── Effet d'arrosage ────────────────────────────────────────────────
static func create_water_effect(parent: Node2D, pos: Vector2) -> void:
	var particles = Node2D.new()
	particles.name = "WaterParticles"
	particles.position = pos
	parent.add_child(particles)

	for i in range(6):
		var drop = _create_water_drop(i)
		particles.add_child(drop)

	var tween = particles.create_tween()
	tween.tween_callback(particles.queue_free).set_delay(0.8)

static func _create_water_drop(index: int) -> Node2D:
	var drop = Node2D.new()
	var sprite = Sprite2D.new()

	var img = Image.create(8, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	Draw.circle(img, Vector2(4, 4), 3, Color(0.3, 0.6, 0.95, 0.8))
	Draw.circle(img, Vector2(4, 3), 2, Color(0.5, 0.8, 1.0, 0.6))
	sprite.texture = ImageTexture.create_from_image(img)

	drop.add_child(sprite)
	drop.position = Vector2(randf_range(-10, 10), randf_range(-15, -5))
	drop.z_index = 100

	var tween = drop.create_tween()
	var target_y = randf_range(5, 25)
	var target_x = drop.position.x + randf_range(-5, 5)
	tween.tween_property(drop, "position", Vector2(target_x, target_y), randf_range(0.3, 0.6))
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3).set_delay(0.3)

	return drop

# ─── Effet de croissance ─────────────────────────────────────────────
static func create_growth_effect(parent: Node2D, pos: Vector2) -> void:
	var effect = Node2D.new()
	effect.name = "GrowthEffect"
	effect.position = pos
	parent.add_child(effect)

	# Étoiles qui montent
	for i in range(4):
		var star = _create_star(i)
		effect.add_child(star)

	var tween = effect.create_tween()
	tween.tween_callback(effect.queue_free).set_delay(1.0)

static func _create_star(index: int) -> Node2D:
	var star = Node2D.new()
	var sprite = Sprite2D.new()

	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var colors = [
		Color(1.0, 0.95, 0.3),
		Color(0.5, 1.0, 0.5),
		Color(1.0, 0.8, 0.3),
		Color(0.7, 1.0, 0.7)
	]
	var color = colors[index % colors.size()]
	var points = PackedVector2Array([
		Vector2(8, 0), Vector2(10, 5), Vector2(16, 5),
		Vector2(11, 8), Vector2(13, 14), Vector2(8, 10),
		Vector2(3, 14), Vector2(5, 8), Vector2(0, 5), Vector2(6, 5)
	])
	Draw.polygon(img, points, PackedColorArray([color]))
	sprite.texture = ImageTexture.create_from_image(img)

	star.add_child(sprite)
	star.position = Vector2(randf_range(-12, 12), randf_range(-8, 8))
	star.z_index = 100

	var tween = star.create_tween()
	var offset = randf_range(-15, -30)
	tween.tween_property(star, "position:y", star.position.y + offset, randf_range(0.5, 0.8))
	tween.parallel().tween_property(star, "position:x", star.position.x + randf_range(-8, 8), 0.6)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.4).set_delay(0.4)

	return star

# ─── Effet de récolte ────────────────────────────────────────────────
static func create_harvest_effect(parent: Node2D, pos: Vector2) -> void:
	var effect = Node2D.new()
	effect.name = "HarvestEffect"
	effect.position = pos
	parent.add_child(effect)

	# Particules qui volent vers le haut (comme des pièces)
	for i in range(8):
		var particle = _create_harvest_particle(i)
		effect.add_child(particle)

	var tween = effect.create_tween()
	tween.tween_callback(effect.queue_free).set_delay(1.2)

static func _create_harvest_particle(index: int) -> Node2D:
	var p = Node2D.new()
	var sprite = Sprite2D.new()

	var img = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var colors = [
		Color(1.0, 0.85, 0.0),
		Color(0.95, 0.75, 0.1),
		Color(1.0, 0.9, 0.3),
		Color(0.9, 0.7, 0.0)
	]
	Draw.circle(img, Vector2(5, 5), 4, colors[index % colors.size()])
	Draw.circle(img, Vector2(4, 4), 2, Color(1.0, 0.95, 0.5, 0.7))
	sprite.texture = ImageTexture.create_from_image(img)

	p.add_child(sprite)
	p.position = Vector2(randf_range(-5, 5), randf_range(-5, 5))
	p.z_index = 100

	var tween = p.create_tween()
	var angle = (float(index) / 8.0) * TAU
	var dist = randf_range(20, 45)
	var target_x = cos(angle) * dist
	var target_y = sin(angle) * dist - 20

	tween.tween_property(p, "position", Vector2(target_x, target_y), randf_range(0.5, 0.9))
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.4).set_delay(0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.6)

	return p

# ─── Effet de plantation ─────────────────────────────────────────────
static func create_plant_effect(parent: Node2D, pos: Vector2) -> void:
	var effect = Node2D.new()
	effect.name = "PlantEffect"
	effect.position = pos
	parent.add_child(effect)

	# Petites particules de terre
	for i in range(5):
		var dirt = _create_dirt_particle(i)
		effect.add_child(dirt)

	var tween = effect.create_tween()
	tween.tween_callback(effect.queue_free).set_delay(0.7)

static func _create_dirt_particle(index: int) -> Node2D:
	var p = Node2D.new()
	var sprite = Sprite2D.new()

	var img = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var shades = [Color(0.45, 0.30, 0.15), Color(0.50, 0.35, 0.18), Color(0.40, 0.25, 0.12)]
	Draw.circle(img, Vector2(3, 3), 2.5, shades[index % 3])
	sprite.texture = ImageTexture.create_from_image(img)

	p.add_child(sprite)
	p.position = Vector2(0, 0)
	p.z_index = 100

	var tween = p.create_tween()
	var target_x = randf_range(-15, 15)
	var target_y = randf_range(-20, -5)
	tween.set_parallel(true)
	tween.tween_property(p, "position", Vector2(target_x, target_y), randf_range(0.3, 0.5))
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3).set_delay(0.2)

	return p
