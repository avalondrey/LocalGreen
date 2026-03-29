extends CanvasLayer
class_name AchievementSystem

# ─── Système de succès / achievements ────────────────────────────────
signal achievement_unlocked(achievement: Dictionary)

var achievements := {
        "first_plant": {"title": "🌱 Premier Pas Vert", "description": "Planter votre première graine", "icon": "🌱", "unlocked": false, "condition_type": "plant", "condition_target": 1},
        "green_thumb": {"title": "🌿 Main Verte", "description": "Planter 10 graines", "icon": "🌿", "unlocked": false, "condition_type": "plant", "condition_target": 10},
        "farmer": {"title": "🧑‍🌾 Fermier", "description": "Planter 50 graines", "icon": "🧑‍🌾", "unlocked": false, "condition_type": "plant", "condition_target": 50},
        "first_harvest": {"title": "🧺 Première Récolte", "description": "Récolter votre premier légume", "icon": "🧺", "unlocked": false, "condition_type": "harvest", "condition_target": 1},
        "master_farmer": {"title": "🏆 Maître Fermier", "description": "Effectuer 25 récoltes", "icon": "🏆", "unlocked": false, "condition_type": "harvest", "condition_target": 25},
        "rich_farmer": {"title": "💰 Fermier Riche", "description": "Accumuler 200 pièces", "icon": "💰", "unlocked": false, "condition_type": "coins", "condition_target": 200},
        "waterboy": {"title": "💧 L'Arroseur", "description": "Arroser 50 fois", "icon": "💧", "unlocked": false, "condition_type": "water", "condition_target": 50},
        "full_garden": {"title": "🏡 Jardin Complet", "description": "Remplir toutes les cases de la grille", "icon": "🏡", "unlocked": false, "condition_type": "full_grid", "condition_target": 1},
        "survivor": {"title": "📅 Survivant", "description": "Atteindre le jour 10", "icon": "📅", "unlocked": false, "condition_type": "day", "condition_target": 10},
        "seasonal": {"title": "🌸 Cycle Complet", "description": "Vivre les 4 saisons", "icon": "🌸", "unlocked": false, "condition_type": "all_seasons", "condition_target": 1},
        "collector": {"title": "📦 Collectionneur", "description": "Avoir 5 de chaque légume en stock", "icon": "📦", "unlocked": false, "condition_type": "inventory", "condition_target": 5},
        "ai_friend": {"title": "🤖 Ami de l'IA", "description": "Recevoir une quête de l'IA", "icon": "🤖", "unlocked": false, "condition_type": "ai_quest", "condition_target": 1}
}

var seasons_seen: Array = []
var unlock_queue: Array = []
var current_popup: Control = null

@onready var game_manager: Node = get_parent().get_node_or_null("GameManager")
@onready var greenhouse: Node = get_parent().get_node_or_null("GreenhouseGrid")

func _ready() -> void:
        print("🏅 AchievementSystem initialisé — %d succès à débloquer" % achievements.size())

func _process(_delta: float) -> void:
        if current_popup == null and unlock_queue.size() > 0:
                _show_achievement_popup(unlock_queue.pop_front())

func check_all() -> void:
        if not game_manager: return
        _check_achievement("plant", game_manager.total_planted)
        _check_achievement("harvest", game_manager.total_harvested)
        _check_achievement("water", game_manager.total_watered)
        _check_achievement("coins", game_manager.coins)
        _check_achievement("day", game_manager.day_number)
        if greenhouse and greenhouse.get_plant_count() >= 24:
                _check_achievement("full_grid", 1)
        var inv = game_manager.inventory
        if inv.get("tomato", 0) >= 5 and inv.get("carrot", 0) >= 5 and inv.get("lettuce", 0) >= 5:
                _check_achievement("inventory", 5)
        if seasons_seen.size() >= 4:
                _check_achievement("all_seasons", 1)

func on_season_change(season_name: String) -> void:
        if not season_name in seasons_seen: seasons_seen.append(season_name)
        if seasons_seen.size() >= 4: _check_achievement("all_seasons", 1)

func on_ai_quest_received() -> void:
        _check_achievement("ai_quest", 1)

func _check_achievement(condition_type: String, current_value: int) -> void:
        for key in achievements:
                var ach = achievements[key]
                if ach["unlocked"]: continue
                if ach["condition_type"] == condition_type and current_value >= ach["condition_target"]:
                        _unlock(key)

func _unlock(key: String) -> void:
        if achievements[key]["unlocked"]: return
        achievements[key]["unlocked"] = true
        print("🏅 Succès débloqué : %s" % achievements[key]["title"])
        achievement_unlocked.emit(achievements[key])
        unlock_queue.append(achievements[key])

