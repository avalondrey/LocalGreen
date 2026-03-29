extends CanvasLayer
class_name UIManager

# ─── UI du jeu : barre d'outils, HUD, sélecteur de plantes ───────────
# Tout est dessiné par programme (pas d'assets externes requis)

# ─── Références ──────────────────────────────────────────────────────
@onready var greenhouse: GreenhouseGrid = get_parent().get_node_or_null("GreenhouseGrid")
@onready var game_manager: GameManager = get_parent().get_node_or_null("GameManager")

# ─── Conteneurs UI ───────────────────────────────────────────────────
var toolbar: PanelContainer
var hud_panel: PanelContainer
var quest_panel: PanelContainer
var inventory_panel: PanelContainer
var notification_label: Label
var season_label: Label

var tool_buttons: Dictionary = {}
var plant_buttons: Dictionary = {}

# ─── Notifications ───────────────────────────────────────────────────
var notification_timer: float = 0.0
var notification_queue: Array = []

# ─── Initialisation ──────────────────────────────────────────────────
func _ready() -> void:
        print("🖥️ UIManager initialisé")
        _build_hud()
        _build_toolbar()
        _build_quest_panel()
        _build_inventory_panel()
        _build_notification_system()
        _connect_signals()

# ─── HUD (en haut de l'écran) ────────────────────────────────────────
func _build_hud() -> void:
        hud_panel = PanelContainer.new()
        hud_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 8)
        hud_panel.offset_top = 8
        hud_panel.offset_bottom = 52

        var hbox = HBoxContainer.new()
        hbox.add_theme_constant_override("separation", 20)
        hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)

        # Titre
        var title = Label.new()
        title.text = "🌱 LocalGreen"
        title.add_theme_font_size_override("font_size", 18)
        title.add_theme_color_override("font_color", Color(0.15, 0.35, 0.15))
        hbox.add_child(title)

        hbox.add_child(_create_spacer_h())

        # Score
        var score_label = Label.new()
        score_label.name = "ScoreLabel"
        score_label.text = "⭐ Score: 0"
        score_label.add_theme_font_size_override("font_size", 14)
        score_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.1))
        hbox.add_child(score_label)

        # Pièces
        var coins_label = Label.new()
        coins_label.name = "CoinsLabel"
        coins_label.text = "🪙 0"
        coins_label.add_theme_font_size_override("font_size", 14)
        coins_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.0))
        hbox.add_child(coins_label)

        hbox.add_child(_create_spacer_h())

        # Jour
        var day_label = Label.new()
        day_label.name = "DayLabel"
        day_label.text = "📅 Jour 1"
        day_label.add_theme_font_size_override("font_size", 14)
        hbox.add_child(day_label)

        # Saison
        season_label = Label.new()
        season_label.name = "SeasonLabel"
        season_label.text = "🌸 Printemps"
        season_label.add_theme_font_size_override("font_size", 14)
        hbox.add_child(season_label)

        hbox.add_child(_create_spacer_h())

        # Bouton sauvegarder
        var save_btn = _create_button("💾 Sauver", "save_game")
        hbox.add_child(save_btn)

        # Bouton charger
        var load_btn = _create_button("📂 Charger", "load_game")
        hbox.add_child(load_btn)

        hud_panel.add_child(hbox)
        add_child(hud_panel)

# ─── Barre d'outils (en bas) ────────────────────────────────────────
func _build_toolbar() -> void:
        toolbar = PanelContainer.new()
        toolbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 8)
        toolbar.offset_top = -64
        toolbar.offset_bottom = -8

        var hbox = HBoxContainer.new()
        hbox.add_theme_constant_override("separation", 10)
        hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
        hbox.alignment = BoxContainer.ALIGNMENT_CENTER

        # Label outils
        var tool_label = Label.new()
        tool_label.text = "🔧 Outils:"
        tool_label.add_theme_font_size_override("font_size", 13)
        hbox.add_child(tool_label)

        # Boutons d'outils
        var tools = [
                {"name": "plant", "icon": "🌱", "label": "Planter", "key": "1"},
                {"name": "water", "icon": "💧", "label": "Arroser", "key": "2"},
                {"name": "harvest", "icon": "🧺", "label": "Récolter", "key": "3"},
                {"name": "remove", "icon": "🗑️", "label": "Retirer", "key": "4"}
        ]

        for tool in tools:
                var btn = _create_tool_button(tool["icon"], tool["label"] + " [%s]" % tool["key"], tool["name"])
                tool_buttons[tool["name"]] = btn
                hbox.add_child(btn)

        # Séparateur
        var sep = VSeparator.new()
        hbox.add_child(sep)

        # Label plantes
        var plant_label = Label.new()
        plant_label.text = "🌿 Plantes:"
        plant_label.add_theme_font_size_override("font_size", 13)
        hbox.add_child(plant_label)

        # Boutons de sélection de plante
        var plant_types = [
                {"name": "tomato", "icon": "🍅", "label": "Tomate", "index": 0},
                {"name": "carrot", "icon": "🥕", "label": "Carotte", "index": 1},
                {"name": "lettuce", "icon": "🥬", "label": "Laitue", "index": 2}
        ]

        for pt in plant_types:
                var btn = _create_plant_button(pt["icon"], pt["label"], pt["name"], pt["index"])
                plant_buttons[pt["name"]] = btn
                hbox.add_child(btn)

        toolbar.add_child(hbox)
        add_child(toolbar)

