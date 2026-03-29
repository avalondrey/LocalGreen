extends CanvasLayer
class_name ChatAI

# ─── Système de chat avec l'IA jardinier ─────────────────────────────
signal chat_message_sent(message: String)
signal chat_response_received(response: String)
signal chat_opened()
signal chat_closed()

var is_open: bool = false
var chat_panel: PanelContainer
var messages: Array = []
var max_messages: int = 50
const API_URL := "http://localhost:8080"
const TIMEOUT := 15.0

var suggested_questions := [
        "Comment faire pousser des tomates plus vite ?",
        "Quelle plante rapporte le plus ?",
        "Conseil pour débuter au jardin",
        "Que faire en hiver ?",
        "Comment bien gérer l'eau ?"
]

func _ready() -> void:
        print("💬 ChatAI initialisé")

func toggle_chat() -> void:
        if is_open:
                close_chat()
        else:
                open_chat()

func open_chat() -> void:
        if is_open: return
        is_open = true; _build_chat_ui(); chat_opened.emit()

func close_chat() -> void:
        is_open = false
        if chat_panel and is_instance_valid(chat_panel):
                var tween = create_tween()
                tween.tween_property(chat_panel, "modulate:a", 0.0, 0.2)
                tween.tween_callback(chat_panel.queue_free)
        chat_closed.emit()

func _build_chat_ui() -> void:
        if chat_panel and is_instance_valid(chat_panel): chat_panel.queue_free()
        chat_panel = PanelContainer.new()
        chat_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
        chat_panel.offset_left = -320; chat_panel.offset_top = -250
        chat_panel.offset_right = -20; chat_panel.offset_bottom = 250
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.08, 0.10, 0.08, 0.97)
        style.border_color = Color(0.5, 0.45, 0.3, 0.9)
        style.border_width_top = 2; style.border_width_bottom = 2
        style.border_width_left = 2; style.border_width_right = 2
        style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
        style.corner_radius_bottom_right = 10; style.corner_radius_bottom_left = 10
        style.set_content_margin_all(10)
        style.shadow_color = Color(0, 0, 0, 0.4); style.shadow_size = 8
        chat_panel.add_theme_stylebox_override("panel", style)

        var vbox = VBoxContainer.new()
        vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
        vbox.add_theme_constant_override("separation", 6)
        var title = HBoxContainer.new()
        var title_label = Label.new()
        title_label.text = "🤖 Jardinier IA — Mistral"
        title_label.add_theme_font_size_override("font_size", 15)
        title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
        title.add_child(title_label)
        var close_btn = Button.new(); close_btn.text = "✖"
        close_btn.custom_minimum_size = Vector2(30, 30)
        close_btn.pressed.connect(close_chat); title.add_child(close_btn)
        vbox.add_child(title)

        var scroll = ScrollContainer.new(); scroll.custom_minimum_size = Vector2(0, 320)
        var msg_container = VBoxContainer.new()
        msg_container.add_theme_constant_override("separation", 4)
        msg_container.name = "MessageContainer"
        scroll.add_child(msg_container); vbox.add_child(scroll)
        _add_message_to_ui("assistant", "Bonjour ! Je suis votre jardinier IA 🌱\nPosez-moi vos questions sur le jardinage !\n\nExemples :\n• Comment faire pousser des tomates ?\n• Quel est le meilleur moment pour planter ?")

        var sug_box = HBoxContainer.new(); sug_box.name = "SuggestionsBox"
        for i in range(2):
                if i < suggested_questions.size():
                        var btn = Button.new(); btn.text = suggested_questions[i]
                        btn.custom_minimum_size = Vector2(120, 0)
                        btn.add_theme_font_size_override("font_size", 9)
                        btn.pressed.connect(_send_suggestion.bind(suggested_questions[i]))
                        sug_box.add_child(btn)
        vbox.add_child(sug_box)

        var input_hbox = HBoxContainer.new()
        var input = LineEdit.new(); input.name = "ChatInput"
        input.placeholder_text = "Posez votre question..."
        input.custom_minimum_size = Vector2(0, 35)
        input.add_theme_font_size_override("font_size", 13)
        input.submit.connect(_send_message)
        input_hbox.add_child(input)
        var send_btn = Button.new(); send_btn.text = "➤"
        send_btn.custom_minimum_size = Vector2(40, 35)
        send_btn.add_theme_font_size_override("font_size", 16)
        send_btn.pressed.connect(func(): _send_message(input.text))
        input_hbox.add_child(send_btn); vbox.add_child(input_hbox)
        chat_panel.add_child(vbox); add_child(chat_panel)

        var chat_input = chat_panel.get_node_or_null("VBoxContainer/HBoxContainer3/ChatInput")
        if chat_input: chat_input.grab_focus()
        chat_panel.modulate.a = 0.0
        var tween = create_tween()
        tween.tween_property(chat_panel, "modulate:a", 1.0, 0.2)