func _show_achievement_popup(ach: Dictionary) -> void:
        var popup = PanelContainer.new()
        popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
        popup.offset_top = 60; popup.offset_left = -160
        popup.offset_right = 160; popup.offset_bottom = 120
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.1, 0.1, 0.05, 0.95)
        style.border_color = Color(0.9, 0.8, 0.2, 0.9)
        style.border_width_top = 3; style.border_width_bottom = 3
        style.border_width_left = 3; style.border_width_right = 3
        style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
        style.corner_radius_bottom_right = 10; style.corner_radius_bottom_left = 10
        style.set_content_margin_all(10)
        style.shadow_color = Color(0.9, 0.8, 0.2, 0.3); style.shadow_size = 10
        popup.add_theme_stylebox_override("panel", style)
        var vbox = VBoxContainer.new()
        vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
        vbox.add_theme_constant_override("separation", 4)
        var badge = Label.new(); badge.text = "🏅 Succès Débloqué !"
        badge.add_theme_font_size_override("font_size", 11)
        badge.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
        badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(badge)
        var icon_title = Label.new(); icon_title.text = "%s %s" % [ach["icon"], ach["title"]]
        icon_title.add_theme_font_size_override("font_size", 16)
        icon_title.add_theme_color_override("font_color", Color(1, 1, 0.9))
        icon_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(icon_title)
        var desc = Label.new(); desc.text = ach["description"]
        desc.add_theme_font_size_override("font_size", 11)
        desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
        desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(desc)
        popup.add_child(vbox); add_child(popup); current_popup = popup
        popup.position.y = -80
        var tween = create_tween()
        tween.tween_property(popup, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_BACK)
        tween.tween_property(popup, "modulate:a", 1.0, 0.2)
        tween.tween_chain().tween_delay(3.0)
        tween.tween_property(popup, "position:y", -80.0, 0.3)
        tween.tween_property(popup, "modulate:a", 0.0, 0.2)
        tween.tween_callback(func(): popup.queue_free(); current_popup = null)

var achievements_panel: PanelContainer
var is_panel_open: bool = false

func toggle_panel() -> void:
        if is_panel_open:
                close_panel()
        else:
                open_panel()

func open_panel() -> void:
        if is_panel_open: return
        is_panel_open = true; _build_panel()

func close_panel() -> void:
        is_panel_open = false
        if achievements_panel and is_instance_valid(achievements_panel):
                var tween = create_tween()
                tween.tween_property(achievements_panel, "modulate:a", 0.0, 0.2)
                tween.tween_callback(achievements_panel.queue_free)

func _build_panel() -> void:
        if achievements_panel and is_instance_valid(achievements_panel): achievements_panel.queue_free()
        achievements_panel = PanelContainer.new()
        achievements_panel.set_anchors_preset(Control.PRESET_CENTER)
        achievements_panel.offset_left = -250; achievements_panel.offset_top = -250
        achievements_panel.offset_right = 250; achievements_panel.offset_bottom = 250
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.08, 0.10, 0.08, 0.97)
        style.border_color = Color(0.9, 0.8, 0.2, 0.8)
        style.border_width_top = 2; style.border_width_bottom = 2
        style.border_width_left = 2; style.border_width_right = 2
        style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
        style.corner_radius_bottom_right = 10; style.corner_radius_bottom_left = 10
        style.set_content_margin_all(12)
        achievements_panel.add_theme_stylebox_override("panel", style)
        var vbox = VBoxContainer.new()
        vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
        vbox.add_theme_constant_override("separation", 6)
        var title = Label.new()
        title.text = "🏅 Succès (%d/%d)" % [_count_unlocked(), achievements.size()]
        title.add_theme_font_size_override("font_size", 18)
        title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(title)
        var scroll = ScrollContainer.new(); scroll.custom_minimum_size = Vector2(0, 380)
        var inner = VBoxContainer.new(); inner.add_theme_constant_override("separation", 4)
        for key in achievements:
                var ach = achievements[key]
                var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 8)
                var icon = Label.new()
                icon.text = ach["icon"] if ach["unlocked"] else "🔒"
                icon.custom_minimum_size = Vector2(30, 0); row.add_child(icon)
                var name_lbl = Label.new(); name_lbl.text = ach["title"]
                name_lbl.custom_minimum_size = Vector2(160, 0)
                name_lbl.add_theme_font_size_override("font_size", 12)
                name_lbl.add_theme_color_override("font_color", Color(1, 1, 0.9) if ach["unlocked"] else Color(0.4, 0.4, 0.4))
                row.add_child(name_lbl)
                var desc_lbl = Label.new(); desc_lbl.text = ach["description"]
                desc_lbl.add_theme_font_size_override("font_size", 10)
                desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6) if ach["unlocked"] else Color(0.3, 0.3, 0.3))
                row.add_child(desc_lbl); inner.add_child(row)
        scroll.add_child(inner); vbox.add_child(scroll)
        var close_btn = Button.new(); close_btn.text = "✖ Fermer"
        close_btn.pressed.connect(close_panel)
        close_btn.add_theme_font_size_override("font_size", 12); vbox.add_child(close_btn)
        achievements_panel.add_child(vbox); add_child(achievements_panel)
        achievements_panel.modulate.a = 0.0
        var tween = create_tween()
        tween.tween_property(achievements_panel, "modulate:a", 1.0, 0.2)

func _count_unlocked() -> int:
        var count = 0
        for key in achievements:
                if achievements[key]["unlocked"]: count += 1
        return count

func _unhandled_input(event: InputEvent) -> void:
        if event is InputEventKey and event.pressed and event.keycode == KEY_J:
                toggle_panel()