# ─── Panneau de quête (à droite) ─────────────────────────────────────
func _build_quest_panel() -> void:
        quest_panel = PanelContainer.new()
        quest_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        quest_panel.offset_left = -220
        quest_panel.offset_top = 60
        quest_panel.offset_right = -8
        quest_panel.offset_bottom = 160

        var vbox = VBoxContainer.new()
        vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)

        var title = Label.new()
        title.text = "📜 Quête du jour"
        title.add_theme_font_size_override("font_size", 13)
        title.add_theme_color_override("font_color", Color(0.3, 0.2, 0.5))
        vbox.add_child(title)

        var desc = Label.new()
        desc.name = "QuestDescription"
        desc.text = "Premiers pas au jardin"
        desc.add_theme_font_size_override("font_size", 11)
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        vbox.add_child(desc)

        var progress = Label.new()
        progress.name = "QuestProgress"
        progress.text = "0 / 3"
        progress.add_theme_font_size_override("font_size", 12)
        progress.add_theme_color_override("font_color", Color(0.2, 0.5, 0.2))
        vbox.add_child(progress)

        var reward = Label.new()
        reward.name = "QuestReward"
        reward.text = "🪙 +20 | ⭐ +50"
        reward.add_theme_font_size_override("font_size", 11)
        reward.add_theme_color_override("font_color", Color(0.6, 0.4, 0.1))
        vbox.add_child(reward)

        quest_panel.add_child(vbox)
        add_child(quest_panel)

# ─── Panneau d'inventaire (à gauche) ────────────────────────────────
func _build_inventory_panel() -> void:
        inventory_panel = PanelContainer.new()
        inventory_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
        inventory_panel.offset_left = 8
        inventory_panel.offset_top = 60
        inventory_panel.offset_right = 180
        inventory_panel.offset_bottom = 220

        var vbox = VBoxContainer.new()
        vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)

        var title = Label.new()
        title.text = "🎒 Inventaire"
        title.add_theme_font_size_override("font_size", 13)
        title.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
        vbox.add_child(title)

        var items = [
                {"key": "tomato", "icon": "🍅", "label": "Tomates"},
                {"key": "carrot", "icon": "🥕", "label": "Carottes"},
                {"key": "lettuce", "icon": "🥬", "label": "Laitues"},
                {"key": "seeds_tomato", "icon": "🌱", "label": "Graines 🍅"},
                {"key": "seeds_carrot", "icon": "🌱", "label": "Graines 🥕"},
                {"key": "seeds_lettuce", "icon": "🌱", "label": "Graines 🥬"}
        ]

        for item in items:
                var lbl = Label.new()
                lbl.name = "Inv_" + item["key"]
                lbl.text = "%s %s: 0" % [item["icon"], item["label"]]
                lbl.add_theme_font_size_override("font_size", 11)
                vbox.add_child(lbl)

        inventory_panel.add_child(vbox)
        add_child(inventory_panel)

# ─── Système de notifications ────────────────────────────────────────
func _build_notification_system() -> void:
        notification_label = Label.new()
        notification_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
        notification_label.offset_top = 70
        notification_label.offset_left = -150
        notification_label.offset_right = 150
        notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        notification_label.add_theme_font_size_override("font_size", 16)
        notification_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.2))
        notification_label.modulate.a = 0.0
        notification_label.z_index = 100
        add_child(notification_label)

func show_notification(text: String) -> void:
        notification_queue.append(text)

func _process(delta: float) -> void:
        if notification_label.modulate.a > 0:
                notification_timer -= delta
                if notification_timer <= 0:
                        var tween = create_tween()
                        tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)
        elif notification_queue.size() > 0:
                notification_label.text = notification_queue.pop_front()
                notification_label.modulate.a = 1.0
                notification_timer = 2.5

# ─── Connexion des signaux ───────────────────────────────────────────
func _connect_signals() -> void:
        if greenhouse:
                greenhouse.tool_changed.connect(_on_tool_changed)
                greenhouse.plant_planted.connect(func(pos, plant):
                        var name = PlantData.PlantType.keys()[plant.plant_type]
                        show_notification("🌱 %s plantée !" % name)
                )
                greenhouse.plant_harvested.connect(func(pos, value):
                        show_notification("🧺 Récoltée ! +⭐%d" % [value * 10])
                )

        if game_manager:
                game_manager.score_changed.connect(_on_score_changed)
                game_manager.coins_changed.connect(_on_coins_changed)
                game_manager.day_changed.connect(_on_day_changed)
                game_manager.quest_updated.connect(_on_quest_updated)
                game_manager.season_changed.connect(_on_season_changed)
                game_manager.inventory_updated.connect(_on_inventory_updated)

