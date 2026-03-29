extends CanvasLayer
class_name ShopSystem

# ─── Boutique pour acheter graines et vendre récoltes ────────────────
signal item_bought(item_name: String, quantity: int, price: int)
signal item_sold(item_name: String, quantity: int, price: int)
signal shop_opened()
signal shop_closed()

var seed_prices := {
        "seeds_tomato": 5, "seeds_carrot": 4, "seeds_lettuce": 3, "fertilizer": 8
}
var sell_prices := {
        "tomato": 12, "carrot": 10, "lettuce": 7
}
var is_open: bool = false
var current_tab: String = "buy"
var shop_panel: PanelContainer

@onready var game_manager: Node = get_parent().get_node_or_null("GameManager")

func _ready() -> void:
        print("🛒 ShopSystem initialisé")

func toggle_shop() -> void:
        if is_open:
                close_shop()
        else:
                open_shop()

func open_shop() -> void:
        if is_open: return
        is_open = true
        _build_shop_ui()
        shop_opened.emit()

func close_shop() -> void:
        if not is_open: return
        is_open = false
        if shop_panel and is_instance_valid(shop_panel):
                var tween = create_tween()
                tween.tween_property(shop_panel, "modulate:a", 0.0, 0.2)
                tween.tween_callback(shop_panel.queue_free)
        shop_closed.emit()

func _build_shop_ui() -> void:
        if shop_panel and is_instance_valid(shop_panel): shop_panel.queue_free()
        shop_panel = PanelContainer.new()
        shop_panel.set_anchors_preset(Control.PRESET_CENTER)
        shop_panel.offset_left = -200; shop_panel.offset_top = -220
        shop_panel.offset_right = 200; shop_panel.offset_bottom = 220
        _add_panel_style(shop_panel, Color(0.12, 0.15, 0.12, 0.95))

        var vbox = VBoxContainer.new()
        vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
        vbox.add_theme_constant_override("separation", 8)

        var title = Label.new()
        title.text = "🛒 Boutique du Jardin"
        title.add_theme_font_size_override("font_size", 20)
        title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vbox.add_child(title)

        var balance = Label.new(); balance.name = "BalanceLabel"
        if game_manager: balance.text = "🪙 Solde: %d pièces" % game_manager.coins
        else: balance.text = "🪙 Solde: 0"
        balance.add_theme_font_size_override("font_size", 13)
        balance.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
        balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vbox.add_child(balance)
        vbox.add_child(HSeparator.new())

        var tabs_hbox = HBoxContainer.new()
        tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
        tabs_hbox.add_theme_constant_override("separation", 4)
        var buy_tab = _create_tab_button("🌱 Acheter", "buy")
        var sell_tab = _create_tab_button("💰 Vendre", "sell")
        tabs_hbox.add_child(buy_tab); tabs_hbox.add_child(sell_tab)
        vbox.add_child(tabs_hbox)

        var scroll = ScrollContainer.new(); scroll.custom_minimum_size = Vector2(0, 200)
        var content = VBoxContainer.new(); content.add_theme_constant_override("separation", 4)
        content.name = "ShopContent"
        _refresh_shop_content(content)
        scroll.add_child(content); vbox.add_child(scroll)

        var close_btn = Button.new(); close_btn.text = "✖ Fermer (Echap)"
        close_btn.pressed.connect(close_shop)
        close_btn.add_theme_font_size_override("font_size", 12)
        vbox.add_child(close_btn)
        shop_panel.add_child(vbox); add_child(shop_panel)
        shop_panel.modulate.a = 0.0
        var tween = create_tween()
        tween.tween_property(shop_panel, "modulate:a", 1.0, 0.2)

func _refresh_shop_content(parent: VBoxContainer) -> void:
        for child in parent.get_children(): child.queue_free()
        if current_tab == "buy": _add_buy_items(parent)
        else: _add_sell_items(parent)

func _add_buy_items(parent: VBoxContainer) -> void:
        var items = [
                {"key": "seeds_tomato", "icon": "🌱", "name": "Graines de Tomate", "price": seed_prices["seeds_tomato"]},
                {"key": "seeds_carrot", "icon": "🌱", "name": "Graines de Carotte", "price": seed_prices["seeds_carrot"]},
                {"key": "seeds_lettuce", "icon": "🌱", "name": "Graines de Laitue", "price": seed_prices["seeds_lettuce"]},
                {"key": "fertilizer", "icon": "🧪", "name": "Engrais", "price": seed_prices["fertilizer"]},
        ]
        for item in items:
                var row = _create_shop_row(item["icon"], item["name"], "%d 🪙" % item["price"])
                var stock_label = Label.new()
                stock_label.text = "Stock: %d" % _get_inventory_count(item["key"])
                stock_label.add_theme_font_size_override("font_size", 10)
                stock_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
                row.add_child(stock_label)
                var btn = Button.new(); btn.text = "Acheter x5"
                btn.custom_minimum_size = Vector2(80, 28)
                btn.add_theme_font_size_override("font_size", 10)
                btn.pressed.connect(_buy_item.bind(item["key"], 5, item["price"]))
                row.add_child(btn)
                parent.add_child(row)

