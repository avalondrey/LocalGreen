extends Control
class_name TitleScreen

# ─── Écran titre avec menu principal ─────────────────────────────────
# Menu : Jouer, Tutoriel, Options, Quitter

signal start_game()
signal show_tutorial()
signal show_settings()

@onready var game_manager: Node = get_node_or_null("/root/GameManager")

# ─── Animations ──────────────────────────────────────────────────────
var title_anim_timer: float = 0.0
var particles: Array = []

func _ready() -> void:
	_build_title_screen()
	_spawn_ambient_particles()

func _build_title_screen() -> void:
	# Fond
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient_img = _create_gradient_bg()
	var tex = ImageTexture.create_from_image(gradient_img)
	var bg_sprite = TextureRect.new()
	bg_sprite.texture = tex
	bg_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg_sprite)

	# Conteneur central
	var center = VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.offset_left = -180
	center.offset_top = -200
	center.offset_right = 180
	center.offset_bottom = 200
	center.add_theme_constant_override("separation", 16)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.name = "CenterContainer"

	# Logo / Titre
	var title_frame = PanelContainer.new()
	var title_inner = VBoxContainer.new()
	title_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	title_inner.add_theme_constant_override("separation", 4)

	var logo = TextureRect.new()
	if ResourceLoader.exists("res://assets/ui/game_icon.png"):
		logo.texture = load("res://assets/ui/game_icon.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(120, 120)
	title_inner.add_child(logo)

	var title = Label.new()
	title.text = "🌱 LocalGreen"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.85))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_inner.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Jardinage Isométrique Style Manga"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.85, 0.70, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_inner.add_child(subtitle)

	title_frame.add_child(title_inner)
	_add_style_to_panel(title_frame, Color(0.15, 0.22, 0.15, 0.7))
	center.add_child(title_frame)

	# Espace
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	center.add_child(spacer)

	# Boutons du menu
	var buttons_data = [
		{"text": "🎮  Jouer", "action": "_on_play_pressed", "color": Color(0.2, 0.55, 0.2, 0.9)},
		{"text": "📖  Tutoriel", "action": "_on_tutorial_pressed", "color": Color(0.2, 0.45, 0.55, 0.9)},
		{"text": "🤖  IA Connectée : Vérification...", "action": "_on_ai_check_pressed", "color": Color(0.45, 0.35, 0.2, 0.9), "name": "AIButton"},
		{"text": "⚙️  Options", "action": "_on_settings_pressed", "color": Color(0.35, 0.35, 0.35, 0.9)},
		{"text": "🚪  Quitter", "action": "_on_quit_pressed", "color": Color(0.55, 0.25, 0.25, 0.9)}
	]

	for btn_data in buttons_data:
		var btn = _create_menu_button(btn_data["text"], btn_data["color"])
		if btn_data.has("name"):
			btn.name = btn_data["name"]
		btn.pressed.connect(Callable(self, btn_data["action"]))
		center.add_child(btn)

	# Version
	var version = Label.new()
	version.text = "v1.0.0 — Godot 4.6"
	version.add_theme_font_size_override("font_size", 10)
	version.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(version)

	add_child(center)

	# Particle container
	var particle_node = Node2D.new()
	particle_node.name = "Particles"
	particle_node.z_index = -1
	add_child(particle_node)

func _create_gradient_bg() -> Image:
	var img = Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	for y in range(720):
		var t = float(y) / 720.0
		var r = lerp(0.18, 0.10, t)
		var g = lerp(0.35, 0.22, t)
		var b = lerp(0.18, 0.10, t)
		Draw.line(img, Vector2(0, y), Vector2(1280, y), Color(r, g, b, 1.0), 1)

	# Taches de lumière décoratives
	for i in range(20):
		var cx = randf_range(100, 1180)
		var cy = randf_range(50, 670)
		var radius = randf_range(30, 80)
		var color = Color(0.3, 0.5, 0.3, 0.15)
		Draw.circle(img, Vector2(cx, cy), radius, color)

	# Petites étoiles / lucioles
	for i in range(15):
		var px = randf_range(50, 1230)
		var py = randf_range(30, 690)
		var size = randf_range(2, 5)
		Draw.circle(img, Vector2(px, py), size, Color(0.7, 0.9, 0.6, 0.4))
		Draw.circle(img, Vector2(px, py), size * 0.5, Color(0.9, 1.0, 0.8, 0.6))

	return img