func _send_message(text: String) -> void:
        text = text.strip_edges()
        if text.is_empty(): return
        var input = chat_panel.get_node_or_null("VBoxContainer/HBoxContainer3/ChatInput")
        if input: input.text = ""
        _add_message_to_ui("user", text)
        messages.append({"role": "user", "text": text})
        chat_message_sent.emit(text)
        _add_typing_indicator()
        var http = HTTPRequest.new(); add_child(http)
        http.timeout = TIMEOUT
        http.request_completed.connect(_on_response_received)
        var body = JSON.stringify({"question": text})
        http.request(API_URL + "/advice", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _send_suggestion(text: String) -> void:
        _send_message(text)

func _on_response_received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
        _remove_typing_indicator()
        if result != HTTPRequest.RESULT_SUCCESS:
                _add_message_to_ui("assistant", "⚠️ Impossible de contacter l'IA.\nVérifiez que le serveur Ollama est lancé.\n(python ai-backend/ollama_client.py)")
                return
        var json = JSON.new()
        if json.parse(body.get_string_from_utf8()) != OK:
                _add_message_to_ui("assistant", "⚠️ Erreur de réponse."); return
        var data = json.data
        var response_text = ""
        if data is Dictionary:
                response_text = data.get("advice", data.get("response", "Pas de réponse."))
        if response_text.is_empty(): response_text = "Je n'ai pas de réponse pour le moment..."
        _add_message_to_ui("assistant", response_text)
        messages.append({"role": "assistant", "text": response_text})
        chat_response_received.emit(response_text)

func _add_message_to_ui(role: String, text: String) -> void:
        if not chat_panel or not is_instance_valid(chat_panel): return
        var container = chat_panel.get_node_or_null("VBoxContainer/ScrollContainer/MessageContainer")
        if not container: return
        var msg_panel = PanelContainer.new()
        var style = StyleBoxFlat.new()
        if role == "user":
                style.bg_color = Color(0.15, 0.25, 0.40, 0.9)
        else:
                style.bg_color = Color(0.12, 0.15, 0.12, 0.8)
        style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
        style.corner_radius_bottom_right = 8; style.corner_radius_bottom_left = 8
        style.set_content_margin_all(6)
        msg_panel.add_theme_stylebox_override("panel", style)
        var lbl = Label.new(); lbl.text = text
        lbl.add_theme_font_size_override("font_size", 12)
        lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0) if role == "user" else Color(0.85, 0.85, 0.75))
        lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        msg_panel.add_child(lbl); container.add_child(msg_panel)
        var scroll = chat_panel.get_node_or_null("VBoxContainer/ScrollContainer")
        if scroll: await get_tree().process_frame; scroll.scroll_vertical = 99999

func _add_typing_indicator() -> void:
        if not chat_panel: return
        var container = chat_panel.get_node_or_null("VBoxContainer/ScrollContainer/MessageContainer")
        if not container: return
        var indicator = Label.new(); indicator.name = "TypingIndicator"
        indicator.text = "🤖 L'IA réfléchit..."
        indicator.add_theme_font_size_override("font_size", 11)
        indicator.add_theme_color_override("font_color", Color(0.5, 0.5, 0.4))
        container.add_child(indicator)

func _remove_typing_indicator() -> void:
        if not chat_panel: return
        var container = chat_panel.get_node_or_null("VBoxContainer/ScrollContainer/MessageContainer")
        if not container: return
        var indicator = container.get_node_or_null("TypingIndicator")
        if indicator: indicator.queue_free()

func _unhandled_input(event: InputEvent) -> void:
        if event is InputEventKey and event.pressed and event.keycode == KEY_T and not event.echo:
                toggle_chat()
