class_name PlantData
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