func _add_sell_items(parent: VBoxContainer) -> void:
        var items = [
                {"key": "tomato", "icon": "🍅", "name": "Tomate", "price": sell_prices["tomato"]},
                {"key": "carrot", "icon": "🥕", "name": "Carotte", "price": sell_prices["carrot"]},
                {"key": "lettuce", "icon": "🥬", "name": "Laitue", "price": sell_prices["lettuce"]},
        ]
        var has_items = false
        for item in items:
                var stock = _get_inventory_count(item["key"])
                if stock == 0: continue
                has_items = true
                var row = _create_shop_row(item["icon"], item["name"], "%d 🪙/u" % item["price"])
                var stock_label = Label.new()
                stock_label.text = "Qté: %d" % stock
                stock_label.add_theme_font_size_override("font_size", 10)
                stock_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
                row.add_child(stock_label)
                var btn = Button.new(); btn.text = "Vendre tout"
                btn.custom_minimum_size = Vector2(80, 28)
                btn.add_theme_font_size_override("font_size", 10)
                btn.pressed.connect(_sell_item.bind(item["key"], stock, item["price"]))
                row.add_child(btn)
                parent.add_child(row)
        if not has_items:
                var empty = Label.new(); empty.text = "Rien à vendre pour le moment."
                empty.add_theme_font_size_override("font_size", 12)
                empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
                empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                parent.add_child(empty)

func _create_shop_row(icon: String, name: String, price_text: String) -> HBoxContainer:
        var row = HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        var icon_label = Label.new(); icon_label.text = icon
        icon_label.custom_minimum_size = Vector2(30, 0); row.add_child(icon_label)
        var name_label = Label.new(); name_label.text = name
        name_label.custom_minimum_size = Vector2(120, 0)
        name_label.add_theme_font_size_override("font_size", 12); row.add_child(name_label)
        var price_label = Label.new(); price_label.text = price_text
        price_label.custom_minimum_size = Vector2(60, 0)
        price_label.add_theme_font_size_override("font_size", 11)
        price_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
        row.add_child(price_label)
        return row

func _create_tab_button(text: String, tab_name: String) -> Button:
        var btn = Button.new(); btn.text = text
        btn.custom_minimum_size = Vector2(100, 32)
        btn.add_theme_font_size_override("font_size", 13)
        btn.pressed.connect(func():
                current_tab = tab_name
                var content = shop_panel.get_node_or_null("VBoxContainer/ScrollContainer/ShopContent")
                if content: _refresh_shop_content(content)
        )
        if tab_name == current_tab:
                btn.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
        return btn

func _buy_item(item_key: String, quantity: int, unit_price: int) -> void:
        if not game_manager: return
        var total_cost = quantity * unit_price
        if game_manager.coins < total_cost:
                _show_notification("❌ Pas assez de pièces ! (Besoin: %d)" % total_cost); return
        game_manager.coins -= total_cost
        game_manager.inventory[item_key] = game_manager.inventory.get(item_key, 0) + quantity
        game_manager.inventory_updated.emit(game_manager.inventory)
        game_manager.coins_changed.emit(game_manager.coins)
        _show_notification("✅ Acheté x%d ! (-%d 🪙)" % [quantity, total_cost])
        item_bought.emit(item_key, quantity, total_cost)
        _update_balance()

func _sell_item(item_key: String, quantity: int, unit_price: int) -> void:
        if not game_manager: return
        var actual_qty = min(quantity, game_manager.inventory.get(item_key, 0))
        if actual_qty <= 0: return
        var total_earn = actual_qty * unit_price
        game_manager.coins += total_earn
        game_manager.inventory[item_key] -= actual_qty
        game_manager.score += total_earn
        game_manager.inventory_updated.emit(game_manager.inventory)
        game_manager.coins_changed.emit(game_manager.coins)
        game_manager.score_changed.emit(game_manager.score)
        _show_notification("💰 Vendu %d pour %d 🪙 !" % [actual_qty, total_earn])
        item_sold.emit(item_key, actual_qty, total_earn)
        _update_balance()

func _get_inventory_count(key: String) -> int:
        if game_manager: return game_manager.inventory.get(key, 0)
        return 0

func _update_balance() -> void:
        var label = shop_panel.get_node_or_null("VBoxContainer/BalanceLabel")
        if label and game_manager: label.text = "🪙 Solde: %d pièces" % game_manager.coins

func _show_notification(text: String) -> void:
        var notif = Label.new(); notif.text = text
        notif.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
        notif.offset_top = -40; notif.offset_left = -150; notif.offset_right = 150
        notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        notif.add_theme_font_size_override("font_size", 14)
        notif.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
        shop_panel.add_child(notif)
        var tween = create_tween()
        tween.tween_property(notif, "position:y", notif.position.y - 30, 1.5)
        tween.tween_parallel().tween_property(notif, "modulate:a", 0.0, 0.5).set_delay(1.0)
        tween.tween_callback(notif.queue_free)

func _add_panel_style(panel: PanelContainer, color: Color) -> void:
        var style = StyleBoxFlat.new()
        style.bg_color = color
        style.border_color = Color(0.4, 0.6, 0.4, 0.9)
        style.border_width_top = 3; style.border_width_bottom = 3
        style.border_width_left = 3; style.border_width_right = 3
        style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
        style.corner_radius_bottom_right = 12; style.corner_radius_bottom_left = 12
        style.set_content_margin_all(12)
        style.shadow_color = Color(0, 0, 0, 0.3); style.shadow_size = 8
        panel.add_theme_stylebox_override("panel", style)

func _unhandled_input(event: InputEvent) -> void:
        if event is InputEventKey and event.pressed:
                if event.keycode == KEY_ESCAPE and is_open: close_shop(); get_viewport().set_input_as_handled()
                if event.keycode == KEY_B and not event.echo: toggle_shop()
