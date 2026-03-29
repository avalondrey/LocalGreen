extends Node
class_name GameManager

# ─── Singleton du jeu ────────────────────────────────────────────────
# Gère le score, l'inventaire, le cycle jour/nuit, les quêtes

# ─── Signaux ──────────────────────────────────────────────────────────
signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal day_changed(day_number: int)
signal quest_updated(quest: Dictionary)
signal season_changed(season_name: String)
signal inventory_updated(items: Dictionary)

# ─── Variables d'état ────────────────────────────────────────────────
var score: int = 0
var coins: int = 0
var day_number: int = 1
var day_timer: float = 0.0
var day_duration: float = 120.0  # 2 minutes = 1 jour de jeu

var current_quest: Dictionary = {
	"title": "Premiers pas au jardin",
	"description": "Plantez 3 graines pour commencer votre aventure !",
	"objective_type": "plant",
	"objective_target": 3,
	"objective_current": 0,
	"reward_coins": 20,
	"reward_xp": 50,
	"completed": false
}

var total_harvested: int = 0
var total_planted: int = 0
var total_watered: int = 0

var inventory: Dictionary = {
	"tomato": 0,
	"carrot": 0,
	"lettuce": 0,
	"seeds_tomato": 5,
	"seeds_carrot": 5,
	"seeds_lettuce": 5,
	"fertilizer": 0
}

enum Season { SPRING, SUMMER, AUTUMN, WINTER }
var current_season: Season = Season.SPRING
var season_names := ["Printemps", "Été", "Automne", "Hiver"]

var season_modifiers := {
	Season.SPRING: { "growth_mult": 1.0, "water_mult": 1.0, "seed_bonus": 1 },
	Season.SUMMER: { "growth_mult": 1.3, "water_mult": 1.5, "seed_bonus": 0 },
	Season.AUTUMN: { "growth_mult": 0.8, "water_mult": 0.8, "seed_bonus": 2 },
	Season.WINTER: { "growth_mult": 0.5, "water_mult": 0.5, "seed_bonus": 0 }
}

# ─── Références ──────────────────────────────────────────────────────
@onready var greenhouse: GreenhouseGrid = get_parent().get_node_or_null("GreenhouseGrid")

# ─── Initialisation ──────────────────────────────────────────────────
func _ready() -> void:
	print("🎮 GameManager initialisé — Jour %d, %s" % [day_number, season_names[current_season]])
	if greenhouse:
		_setup_greenhouse_signals()

func _setup_greenhouse_signals() -> void:
	# Connecter via call_deferred pour éviter les erreurs de connexion
	if not greenhouse.plant_planted.is_connected(_on_plant_planted):
		greenhouse.plant_planted.connect(_on_plant_planted)
	if not greenhouse.plant_watered.is_connected(_on_plant_watered):
		greenhouse.plant_watered.connect(_on_plant_watered)
	if not greenhouse.plant_harvested.is_connected(_on_plant_harvested):
		greenhouse.plant_harvested.connect(_on_plant_harvested)

# ─── Callbacks du greenhouse ─────────────────────────────────────────
func _on_plant_planted(pos: Vector2i, plant: PlantData) -> void:
	total_planted += 1
	_update_quest_progress("plant")
	score += 5
	score_changed.emit(score)

func _on_plant_watered(pos: Vector2i) -> void:
	total_watered += 1
	score += 1
	score_changed.emit(score)

func _on_plant_harvested(pos: Vector2i, value: int) -> void:
	total_harvested += 1
	var plant_type_name = ""
	# Déterminer quel type de plante a été récolté
	var plants = greenhouse.get_all_plants()
	var reward = value
	score += value * 10
	coins += value
	_update_quest_progress("harvest")

	# Ajouter à l'inventaire (aléatoire si on ne peut pas déterminer)
	if plant_type_name == "":
		var types = ["tomato", "carrot", "lettuce"]
		plant_type_name = types[randi() % 3]
	inventory[plant_type_name] = inventory.get(plant_type_name, 0) + 1
	inventory_updated.emit(inventory)
	score_changed.emit(score)
	coins_changed.emit(coins)

