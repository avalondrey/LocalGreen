import os
import sys
from pathlib import Path

# Couleurs pour le terminal
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

def print_success(msg):
    print(f"{Colors.GREEN}✓{Colors.RESET} {msg}")

def print_error(msg):
    print(f"{Colors.RED}✗{Colors.RESET} {msg}")

def print_info(msg):
    print(f"{Colors.BLUE}ℹ{Colors.RESET} {msg}")

BASE = Path("C:/Users/Administrateur/Desktop/LocalGreen")

print(f"\n{Colors.YELLOW}🌱 Création de LocalGreen...{Colors.RESET}\n")

try:
    # 1. Création des dossiers
    print_info("Création des dossiers...")
    dirs = [
        "assets/plants/tomato",
        "assets/plants/carrot",
        "assets/plants/lettuce",
        "assets/ui/buttons",
        "assets/ui/icons",
        "assets/effects",
        "assets/tiles",
        "scenes/ui",
        "scripts/ai",
        "ai-backend",
        "docs"
    ]
    
    for d in dirs:
        full_path = BASE / d
        full_path.mkdir(parents=True, exist_ok=True)
        print_success(d)
    
    # 2. .gitignore
    print_info("\nCréation des fichiers...")
    (BASE / ".gitignore").write_text("""# Godot
.godot/
export.cfg
*.import
*.tmp

# Python
__pycache__/
*.pyc
venv/
.env

# Windows
Thumbs.db
Desktop.ini
""", encoding="utf-8")
    print_success(".gitignore")
    
    # 3. README.md
    (BASE / "README.md").write_text("""# 🌱 LocalGreen

Mini-jeu de jardinage isométrique style manga + IA locale.

## Stack
- **Moteur**: Godot 4.x
- **IA**: Ollama + Mistral
- **Langage**: GDScript + Python

## Démarrage
1. Ouvrir `project.godot` dans Godot
2. Lancer `scenes/main.tscn`
3. IA: `ollama pull mistral`
""", encoding="utf-8")
    print_success("README.md")
    
    # 4. project.godot
    (BASE / "project.godot").write_text("""config_version=5

[application]
config/name="LocalGreen"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.2", "Forward Plus")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="viewport"

[input]
ui_select={"deadzone":0.5,"events":[Object(InputEventMouseButton,"button_index":1,"pressed":true)]}
""", encoding="utf-8")
    print_success("project.godot")
    
    # 5. PlantData.gd
    plantdata_content = """class_name PlantData
extends Resource

enum PlantType { TOMATO, CARROT, LETTUCE }
enum GrowthStage { SEED, SPROUT, YOUNG, MATURE, READY }

@export var plant_type: PlantType = PlantType.TOMATO
@export var current_stage: GrowthStage = GrowthStage.SEED
@export var water_level: float = 0.0
@export var growth_timer: float = 0.0
@export var planted_at: String = ""

var growth_times := {
	GrowthStage.SEED: 10.0,
	GrowthStage.SPROUT: 20.0,
	GrowthStage.YOUNG: 30.0,
	GrowthStage.MATURE: 40.0,
	GrowthStage.READY: 0.0
}

func get_sprite_path() -> String:
	var types = ["tomato", "carrot", "lettuce"]
	var stages = ["seed", "sprout", "young", "mature", "ready"]
	return "res://assets/plants/" + types[plant_type] + "/" + stages[current_stage] + ".png"

func process(delta: float) -> bool:
	if water_level > 0 and current_stage < GrowthStage.READY:
		growth_timer += delta
		if growth_timer >= growth_times[current_stage]:
			advance_stage()
			growth_timer = 0
			return true
	return false

func advance_stage():
	if current_stage < GrowthStage.READY:
		current_stage += 1

func water(amount: float):
	water_level = min(water_level + amount, 100.0)

func consume_water(delta: float):
	water_level = max(water_level - (delta * 2.0), 0.0)

func can_harvest() -> bool:
	return current_stage == GrowthStage.READY

func get_harvest_value() -> int:
	match plant_type:
		PlantType.TOMATO: return 10
		PlantType.CARROT: return 8
		PlantType.LETTUCE: return 6
	return 5
"""
    (BASE / "scripts" / "PlantData.gd").write_text(plantdata_content, encoding="utf-8")
    print_success("scripts/PlantData.gd")
    
    # 6. GreenhouseGrid.gd
    grid_content = """extends Node2D

const GRID_WIDTH := 6
const GRID_HEIGHT := 4
const TILE_SIZE := Vector2(128, 64)

var plants: Dictionary = {}
var selected_tool: String = "water"
var selected_plant_type: int = 0

func _ready():
	print("LocalGreen demarre - Grille 6x4")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos = get_global_mouse_position()
		var grid = world_to_grid(pos)
		if is_valid(grid):
			handle_click(grid.x, grid.y)

func handle_click(x: int, y: int):
	match selected_tool:
		"plant": plant_seed(x, y, selected_plant_type)
		"water": water_plant(x, y)
		"harvest": harvest_plant(x, y)

func plant_seed(x: int, y: int, ptype: int) -> bool:
	var key = str(x) + "," + str(y)
	if plants.has(key): return false
	var plant = PlantData.new()
	plant.plant_type = ptype
	plant.planted_at = Time.get_datetime_string_from_system()
	plants[key] = plant
	print("Plante en ", x, ",", y)
	update_visual(x, y)
	return true

func water_plant(x: int, y: int, amount: float = 25.0) -> bool:
	var key = str(x) + "," + str(y)
	if plants.has(key):
		plants[key].water(amount)
		print("Arrose en ", x, ",", y)
		return true
	return false

func harvest_plant(x: int, y: int) -> bool:
	var key = str(x) + "," + str(y)
	if plants.has(key) and plants[key].can_harvest():
		var val = plants[key].get_harvest_value()
		plants.erase(key)
		print("Recolte +", val)
		update_visual(x, y)
		return true
	return false

func _process(delta):
	for key in plants:
		var p = plants[key]
		p.consume_water(delta)
		if p.process(delta):
			var parts = key.split(",")
			update_visual(int(parts[0]), int(parts[1]))

func is_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < GRID_HEIGHT

func world_to_grid(wp: Vector2) -> Vector2i:
	var x = int((wp.x / TILE_SIZE.x) + (wp.y / TILE_SIZE.y))
	var y = int((wp.y / TILE_SIZE.y) - (wp.x / TILE_SIZE.x))
	return Vector2i(x, y)

func update_visual(x: int, y: int):
	pass
"""
    (BASE / "scripts" / "GreenhouseGrid.gd").write_text(grid_content, encoding="utf-8")
    print_success("scripts/GreenhouseGrid.gd")
    
    # 7. ai-backend/requirements.txt
    (BASE / "ai-backend" / "requirements.txt").write_text("requests>=2.31.0\n", encoding="utf-8")
    print_success("ai-backend/requirements.txt")
    
    # 8. ai-backend/ollama_client.py
    ollama_content = """import requests
import json

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "mistral"

def generate(prompt: str, stream: bool = False) -> dict:
    try:
        resp = requests.post(OLLAMA_URL, json={"model": MODEL, "prompt": prompt, "stream": stream}, timeout=30)
        return resp.json()
    except Exception as e:
        return {"error": str(e)}

def get_daily_quest() -> dict:
    prompt = 'Genere une quete jardinage JSON: {"title":"...", "description":"...", "reward":50}'
    r = generate(prompt)
    if "response" in r:
        try:
            return json.loads(r["response"])
        except:
            return {"title":"Quest","description":r["response"],"reward":50}
    return {"title":"Error","description":"IA offline","reward":0}

if __name__ == "__main__":
    print("🤖 Test Ollama...")
    q = get_daily_quest()
    print(f"📜 {q['title']}: {q['description']} (+{q['reward']} XP)")
    input("\\nAppuie sur Entrée pour quitter...")
"""
    (BASE / "ai-backend" / "ollama_client.py").write_text(ollama_content, encoding="utf-8")
    print_success("ai-backend/ollama_client.py")
    
    # SUCCÈS
    print(f"\n{Colors.GREEN}✅ ========================================{Colors.RESET}")
    print(f"{Colors.GREEN}✅ LocalGreen créé avec succès !{Colors.RESET}")
    print(f"{Colors.GREEN}✅ ========================================{Colors.RESET}")
    print(f"\n{Colors.YELLOW}📁 Chemin:{Colors.RESET} {BASE}")
    print(f"\n{Colors.YELLOW}🎯 Prochaines étapes:{Colors.RESET}")
    print("   1. Ouvre Godot 4 et importe project.godot")
    print("   2. Ajoute tes assets dans assets/")
    print("   3. Crée scenes/main.tscn dans l'éditeur")
    print("   4. Git init && git push")
    
except Exception as e:
    print(f"\n{Colors.RED}❌ ERREUR: {str(e)}{Colors.RESET}")
    print("Vérifie que Python est installé et que tu as les permissions.")

# PAUSE pour Windows
print("\n" + "="*50)
input("Appuie sur ENTRÉE pour quitter...")