func _create_menu_button(text: String, bg_color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 48)
	btn.add_theme_font_size_override("font_size", 16)

	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = bg_color.lightened(0.2)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.set_content_margin_all(8)

	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = bg_color.lightened(0.15)
	hover_style.border_color = bg_color.lightened(0.4)
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = bg_color.darkened(0.1)
	pressed_style.border_color = bg_color.lightened(0.3)
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_right = 8
	pressed_style.corner_radius_bottom_left = 8
	pressed_style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	return btn

func _add_style_to_panel(panel: PanelContainer, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.2)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)

# ─── Particules ambiantes (feuilles, lucioles) ───────────────────────
func _spawn_ambient_particles() -> void:
	var particles_node = get_node_or_null("Particles")
	if not particles_node:
		return
	for i in range(12):
		_create_floating_particle(particles_node)

func _create_floating_particle(parent: Node2D) -> void:
	var p = Node2D.new()
	var sprite = Sprite2D.new()
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Soit une feuille, soit une luciole
	if randf() > 0.5:
		# Feuille
		var points = PackedVector2Array([Vector2(6, 1), Vector2(11, 6), Vector2(6, 11), Vector2(1, 6)])
		var colors = PackedColorArray([Color(0.4, 0.7, 0.3, 0.6)])
		Draw.polygon(img, points, colors)
	else:
		# Luciole
		Draw.circle(img, Vector2(6, 6), 4, Color(0.8, 0.95, 0.5, 0.7))
		Draw.circle(img, Vector2(6, 6), 2, Color(1.0, 1.0, 0.8, 0.9))

	sprite.texture = ImageTexture.create_from_image(img)
	p.add_child(sprite)

	p.position = Vector2(randf_range(50, 1230), randf_range(50, 670))
	p.z_index = -1
	parent.add_child(p)

	# Animation de flottement
	var tween = p.create_tween().set_loops()
	var duration = randf_range(3.0, 7.0)
	var offset_x = randf_range(-60, 60)
	var offset_y = randf_range(-40, 40)
	tween.tween_property(p, "position:x", p.position.x + offset_x, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(p, "position:y", p.position.y + offset_y, duration * 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "modulate:a", 0.3, duration * 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "modulate:a", 0.8, duration * 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): p.position = Vector2(randf_range(50, 1230), randf_range(50, 670)))

# ─── Callbacks ───────────────────────────────────────────────────────
func _on_play_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		start_game.emit()
		queue_free()
	)

func _on_tutorial_pressed() -> void:
	show_tutorial.emit()

func _on_settings_pressed() -> void:
	show_settings.emit()

func _on_ai_check_pressed() -> void:
	var btn = get_node_or_null("CenterContainer/AIButton")
	if btn:
		btn.text = "🤖  Vérification IA..."
		btn.disabled = true
	# Vérifier via un timer simple
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = 5.0
	http.request_completed.connect(_on_ai_check_result)
	http.request("http://localhost:8080/health")

func _on_ai_check_result(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var btn = get_node_or_null("CenterContainer/AIButton")
	if btn:
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			btn.text = "🤖  IA Connectée ✅"
			btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		else:
			btn.text = "🤖  IA Hors ligne (jeu OK sans IA)"
			btn.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
		btn.disabled = false

func _on_quit_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		get_tree().quit()
	)

func _process(delta: float) -> void:
	title_anim_timer += delta
	# Légère oscillation du titre
	var center = get_node_or_null("CenterContainer")
	if center:
		var offset = sin(title_anim_timer * 0.8) * 3.0
		center.position.y = offset