# ─── Cycle de jeu ────────────────────────────────────────────────────
func _process(delta: float) -> void:
	day_timer += delta
	if day_timer >= day_duration:
		advance_day()

func advance_day() -> void:
	day_number += 1
	day_timer = 0.0

	# Bonus de saison (graines)
	var bonus = season_modifiers[current_season]["seed_bonus"]
	if bonus > 0:
		inventory["seeds_tomato"] += bonus
		inventory["seeds_carrot"] += bonus
		inventory["seeds_lettuce"] += bonus
		print("🎁 Bonus de %s : +%d graines de chaque !" % [season_names[current_season], bonus])

	# Changer de saison tous les 3 jours
	if day_number % 3 == 1 and day_number > 1:
		current_season = (current_season + 1) % 4
		season_changed.emit(season_names[current_season])
		print("🌸 Saison : %s" % season_names[current_season])

	day_changed.emit(day_number)

# ─── Système de quêtes ───────────────────────────────────────────────
func _update_quest_progress(action_type: String) -> void:
	if current_quest.get("completed", true):
		return
	if current_quest.get("objective_type", "") == action_type:
		current_quest["objective_current"] = current_quest.get("objective_current", 0) + 1
		quest_updated.emit(current_quest)
		if current_quest["objective_current"] >= current_quest["objective_target"]:
			complete_quest()

func complete_quest() -> void:
	current_quest["completed"] = true
	var reward = current_quest.get("reward_coins", 10)
	var xp = current_quest.get("reward_xp", 25)
	coins += reward
	score += xp
	print("🎉 Quête terminée : %s (+%d pièces, +%d XP)" % [current_quest["title"], reward, xp])
	quest_updated.emit(current_quest)
	coins_changed.emit(coins)
	score_changed.emit(score)

func generate_new_quest(title: String, desc: String, obj_type: String, obj_target: int, reward_c: int, reward_x: int) -> void:
	current_quest = {
		"title": title,
		"description": desc,
		"objective_type": obj_type,
		"objective_target": obj_target,
		"objective_current": 0,
		"reward_coins": reward_c,
		"reward_xp": reward_x,
		"completed": false
	}
	quest_updated.emit(current_quest)

# ─── Inventaire ──────────────────────────────────────────────────────
func use_seed(plant_type: String) -> bool:
	var key = "seeds_" + plant_type
	if inventory.get(key, 0) > 0:
		inventory[key] -= 1
		inventory_updated.emit(inventory)
		return true
	return false

func has_seeds(plant_type: String) -> bool:
	return inventory.get("seeds_" + plant_type, 0) > 0

func get_seed_count(plant_type: String) -> int:
	return inventory.get("seeds_" + plant_type, 0)

# ─── Modificateurs de saison ────────────────────────────────────────
func get_growth_multiplier() -> float:
	return season_modifiers[current_season]["growth_mult"]

func get_water_multiplier() -> float:
	return season_modifiers[current_season]["water_mult"]

# ─── Sauvegarde ──────────────────────────────────────────────────────
func save_game() -> void:
	var data = {
		"score": score,
		"coins": coins,
		"day_number": day_number,
		"current_season": current_season,
		"total_harvested": total_harvested,
		"total_planted": total_planted,
		"total_watered": total_watered,
		"inventory": inventory
	}
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		print("💾 Jeu sauvegardé !")
	else:
		print("❌ Erreur de sauvegarde")

func load_game() -> bool:
	if not FileAccess.file_exists("user://savegame.json"):
		return false
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	if not file:
		return false
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	if err != OK:
		return false
	var data = json.data
	score = data.get("score", 0)
	coins = data.get("coins", 0)
	day_number = data.get("day_number", 1)
	current_season = data.get("current_season", 0)
	total_harvested = data.get("total_harvested", 0)
	total_planted = data.get("total_planted", 0)
	total_watered = data.get("total_watered", 0)
	inventory = data.get("inventory", inventory)
	print("📂 Jeu chargé — Jour %d, Score: %d" % [day_number, score])
	return true
