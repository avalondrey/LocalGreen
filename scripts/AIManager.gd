extends Node
class_name AIManager

# ─── Intégration Ollama/Mistral dans Godot ───────────────────────────
# Envoie des requêtes HTTP à l'API Ollama locale

# ─── Configuration ───────────────────────────────────────────────────
const OLLAMA_URL := "http://localhost:11434/api/generate"
const MODEL := "mistral"
const TIMEOUT := 15.0

# ─── Signaux ─────────────────────────────────────────────────────────
signal quest_generated(quest: Dictionary)
signal tip_received(tip: String)
signal advice_received(advice: String)
signal ai_error(message: String)
signal ai_connected(success: bool)

# ─── État ────────────────────────────────────────────────────────────
var http_request: HTTPRequest
var is_connected: bool = false
var pending_requests: int = 0
var last_tip: String = ""

# ─── Références ──────────────────────────────────────────────────────
@onready var game_manager: GameManager = get_parent().get_node_or_null("GameManager")

# ─── Initialisation ──────────────────────────────────────────────────
func _ready() -> void:
	http_request = HTTPRequest.new()
	http_request.timeout = TIMEOUT
	http_request.request_completed.connect(_on_request_completed)
	add_child(http_request)
	print("🤖 AIManager initialisé — Connexion à Ollama...")
	check_connection()

func check_connection() -> void:
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"model": MODEL,
		"prompt": "Réponds OK",
		"stream": false
	})
	var err = http_request.request(OLLAMA_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("❌ Impossible de se connecter à Ollama")
		ai_connected.emit(false)
		is_connected = false

# ─── Requêtes HTTP ───────────────────────────────────────────────────
func _on_request_completed(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	pending_requests -= 1

	if result != HTTPRequest.RESULT_SUCCESS:
		if pending_requests <= 0:
			ai_connected.emit(false)
			is_connected = false
		ai_error.emit("Erreur HTTP: code %d" % code)
		return

	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())

	if err != OK:
		ai_error.emit("Erreur de parsing JSON")
		return

	var response = json.data
	if not response is Dictionary:
		ai_error.emit("Réponse invalide")
		return

	# Première réponse réussie = connecté
	if not is_connected:
		is_connected = true
		ai_connected.emit(true)
		print("✅ Ollama connecté !")

	_process_response(response)

func _process_response(response: Dictionary) -> void:
	# Extraire le texte de la réponse
	var text = response.get("response", "").strip_edges()
	if text.is_empty():
		ai_error.emit("Réponse vide de l'IA")
		return

	# Détection automatique du type de contenu (JSON = quête, sinon = texte)
	if text.begins_with("{") and text.ends_with("}"):
		var quest_json = JSON.new()
		if quest_json.parse(text) == OK and quest_json.data is Dictionary:
			quest_generated.emit(quest_json.data)
			return

	# Sinon, c'est un conseil ou tip
	tip_received.emit(text)

# ─── API publique ────────────────────────────────────────────────────
func generate_daily_quest() -> void:
	var prompt = """Tu es un assistant de jeu de jardinage.
Génère UNE quête de jardinage au format JSON strict (pas de markdown, pas de backticks).
Le JSON doit contenir exactement ces champs :
- "title": string (titre court de la quête)
- "description": string (description de la quête en français)
- "objective_type": "plant" ou "harvest" ou "water"
- "objective_target": number (entre 2 et 10)
- "reward_coins": number (entre 10 et 100)
- "reward_xp": number (entre 25 et 200)

Réponds UNIQUEMENT avec le JSON, rien d'autre."""

	_send_request(prompt)

func get_planting_tip(plant_type: String) -> void:
	var prompt = """Donne un conseil de jardinage court (1-2 phrases) en français pour cultiver : %s.
Sois précis et utile. Réponds en français uniquement.""" % plant_type
	_send_request(prompt)

func get_quest_hint() -> void:
	if game_manager and not game_manager.current_quest.get("completed", true):
		var quest_title = game_manager.current_quest.get("title", "la quête")
		var prompt = "Donne un indice court (1 phrase) en français pour aider le joueur dans la quête : %s" % quest_title
		_send_request(prompt)

func ask_advice(question: String) -> void:
	var prompt = """Tu es un expert en jardinage dans un jeu vidéo style manga.
Le joueur te demande : %s
Réponds en 1-2 phrases en français, de façon utile et encourageante.""" % question
	_send_request(prompt)

# ─── Envoi de requête ────────────────────────────────────────────────
func _send_request(prompt: String) -> void:
	if pending_requests > 3:
		ai_error.emit("Trop de requêtes en attente")
		return

	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"model": MODEL,
		"prompt": prompt,
		"stream": false,
		"options": {
			"temperature": 0.7,
			"num_predict": 200
		}
	})

	pending_requests += 1
	var err = http_request.request(OLLAMA_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		pending_requests -= 1
		ai_error.emit("Impossible d'envoyer la requête")

# ─── Timer pour requêtes automatiques ────────────────────────────────
var auto_timer: float = 0.0

func _process(delta: float) -> void:
	if not is_connected:
		auto_timer += delta
		if auto_timer > 30.0:
			auto_timer = 0.0
			check_connection()