# ─── Callbacks ───────────────────────────────────────────────────────
func _on_tool_changed(tool_name: String) -> void:
        for name in tool_buttons:
                var btn = tool_buttons[name] as Button
                if name == tool_name:
                        btn.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
                        btn.add_theme_font_size_override("font_size", 14)
                else:
                        btn.add_theme_color_override("font_color", Color(1, 1, 1))
                        btn.add_theme_font_size_override("font_size", 12)

func _on_score_changed(new_score: int) -> void:
        _update_hud_label("ScoreLabel", "⭐ Score: %d" % new_score)

func _on_coins_changed(new_coins: int) -> void:
        _update_hud_label("CoinsLabel", "🪙 %d" % new_coins)

func _on_day_changed(day: int) -> void:
        _update_hud_label("DayLabel", "📅 Jour %d" % day)
        show_notification("🌅 Nouveau jour ! Jour %d" % day)

func _on_season_changed(season_name: String) -> void:
        var icons = {"Printemps": "🌸", "Été": "☀️", "Automne": "🍂", "Hiver": "❄️"}
        var icon = icons.get(season_name, "🌸")
        _update_hud_label("SeasonLabel", "%s %s" % [icon, season_name])
        show_notification("%s Saison : %s !" % [icon, season_name])

func _on_quest_updated(quest: Dictionary) -> void:
        if quest_panel and quest_panel.has_node("VBoxContainer"):
                var vbox = quest_panel.get_node("VBoxContainer")
                if vbox.has_node("QuestDescription"):
                        vbox.get_node("QuestDescription").text = quest.get("title", "")
                if vbox.has_node("QuestProgress"):
                        var current = quest.get("objective_current", 0)
                        var target = quest.get("objective_target", 0)
                        var text = "%d / %d" % [current, target]
                        if quest.get("completed", false):
                                text += " ✅"
                        vbox.get_node("QuestProgress").text = text
                if vbox.has_node("QuestReward"):
                        var c = quest.get("reward_coins", 0)
                        var x = quest.get("reward_xp", 0)
                        vbox.get_node("QuestReward").text = "🪙 +%d | ⭐ +%d" % [c, x]

func _on_inventory_updated(items: Dictionary) -> void:
        if not inventory_panel:
                return
        for key in items:
                var node_name = "Inv_%s" % key
                if inventory_panel.has_node("VBoxContainer/" + node_name):
                        var lbl = inventory_panel.get_node("VBoxContainer/" + node_name) as Label
                        var original = lbl.text.rsplit(": ", true, 1)[0]
                        lbl.text = "%s: %d" % [original, items[key]]

# ─── Utilitaires UI ──────────────────────────────────────────────────
func _create_button(text: String, action: String) -> Button:
        var btn = Button.new()
        btn.text = text
        btn.pressed.connect(_handle_button_action.bind(action))
        btn.add_theme_font_size_override("font_size", 11)
        return btn

func _create_tool_button(icon: String, label: String, tool_name: String) -> Button:
        var btn = Button.new()
        btn.text = "%s %s" % [icon, label]
        btn.pressed.connect(func():
                if greenhouse:
                        greenhouse.set_tool(tool_name)
        )
        btn.add_theme_font_size_override("font_size", 12)
        # Premier outil sélectionné par défaut
        if tool_name == "plant":
                btn.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
                btn.add_theme_font_size_override("font_size", 14)
        return btn

func _create_plant_button(icon: String, label: String, name: String, index: int) -> Button:
        var btn = Button.new()
        btn.text = "%s %s" % [icon, label]
        btn.pressed.connect(func():
                if greenhouse:
                        greenhouse.set_plant_type(index)
                        greenhouse.set_tool("plant")
                        show_notification("🌿 Plant sélectionné : %s" % label)
        )
        btn.add_theme_font_size_override("font_size", 12)
        return btn

func _create_spacer_h() -> Control:
        var spacer = Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        return spacer

func _update_hud_label(node_name: String, text: String) -> void:
        if hud_panel and hud_panel.has_node(node_name):
                hud_panel.get_node(node_name).text = text

func _handle_button_action(action: String) -> void:
        match action:
                "save_game":
                        if game_manager:
                                game_manager.save_game()
                                show_notification("💾 Jeu sauvegardé !")
                "load_game":
                        if game_manager:
                                if game_manager.load_game():
                                        show_notification("📂 Jeu chargé !")
                                else:
                                        show_notification("❌ Aucune sauvegarde trouvée")

# ─── Raccourcis clavier ──────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
        if event is InputEventKey and event.pressed:
                match event.keycode:
                        KEY_1:
                                if greenhouse: greenhouse.set_tool("plant")
                        KEY_2:
                                if greenhouse: greenhouse.set_tool("water")
                        KEY_3:
                                if greenhouse: greenhouse.set_tool("harvest")
                        KEY_4:
                                if greenhouse: greenhouse.set_tool("remove")
                        KEY_F5:
                                if game_manager: game_manager.save_game(); show_notification("💾 Sauvegardé !")
                        KEY_F9:
                                if game_manager:
                                        if game_manager.load_game():
                                                show_notification("📂 Chargé !")
