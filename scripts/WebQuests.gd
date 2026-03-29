extends Node
class_name WebQuests

# ─── Quêtes prédéfinies pour le mode web (sans IA) ──────────────────
# Quand Ollama n'est pas disponible, ces quêtes sont utilisées

var quest_pool: Array = [
	{
		"title": "Premier Jardin",
		"description": "Plantez 3 graines pour commencer !",
		"objective_type": "plant", "objective_target": 3,
		"reward_coins": 20, "reward_xp": 50
	},
	{
		"title": "Jardinier Efficace",
		"description": "Arrosez 5 plantes.",
		"objective_type": "water", "objective_target": 5,
		"reward_coins": 15, "reward_xp": 30
	},
	{
		"title": "Récolte Abondante",
		"description": "Récoltez 3 légumes mûrs.",
		"objective_type": "harvest", "objective_target": 3,
		"reward_coins": 30, "reward_xp": 60
	},
	{
		"title": "Tomateraie",
		"description": "Plantez 5 tomates !",
		"objective_type": "plant", "objective_target": 5,
		"reward_coins": 25, "reward_xp": 40
	},
	{
		"title": "Coup de Faim",
		"description": "Récoltez 5 carottes.",
		"objective_type": "harvest", "objective_target": 5,
		"reward_coins": 40, "reward_xp": 80
	},
	{
		"title": "Pluie de Pièces",
		"description": "Arrosez 10 fois vos plantes.",
		"objective_type": "water", "objective_target": 10,
		"reward_coins": 25, "reward_xp": 45
	},
	{
		"title": "Laitue Party",
		"description": "Plantez 3 laitues et récoltez-les.",
		"objective_type": "harvest", "objective_target": 3,
		"reward_coins": 20, "reward_xp": 35
	},
	{
		"title": "Grand Fermier",
		"description": "Plantez 15 graines au total !",
		"objective_type": "plant", "objective_target": 15,
		"reward_coins": 50, "reward_xp": 100
	},
	{
		"title": "Récolte d'Or",
		"description": "Récoltez 10 légumes.",
		"objective_type": "harvest", "objective_target": 10,
		"reward_coins": 60, "reward_xp": 120
	},
	{
		"title": "Arroseur Fou",
		"description": "Arrosez 20 fois !",
		"objective_type": "water", "objective_target": 20,
		"reward_coins": 40, "reward_xp": 80
	},
	{
		"title": "Jardin Complet",
		"description": "Plantez dans 10 cases différentes.",
		"objective_type": "plant", "objective_target": 10,
		"reward_coins": 35, "reward_xp": 70
	},
	{
		"title": "Maître Arroseur",
		"description": "Arrosez 30 fois vos plantes.",
		"objective_type": "water", "objective_target": 30,
		"reward_coins": 50, "reward_xp": 100
	}
]

var used_indices: Array = []

func get_random_quest() -> Dictionary:
	# Si toutes les quêtes ont été utilisées, reset
	if used_indices.size() >= quest_pool.size():
		used_indices.clear()
	
	# Choisir une quête non utilisée
	var available = []
	for i in range(quest_pool.size()):
		if not i in used_indices:
			available.append(i)
	
	var idx = available[randi() % available.size()]
	used_indices.append(idx)
	
	var quest = quest_pool[idx].duplicate()
	quest["objective_current"] = 0
	quest["completed"] = false
	return quest
