extends Node
class_name WebAdapter

# ─── Adaptateur pour le déploiement web ──────────────────────────────
# Gère les différences entre desktop et HTML5 :
# - Sauvegarde dans localStorage au lieu de fichiers
# - Désactivation propre de l'IA (pas de connexion Ollama en web)
# - Configuration web spécifique

var is_web: bool = false
var ai_available: bool = false

func _ready() -> void:
	# Détecter si on est dans un navigateur
	is_web = OS.get_name() == "HTML5"
	
	if is_web:
		print("🌐 Mode Web détecté — Adaptation en cours...")
		_adapt_for_web()
	else:
		print("💻 Mode Desktop détecté")

func _adapt_for_web() -> void:
	# En web, l'IA Ollama n'est pas accessible
	# Le jeu fonctionne pleinement sans IA (quêtes prédéfinies)
	ai_available = false
	
	# Désactiver le SoundManager si nécessaire
	# (l'audio procédural peut poser problème en web)
	var sound_manager = get_parent().get_node_or_null("SoundManager")
	if sound_manager and not OS.has_feature("audio"):
		sound_manager.sfx_enabled = false
		sound_manager.music_enabled = false
		print("🔊 Audio désactivé (non supporté)")

# ─── Sauvegarde web (localStorage) ───────────────────────────────────
func save_game_web(data: Dictionary) -> bool:
	if not is_web:
		return false
	# En HTML5, on utilise JavaScript localStorage
	var json_str = JSON.stringify(data, "\t")
	JavaScriptBridge.eval("localStorage.setItem('localgreen_save', JSON.stringify(%s));" % json_str)
	print("💾 Sauvegarde web effectuée")
	return true

func load_game_web() -> Dictionary:
	if not is_web:
		return {}
	var result = JavaScriptBridge.eval("JSON.parse(localStorage.getItem('localgreen_save') || '{}')")
	if result == null:
		return {}
	if result is Dictionary:
		return result
	return {}

func has_web_save() -> bool:
	if not is_web:
		return false
	var result = JavaScriptBridge.eval("localStorage.getItem('localgreen_save') !== null")
	return result == true

func clear_web_save() -> void:
	if not is_web:
		return
	JavaScriptBridge.eval("localStorage.removeItem('localgreen_save')")
	print("🗑️ Sauvegarde web supprimée")
