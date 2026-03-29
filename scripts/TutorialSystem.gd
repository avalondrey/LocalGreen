extends CanvasLayer
class_name TutorialSystem

# ─── Système de tutoriel interactif ──────────────────────────────────
signal tutorial_completed()

var tutorial_steps: Array = []
var current_step: int = 0
var is_active: bool = false
var tutorial_panel: PanelContainer
var highlight_rect: ColorRect

func _ready() -> void:
	print("📖 TutorialSystem initialisé")
	_setup_tutorial_steps()

func _setup_tutorial_steps() -> void:
	tutorial_steps = [
		{"title": "Bienvenue dans LocalGreen ! 🌱", "text": "Vous êtes le nouveau jardinier du village !\nApprenez à cultiver votre jardin.\n\nCliquez pour continuer...", "highlight": ""},
		{"title": "🔧 La Barre d'Outils", "text": "En bas de l'écran se trouvent vos outils :\n\n🌱 [1] Planter — placez des graines\n💧 [2] Arroser — donnez de l'eau\n🧺 [3] Récolter — récoltez quand c'est prêt\n🗑️ [4] Retirer — supprimez une plante", "highlight": "toolbar"},
		{"title": "🌱 Planter une graine", "text": "1. Sélectionnez l'outil « Planter » (touche 1)\n2. Choisissez un type de plante\n3. Cliquez sur une tuile vide\n\nCommencez par planter une Tomate !", "highlight": "grid"},
		{"title": "💧 Arroser vos plantes", "text": "Les plantes ont besoin d'eau pour grandir !\n\n1. Sélectionnez « Arroser » (touche 2)\n2. Cliquez sur votre plante\n\nL'eau diminue avec le temps.", "highlight": "grid"},
		{"title": "📈 Les stades de croissance", "text": "Chaque plante passe par 5 stades :\n\n🌰 Graine → 🌱 Pousse → 🌿 Jeune\n→ ☘️ Mature → ✨ Prêt à récolter\n\nSurvolez une plante pour voir sa progression !", "highlight": ""},
		{"title": "🧺 Récolter", "text": "Quand une plante est au stade ✨, récoltez-la !\n\n1. Sélectionnez « Récolter » (touche 3)\n2. Cliquez sur la plante mature\n\nVous gagnez des pièces et des points !", "highlight": ""},
		{"title": "🛒 La Boutique (touche B)", "text": "Appuyez sur B pour ouvrir la boutique.\n\nAchetez des graines avec vos pièces.\nVendez vos récoltes pour gagner plus !", "highlight": ""},
		{"title": "🌤️ Météo et Saisons", "text": "La météo change automatiquement :\n\n☀️ Soleil = croissance rapide\n🌧️ Pluie = arrosage automatique\n⛈️ Orage = beaucoup d'eau\n\nLes saisons changent tous les 3 jours !", "highlight": ""},
		{"title": "📜 Quêtes journalières", "text": "Complétez des quêtes pour gagner des bonus !\nElles apparaissent en haut à droite.\n\nL'IA peut générer des quêtes uniques.", "highlight": "quest"},
		{"title": "Vous êtes prêt ! 🎉", "text": "Vous connaissez les bases du jardinage.\nExplorez et amusez-vous !\n\nBonne chance, jeune jardinier ! 🌿", "highlight": ""}
	]

func start_tutorial() -> void:
	if is_active: return
	is_active = true; current_step = 0
	_build_tutorial_ui(); _show_step()

func skip_tutorial() -> void:
	is_active = false
	if tutorial_panel and is_instance_valid(tutorial_panel):
		var tween = create_tween()
		tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(tutorial_panel.queue_free)
	if highlight_rect and is_instance_valid(highlight_rect): highlight_rect.queue_free()

func _build_tutorial_ui() -> void:
	if tutorial_panel and is_instance_valid(tutorial_panel): tutorial_panel.queue_free()
	if highlight_rect and is_instance_valid(highlight_rect): highlight_rect.queue_free()
	highlight_rect = ColorRect.new()
	highlight_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	highlight_rect.color = Color(0, 0, 0, 0.4)
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highlight_rect)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_panel.offset_left = -220; tutorial_panel.offset_top = -180
	tutorial_panel.offset_right = 220; tutorial_panel.offset_bottom = 180
	tutorial_panel.z_index = 500
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.10, 0.97)
	style.border_color = Color(0.4, 0.65, 0.4, 0.9)
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_width_left = 2; style.border_width_right = 2
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12; style.corner_radius_bottom_left = 12
	style.set_content_margin_all(16)
	style.shadow_color = Color(0, 0, 0, 0.5); style.shadow_size = 12
	tutorial_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	vbox.add_theme_constant_override("separation", 10)

	var icon = Label.new(); icon.text = "📖"; icon.add_theme_font_size_override("font_size", 32)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(icon)
	var title = Label.new(); title.name = "TutorialTitle"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(title)
	vbox.add_child(HSeparator.new())
	var text = Label.new(); text.name = "TutorialText"
	text.add_theme_font_size_override("font_size", 13)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; vbox.add_child(text)
	var progress = Label.new(); progress.name = "TutorialProgress"
	progress.add_theme_font_size_override("font_size", 10)
	progress.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(progress)

	var btns = HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 12)
	var prev_btn = Button.new(); prev_btn.text = "◀ Précédent"
	prev_btn.add_theme_font_size_override("font_size", 12)
	prev_btn.pressed.connect(_prev_step); prev_btn.name = "PrevBtn"; btns.add_child(prev_btn)
	var next_btn = Button.new(); next_btn.text = "Suivant ▶"
	next_btn.add_theme_font_size_override("font_size", 12)
	next_btn.pressed.connect(_next_step); next_btn.name = "NextBtn"; btns.add_child(next_btn)
	var skip_btn = Button.new(); skip_btn.text = "✖ Passer"
	skip_btn.add_theme_font_size_override("font_size", 11)
	skip_btn.pressed.connect(skip_tutorial); btns.add_child(skip_btn)
	vbox.add_child(btns)

	tutorial_panel.add_child(vbox); add_child(tutorial_panel)
	tutorial_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.3)

func _show_step() -> void:
	if current_step >= tutorial_steps.size():
		skip_tutorial(); tutorial_completed.emit(); return
	var step = tutorial_steps[current_step]
	var t = tutorial_panel.get_node_or_null("VBoxContainer/TutorialTitle")
	var tx = tutorial_panel.get_node_or_null("VBoxContainer/TutorialText")
	var p = tutorial_panel.get_node_or_null("VBoxContainer/TutorialProgress")
	if t: t.text = step["title"]
	if tx: tx.text = step["text"]
	if p: p.text = "Étape %d / %d" % [current_step + 1, tutorial_steps.size()]
	var prev_btn = tutorial_panel.get_node_or_null("VBoxContainer/HBoxContainer/PrevBtn")
	var next_btn = tutorial_panel.get_node_or_null("VBoxContainer/HBoxContainer/NextBtn")
	if prev_btn: prev_btn.visible = current_step > 0
	if next_btn: next_btn.text = "Terminer ✅" if current_step == tutorial_steps.size() - 1 else "Suivant ▶"

func _next_step() -> void:
	current_step += 1
	if current_step >= tutorial_steps.size(): skip_tutorial(); tutorial_completed.emit()
	else:
		var tween = create_tween()
		tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.15)
		tween.tween_callback(_show_step)
		tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.15)

func _prev_step() -> void:
	if current_step > 0:
		current_step -= 1
		var tween = create_tween()
		tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.15)
		tween.tween_callback(_show_step)
		tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.15)
